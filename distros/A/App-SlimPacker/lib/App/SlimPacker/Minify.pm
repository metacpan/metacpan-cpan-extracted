package App::SlimPacker::Minify;
use strict;
use warnings;
use PPI;
use Scalar::Util 'refaddr';
use Exporter 'import';
our $VERSION = '0.08';
our @EXPORT_OK = qw(
    process process_deps minify_file name_gen needs_space
    module_deps collect_bundle_globals
    rename_module_name rename_module_path
);

sub needs_space {
    my ($l, $r) = @_;
    my $lc = $l->content; my $rc = $r->content;
    my $lr = ref($l);     my $rr = ref($r);
    return 1 if $lc =~ /\w$/ && $rc =~ /^\w/;
    return 1 if $lc =~ /[\$\@\%]$/ && $rc =~ /^\w/;
    return 1 if $lc =~ /\w$/ && $rr =~ /Quote/;
    return 1 if $lr =~ /Quote/ && $rc =~ /^\w/;
    return 1 if $lr =~ /Symbol/ && $rr =~ /Symbol/;
    # A bare Cast sigil (`$`, `@`, `%`) must not be glued to the token before
    # it: `print $fh $$source` -> `print$fh$$source` (or `$fh@$source`)
    # silently changes meaning / breaks parsing.
    return 1 if $rr =~ /Cast/;
    return 1 if $lc =~ /\w$/ && $rc =~ /^['"\/]/;
    return 1 if $lr =~ /Regexp/ && $rc =~ /^\w/;
    # `use Foo VERSION (LIST)` needs the space before the paren; dropping it
    # (e.g. `use Foo 5.57(qw/x/)`) is a Perl syntax error. The paren arrives as
    # a Structure whose content starts with '('.
    return 1 if $lr =~ /Number/ && $rc =~ /^\(/;
    # Perl <= 5.18 mis-tokenizes `&&WORD` (also `&`, `||`, `//`) when a method
    # call follows (`$x&&Foo::Bar->baz`): "Operator or semicolon missing
    # before &Foo::Bar". Keep the space after the operator.
    return 1 if ($lc eq '&&' || $lc eq '||' || $lc eq '//' || $lc eq '&')
              && $rc =~ /^[A-Za-z_]/;
    # `-WORD` is a filetest (`-e $x`) or, on perl <= 5.20, an ambiguous
    # bareword negation ("Ambiguous use of -WORD resolved as -&WORD()").
    # Keep the space after a minus that preceded a word.
    return 1 if $lc eq '-' && $rc =~ /^[A-Za-z_]/;
    return 0;
}

my @_chars = ('a'..'z');
sub name_gen {
    my ($n) = @_;
    my $out = '';
    $n++;
    while ($n > 0) { $out = $_chars[($n-1)%26] . $out; $n = int(($n-1)/26) }
    return $out;
}

# Previous/next sibling skipping whitespace.  Builtins never appear as direct
# siblings of a Word token (Whitespace is its own sibling), so the rename
# contexts below must see through it.
sub _prev_sig_sib {
    my ($t) = @_;
    my $p = $t->previous_sibling;
    $p = $p->previous_sibling while $p && ref($p) eq 'PPI::Token::Whitespace';
    return $p;
}
sub _next_sig_sib {
    my ($t) = @_;
    my $n = $t->next_sibling;
    $n = $n->next_sibling while $n && ref($n) eq 'PPI::Token::Whitespace';
    return $n;
}

# ---------------------------------------------------------------------------
# Per-name eligibility: what may be renamed, and to what.
# ---------------------------------------------------------------------------

# Pragma/pseudo modules whose `use` argument list is NOT a list of exported
# sub names to rename: names there are pragma settings, class names or data
# (`use lib 'cache'`, `use parent qw(App::Base)`, `use constant FOO => 'bar'`).
# When a sub name collides with one of these the rename is refused rather than
# risk turning data into a renamed identifier.
my %USE_LITERAL_ARGS = map { $_ => 1 } qw(
    strict warnings feature lib parent base constant vars subs if integer bytes
    utf8 overload re sigtrap open sort
);

# Is this token part of a sub-name "protocol site": a `use` import list, an
# @EXPORT/@EXPORT_OK/%EXPORT_TAGS assignment, or a can()/DOES()/import()
# argument?  With rename_exports on, words at these sites are RENAMED in step
# with the sub they refer to (two sides of the same name surface), so they must
# neither freeze the name for eligibility nor be left behind when the sub is
# shortened.  Everything that looks like a site but is really data is excluded
# (pragma import args, the module-name word of the `use`, non-single-word
# strings).
sub _protocol_site {
    my ($tok) = @_;
    my $stmt = $tok->statement or return 0;

    if ($stmt->isa('PPI::Statement::Include')) {
        my $type = $stmt->type;
        return 0 unless defined $type && $type eq 'use';
        my $mod = $stmt->module;
        return 0 unless defined $mod && length $mod;
        return 0 if $mod eq $tok->content;          # the module-name word
        (my $leaf = $mod) =~ s/^.*:://;
        return 0 if $USE_LITERAL_ARGS{$leaf};       # pragma args are data
        return 1;
    }

    my $syms = $stmt->find('PPI::Token::Symbol');
    if ($syms) {
        for my $s (@$syms) {
            next if $s == $tok;
            return 1 if $s->content =~ /^[\$\@\%](?:EXPORT|EXPORT_OK|EXPORT_TAGS)$/;
        }
    }

    my $par = $tok->parent;
    # PPI wraps a bare method-call argument in a Statement::Expression inside
    # the argument List, so climb through those wrappers to find the List.
    while ($par && $par->isa('PPI::Statement::Expression')) { $par = $par->parent }
    if ($par && $par->isa('PPI::Structure::List')) {
        my $prev = _prev_sig_sib($par);
        return 1 if $prev && $prev->isa('PPI::Token::Word')
                  && $prev->content =~ /^(?:can|DOES|import)$/;
    }
    return 0;
}

# Namespace components of bundled packages are renamed to short names,
# INCLUDING each package's leaf (final) component: the bundle is closed, so a
# `use Pkg::Leaf` compiles to a `require 'Pkg/Leaf.pm'` that the loader's
# %INC key matches, and both are rewritten from the same component map.  Module
# names that are only ever built at runtime (from user config, directory
# globbing, string-eval) are not rewritten — slimpack documents that any such
# name must be whitelisted by the app author.
#
# rename_module_name(NAME, $mods) rewrites a "Foo::Bar" style name; $mods is
# the module struct from collect_bundle_globals() (a fourth return value):
#   { map => { component => short }, pkgs => [longest-first package names] }
# A name is rewritten when it equals a declared bundled package, starts with
# one ("Pkg::Leaf::sub" — the package part only), or is a strict namespace
# ancestor of one (search-path strings like "App::Saisons::Adapter", where
# every component is renamed).
sub rename_module_name {
    my ($name, $m) = @_;
    return $name unless $m && $m->{pkgs} && @{ $m->{pkgs} } && $name =~ /::/;
    my @caps = split /::/, $name;
    for my $p (@{ $m->{pkgs} }) {
        my @pc = split /::/, $p;
        if ($name eq $p && @pc >= 2) {
            return join('::', map { $m->{map}{$_} // $_ } @pc);
        }
        if (@pc >= 2 && substr($name, 0, length($p) + 2) eq $p . '::') {
            # `name` lives under the declared package $p.  $p may itself be an
            # ancestor-namespace (a deeper declared package renames $p's last
            # component too — App::Saisons -> a::b when App::Saisons::UI is
            # declared), so resolve the renamed prefix via a recursive call
            # rather than mapping only $p's ancestors and appending its leaf
            # verbatim.
            my $ren = rename_module_name($p, $m);
            return $ren . substr($name, length $p);
        }
        if (@caps >= 2 && substr($p, 0, length($name) + 2) eq $name . '::') {
            return join('::', map { $m->{map}{$_} // $_ } @caps);
        }
    }
    return $name;
}

# rename_module_path('App/Saisons/UI.pm', $mods) rewrites the %INC/loader key
# form of a module name, so a renamed `require 'a/Saisons/UI.pm'` resolves in
# the loader.  The leaf is renamed too when the component map contains it (the
# bundler includes every component of a declared package), which is what keeps
# the loader's %INC table keys in step with the rewritten package names.
sub rename_module_path {
    my ($path, $m) = @_;
    return $path unless $path =~ /\.pm\z/;
    (my $name = $path) =~ s{\.pm\z}{};
    $name =~ s{/}{::}g;
    my $ren = rename_module_name($name, $m);
    $ren =~ s{::}{/}g;
    return $ren . '.pm';
}

# Is a Word whose content is in the sub rename map really a reference to that
# sub (so renaming is safe and consistent), as opposed to a hash key, a label,
# or the target of a dereference?  $qualified selects the rules for a
# Pkg::name token (PPI emits the whole qualified name as one Word): those are
# only ever renamed when the token is unambiguously a sub reference — a
# definition, an &name, or an actual call with parentheses.  Bare qualified
# words (constants, typeglob elements) and foreign-method chains are left
# alone.
#
# Renamed contexts (plain names):
#   sub foo {...}            definition (also sub Pkg::foo)
#   $o->foo(...)             method call            (never $h->{foo} / {foo=>})
#   &foo, \&foo              direct / coderef call
#   Foo::bar(...)            qualified call         (qualified defs handled too)
#   foo(...)                 plain bareword call
# Anything else — a bare `foo` word, `foo =>`, `$o->{foo}`, `Pkg::foo` without
# parens, `foo:`, `\foo` — is left alone.
sub _sub_word_context {
    my ($tok, $qualified) = @_;
    my $parent = $tok->parent;
    return 0 if $parent && ($parent->isa('PPI::Structure::Brace')
                          || $parent->isa('PPI::Structure::Constructor'));
    my $prev = _prev_sig_sib($tok);
    my $next = _next_sig_sib($tok);
    if ($qualified) {
        return 1 if $prev && $prev->content eq 'sub';
        return 1 if $prev && $prev->content eq '&';
        return 1 if $next && $next->isa('PPI::Structure::List');
        return 0;
    }
    return 1 if $prev && $prev->content eq 'sub';
    return 1 if $prev && $prev->content eq '->';
    return 1 if $prev && $prev->content eq '&';
    if ($prev && $prev->content eq '::') {
        my $p = _prev_sig_sib($prev);
        return 1 if $p && $p->content eq 'sub';   # sub Pkg::foo {...}
        return 1 if $next && $next->isa('PPI::Structure::List');
        return 0;                                  # Pkg::foo bare (const/sym)
    }
    # Bareword call.  Every name in the sub map is a defined sub, so any
    # remaining bareword occurrence of it is a call to it (`foo . $x`,
    # `foo if $x`, `&`-less `foo(...)`, `foo;`, `foo, bar`) — except where
    # the word is really a hash key, a label, or a constant being declared.
    if ($next) {
        return 0 if $next->isa('PPI::Structure::Brace')
                 || $next->isa('PPI::Structure::Constructor');
        my $c = $next->content;
        return 0 if $c eq '=>';
        return 0 if $c eq ':' && $tok->statement
                  && $tok->statement->first_token == $tok;   # foo: label
        return 0 if $prev && $prev->content =~ /^(?:goto|next|last|redo)$/;
        return 1;
    }
    # Last word of its expression (`(... && !foo)`, `[foo]`, a block ending
    # in `foo`) is still a call - unless it is a hash key ($h{foo}).
    return 0 if $prev && $prev->content =~ /^(?:goto|next|last|redo)$/;
    my $holder = $parent;
    $holder = $holder->parent if $holder && $holder->isa('PPI::Statement::Expression');
    return 0 if $holder && $holder->isa('PPI::Structure::Subscript');
    return 1;
}

my %KEEP = map { $_ => 1 } qw(
    _ a b 0 1 2 3 4 5 6 7 8 9
    ENV INC ISA SIG ARGV ARGVOUT STDOUT STDERR STDIN
    VERSION AUTOLOAD self class
);

# `self` and `class` are real keywords only under Perl's 5.38+ `class` feature
# (bareword declarations plus an implicit, never-my-declared `$self` in method
# bodies).  As plain `my` lexicals in classic code (`my $self = shift`,
# `my $class = shift`) they are ordinary variables and rename like any other —
# if a source actually enables the class feature, _uses_class_feature() freezes
# them again so the implicit $self and the class/method/field keywords stay.
sub _uses_class_feature {
    my ($doc) = @_;
    my $s = $doc->serialize;
    return 1 if $s =~ /\buse\s+v?\s*\d\.(?:3[89]|4[0-9])\b/;
    for my $inc (@{ $doc->find('PPI::Statement::Include') || [] }) {
        my $txt = $inc->content;
        next unless $txt =~ /^\s*use\s+(feature|experimental)\b/;
        return 1 if $txt =~ /\bclass\b/ || $txt =~ /\b:\s*5\.(?:3[89]|4[0-9])\b/;
    }
    return 0;
}

# Sub/method names that must never be renamed: magic lifetimes, the module
# protocol, UNIVERSAL, constructor/factory protocols that other code (or the
# runtime) reaches by name rather than by an in-file reference, the whole tie()
# interface (the runtime dispatches TIEHASH/FETCH/STORE/... by name from a
# quoted package — `tie %h, __PACKAGE__` is invisible to the word scan), and
# the serialization hooks that external modules look up by name.
my %SUBKEEP = map { $_ => 1 } qw(
    new clone DESTROY AUTOLOAD VERSION import unimport export
    can isa DOES
    BEGIN CHECK INIT END UNITCHECK
    TIESCALAR TIEARRAY TIEHASH TIEHANDLE
    FETCH STORE FETCHSIZE STORESIZE EXISTS DELETE CLEAR UNTIE
    PUSH POP SHIFT UNSHIFT SPLICE EXTEND FIRSTKEY NEXTKEY SCALAR
    WRITE PRINT PRINTF READLINE GETC READ CLOSE FILENO BINMODE EOF TELL SEEK OPEN
    TO_JSON FREEZE THAW STORABLE_freeze STORABLE_thaw
);

# Perl keywords and builtin functions as bareword-call candidates.  A sub
# whose name is already a keyword/builtin is never renamed (calls to
# "map(...)", "format" etc. must keep resolving to the builtin), and generated
# short names are reserved away from every surviving word in the file.
my %PERL_WORDS = map { $_ => 1 } qw(
    __FILE__ __LINE__ __PACKAGE__ __SUB__ BEGIN CHECK CORE DESTROY END
    UNITCHECK AUTOLOAD abs accept alarm and atan2 bind binmode bless break
    caller chdir chmod chomp chop chown chr chroot close closedir cmp connect
    continue cos crypt dbmclose dbmopen default defined delete die do dump
    each else elsif endgrent endhostent endnetent endprotoent endpwent
    endservent eof eq eval exec exists exit exp fc fcntl fileno flock for
    foreach fork format formline ge getc getgrent getgrgid getgrnam
    gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr getnetbyname
    getnetent getpeername getpgrp getppid getpriority getprotobyname
    getprotobynumber getprotoent getpwent getpwnam getpwuid getservbyname
    getservbyport getservent getsockname getsockopt given glob gmtime goto
    grep gt hex if index int ioctl join keys kill last lc lcfirst le length
    link listen local localtime lock log lstat lt m map mkdir msgctl msgget
    msgrcv msgsnd my ne next no not oct open opendir or ord our pack package
    pipe pop pos print printf prototype push q qq qr quotemeta qw qx rand
    read readdir readline readlink readpipe recv redo ref rename repeat
    require reset return reverse rewinddir rindex rmdir s say scalar seek
    seekdir select semctl semget semop send setgrent sethostent setnetent
    setpgrp setpriority setprotoent setpwent setservent setsockopt shift
    shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort
    splice split sprintf sqrt srand stat state study sub substr symlink
    syscall sysopen sysread sysseek system syswrite tell telldir tie tied
    time times tr truncate uc ucfirst umask undef unless unlink unpack
    unshift untie until use utime values vec wait waitpid wantarray warn when
    while write x xor y
);

# Letters Perl reads as a file test after a minus: a sub renamed to `k`
# turns `$x - _CONST` (glued to `$x-_CONST` by the whitespace pass) into the
# file test `$x-k`.
my %FILETEST = map { $_ => 1 } qw(r w x o R W X O e z s f d l p S b c t u g k T B A M C);

# True when a generated short sub name must be skipped: a keyword/builtin,
# a file-test letter, or a name already in use ($taken).
sub _sub_short_taken {
    my ($short, $taken) = @_;
    return $PERL_WORDS{$short} || $FILETEST{$short} || $taken->{$short};
}

# Packages declared in a file that loads XS code (XSLoader::load,
# DynaLoader's bootstrap).  Empty for pure-Perl files.
sub _xs_packages {
    my ($doc) = @_;
    my $loads_xs = $doc->find_first(sub {
        $_[1]->isa('PPI::Token::Word')
            && $_[1]->content =~ /^(?:XSLoader::load|(?:DynaLoader::)?bootstrap)$/
    });
    return unless $loads_xs;
    return map { $_->namespace } @{ $doc->find('PPI::Statement::Package') || [] };
}

# Names of every sub the file/bundle may legally shorten.  A sub name is
# eligible only when it survives all the guards: a plain identifier, not a
# kept magic/protocol name, not a perl keyword/builtin, never seen inside a
# stringy/regex token (dispatch by string would silently bypass the rename),
# and not colliding with any word that stays in the output.
sub _sub_eligible {
    my ($name, $in_string_word) = @_;
    return 0 unless defined $name;
    return 0 if length($name) <= 1;
    return 0 unless $name =~ /^[A-Za-z_]\w*$/;
    return 0 if $KEEP{$name} || $SUBKEEP{$name} || $PERL_WORDS{$name};
    return 0 if $in_string_word && $in_string_word->{$name};
    return 1;
}

# What a `*name` glob token is assigned: 'code' when the assignment installs
# a sub (*x = \&y, *x = sub {...}, *x = $coderef, *x = cond ? $a : $b,
# *x{CODE} = ...), 'data' when it aliases a variable, filehandle or another
# glob (*x = \@y, *x = \*STDOUT, *x = *y, *x = 'y', *x{SCALAR} = ...), undef when the
# glob is not assigned to.  The bundle collector and the renamer both ask
# this, so a glob-installed sub and its callers are always renamed together.
sub _glob_assign_kind {
    my ($glob) = @_;
    my $next = $glob->snext_sibling or return;
    my $slot;
    if ($next->isa('PPI::Structure::Subscript') || $next->isa('PPI::Structure::Block')) {
        ($slot) = $next->content =~ /^\{\s*(\w+)\s*\}$/;
        $next = $next->snext_sibling or return;
    }
    return unless $next->isa('PPI::Token::Operator') && $next->content eq '=';
    return $slot eq 'CODE' ? 'code' : 'data' if defined $slot;
    my $rhs = $next->snext_sibling or return 'code';
    return 'data' if $rhs->isa('PPI::Token::Symbol') && $rhs->content =~ /^\*/;
    # *x = 'name' aliases the glob of that name
    return 'data' if $rhs->isa('PPI::Token::Quote') || $rhs->isa('PPI::Token::Number');
    if ($rhs->isa('PPI::Token::Cast') && $rhs->content eq '\\') {
        my $target = $rhs->snext_sibling;
        return 'data'
            unless $target && $target->isa('PPI::Token::Symbol') && $target->content =~ /^&/;
    }
    return 'code';
}
# ---------------------------------------------------------------------------
# Entry points: process() runs the whole minifier; _minify_doc is the shared
# core (disable individual passes by removing their one call below).
# ---------------------------------------------------------------------------

sub process {
    my ($src, %opts) = @_;
    my $doc = PPI::Document->new(\$src) or return $src;
    return _minify_doc($doc, %opts);
}

# Minification core shared by process() and process_deps(): apply the PPI
# comment/POD prune and the rename/whitespace passes to an already-parsed
# document, then optionally the rewrite pass (rewrite => 1).  Returns the
# serialized, minified string.
sub _minify_doc {
    my ($doc, %opts) = @_;
    my $rename_vars = $opts{rename_vars} // $opts{rename} // 1;
    my $rename_subs = $opts{rename_subs};
    my $gmap = $opts{global_rename_vars} // $opts{global_rename}; # pkg => { old=>short }
    my $glex = $opts{global_lexicals};     # bundle-wide `my`/`state` names
    my $gs = $opts{global_subs};           # bundle-wide name-global sub map
    my $mods = $opts{global_modules} || {};       # { map, pkgs } module-rename struct
    my $rename_exports = $opts{rename_exports};   # rename export/import protocol strings
    $doc->prune('PPI::Token::Comment');
    $doc->prune('PPI::Token::Pod');

    return $doc->serialize unless $doc->children;

    my %rename;     # original name -> short name (global per file)
    my $counter = 0;

    if ($rename_vars) {
        my %in_string;

        # Pass 1a: collect variable names used inside regex CODE regions
        # ((?{ ... }) blocks, s///e replacements) and refuse them renames —
        # those regions are real Perl, opaque to this pass, and a renamed
        # lexical referenced there would break.  Names in the interpolating
        # pattern/replacement text are fine: _rewrite_names_in_regexes rewrites
        # them to match the symbol renames later.
        _regex_exempt_names_doc($doc, \%in_string, undef);

        # Pass 1b: collect rename candidates from my declarations only.
        # `local $x` declares a package global (even bare: it localises
        # $PKG::x), and `our $x` is likewise a package global; renaming a
        # global while any surviving $PKG::x reference reads it would break
        # cross-package semantics. `my $x` is a true file lexical, never
        # reachable as a package global, so it is always safe to rename.
        my $class_feature = _uses_class_feature($doc);
        my @decl_names = _collect_lexical_candidates($doc, \%in_string, $class_feature);

        # Pass 1c: reserve every symbol name that survives unrenamed,
        # so generated short names can never shadow or collide with them.
        my $reserved = _reserve_names($doc, $gmap);

        # Assign short names in declaration order
        for my $name (@decl_names) {
            next if exists $rename{$name};
            my $short;
            do { $short = name_gen($counter++) } while $KEEP{$short} || $reserved->{$short};
            $rename{$name} = $short;
        }
        # Pass 1d: rewrite interpolated variable names inside strings so they
        # keep agreeing with the renames applied to symbols in Pass 2.
        _rewrite_names_in_strings($doc, \%rename, $gmap, $glex, $mods)
            if $rename_vars || $gmap || ($mods && $mods->{pkgs});
        # Pass 1d': rewrite variables interpolated inside regex pattern /
        # replacement text (m/.../, s/.../.../, qr(...)) the same way, so a
        # qr/\Q$query\E/i built from a now-short lexical still matches what the
        # code references, and bundle globals ($gmap) interpolated in patterns
        # follow their renames too.  Code regions ((?{ ... }), s///e
        # replacements) are exempted in Pass 1a and never touched here.
        _rewrite_names_in_regexes($doc, \%rename, $gmap, $glex, $mods);
    }
    # Module-prefix rewrite only (no variable renames): when variable
    # renaming is off but namespaces move, interpolated fully-qualified
    # globals in strings ("$App::Saisons::VERSION") and readlines must still
    # follow the module rename.  Without rename_vars no my-variable map is
    # built, so this can never per-token-rename a scalar.
    if (!$rename_vars && $mods && $mods->{pkgs}) {
        _rewrite_names_in_strings($doc, {}, undef, undef, $mods);
    }

    my %submap;        # method/sub name -> short name
    %submap = %{ _build_sub_map($doc, $gs, $rename_subs, $rename_exports) };

    # Pass 2: strip whitespace, then rename variables, subs and module
    # components in place.  @needs_space inspects only char-class edges that
    # the renames preserve (a shortened identifier still ends and starts \w,
    # sigils and delimiters are untouched), so the collapse and the rename
    # are independent token walks and each stays readable on its own.
    _strip_whitespace($doc);
    _apply_renames($doc,
        rename => \%rename, gmap => $gmap, glex => $glex,
        mods => $mods, submap => \%submap, rename_vars => $rename_vars,
        rename_exports => $rename_exports);

    # Protocol-string + module-name string rewrite.  Runs after the token walk
    # so %submap is final (bundle global_subs or the file's own map).  Only
    # plain single-word / module-shaped / module-path strings are touched; any
    # string with escapes, sigils or spaces is left alone.
    _rewrite_protocol_strings($doc,
        submap => \%submap, rename_exports => $rename_exports,
        gmap => $gmap, glex => $glex, mods => $mods);

    _rewrite_doc($doc) if $opts{rewrite};

    return $doc->serialize;
}

# ---------------------------------------------------------------------------
# Name-policy gates.  _var_renameable is THE single place that decides whether
# a variable name may be shortened; every collector (file lexicals here, the
# bundler's globals in collect_bundle_globals) funnels through it.  Per-version
# whitelists/blacklists (e.g. new keywords or class-feature names on newer
# perls) are added here, in one spot, via the is_global / class_feature
# context instead of scattered edit sites.
#
# Global policy (is_global): a package global is renamed only when it can
# never be ambiguous with a lexical anywhere in the bundle, never appears
# inside opaque stringy/regex text, is not a KEEP name and not an all-caps
# constant.  Lexical policy: `my`/`state` names rename unless one character,
# a $^X-style special, inside a regex code region, or otherwise blocked —
# `self`/`class` are ordinary lexicals in classic code (my $self = shift)
# but become keywords that must not be renamed under the 5.38+ class feature.
sub _var_renameable {
    my ($name, %ctx) = @_;
    return 0 if length($name) <= 1;
    return 0 if $name =~ /\^/;             # $^X / %^H / ${^...} specials
    return 0 if $name =~ /::/;             # package globals are never renamed
    if ($ctx{is_global}) {
        return 0 if $ctx{lexicals} && $ctx{lexicals}{$name};
        return 0 if $ctx{in_string} && $ctx{in_string}{$name};
        return 0 if $KEEP{$name};
        return 0 if $name =~ /^[A-Z_]+$/;  # all-caps: constants / magic ($!), ...
        return 1;
    }
    return 0 if $ctx{in_string} && $ctx{in_string}{$name};
    return 0 if $KEEP{$name} && $name ne 'self' && $name ne 'class';
    return 0 if $ctx{class_feature} && ($name eq 'self' || $name eq 'class');
    return 1;
}

# Pass 1a: walk every regex token and mark the variable names used inside
# regex CODE regions ((?{ ... }) blocks, s///e replacements) as
# unrenameable.  Those regions are real Perl, opaque to this pass, and a
# renamed lexical referenced there would break.  Names in the interpolating
# pattern/replacement text are fine: _rewrite_names_in_regexes rewrites them
# to match the symbol renames later.  With a second hash, code-region BARE
# WORDS freeze the sub map the same way.
sub _regex_exempt_names_doc {
    my ($doc, $in_string, $in_string_word) = @_;
    my $tok = $doc->first_token;
    while ($tok) {
        my $r = ref($tok);
        if ($r eq 'PPI::Token::Regexp::Match'
         || $r eq 'PPI::Token::Regexp::Substitute'
         || $r eq 'PPI::Token::QuoteLike::Regexp') {
            _regex_exempt_names($in_string, $in_string_word, $r, $tok->content);
        } elsif ($r eq 'PPI::Token::Quote::Single'
              || $r eq 'PPI::Token::Quote::Literal') {
            _string_exempt_names($in_string, $in_string_word, $tok->content);
        } elsif ($r eq 'PPI::Token::HereDoc'
              && ($tok->{_mode} || '') !~ /^(?:interpolate|command)$/) {
            _string_exempt_names($in_string, $in_string_word,
                                 join '', $tok->heredoc);
        }
        $tok = $tok->next_token;
    }
}

# Names referenced with a sigil inside a NON-interpolating string are frozen
# like regex code regions: such strings can be eval'd as code at runtime
# (Sub::Defer builds its deferred subs in a q[...] template that closes over
# the file lexicals $undeferred / $deferred_info), and a renamed lexical
# referenced there would break.  Interpolating strings are fine: their
# references are rewritten to match the renames.
sub _string_exempt_names {
    my ($in_string, $in_string_word, $text) = @_;
    while ($text =~ /[\$\@\%]\{?([A-Za-z_]\w*)/g) {
        $in_string->{$1} = 1;
        $in_string_word->{$1} = 1 if $in_string_word;
    }
}

# Pass 1b: collect rename candidates from my declarations only, in
# declaration order.  `local $x` declares a package global (even bare: it
# localises $PKG::x), and `our $x` is likewise a package global; renaming a
# global while any surviving $PKG::x reference reads it would break
# cross-package semantics.  `my $x` is a true file lexical, never reachable
# as a package global, so it is always safe to rename — subject to the
# shared _var_renameable gate.
sub _collect_lexical_candidates {
    my ($doc, $in_string, $class_feature) = @_;
    my @decl_names;
    my $tok = $doc->first_token;
    while ($tok) {
        if (ref($tok) eq 'PPI::Token::Word' && $tok->content eq 'my') {
            my $next = $tok->snext_sibling or do { $tok = $tok->next_token; next };
            my @syms;
            if ($next->isa('PPI::Token::Symbol')) {
                @syms = ($next);
            } elsif ($next->isa('PPI::Structure::List')) {
                @syms = @{ $next->find('PPI::Token::Symbol') || [] };
            }
            for my $sym (@syms) {
                my (undef, $name) = $sym->content =~ /^([\$\@\%])(.+)$/ or next;
                push @decl_names, $name
                    if _var_renameable($name,
                        is_global => 0, class_feature => $class_feature,
                        in_string => $in_string);
            }
        }
        $tok = $tok->next_token;
    }
    return @decl_names;
}

# Pass 1c: reserve every symbol name that survives unrenamed, so generated
# short names can never shadow or collide with them.  Also reserves every
# bundle-global short name: any of them may be referenced (or declared)
# unqualified in this very file, so a `my` short of the same name would
# shadow it.
sub _reserve_names {
    my ($doc, $gmap) = @_;
    my %reserved;
    my $tok = $doc->first_token;
    while ($tok) {
        if (ref($tok) eq 'PPI::Token::Symbol' || ref($tok) eq 'PPI::Token::ArrayIndex') {
            my (undef, $name) = $tok->content =~ /^((?:\$#|[\$\@\%]))(.+)$/;
            $reserved{$name} = 1 if defined $name && length $name;
        }
        $tok = $tok->next_token;
    }
    if ($gmap) {
        $reserved{$_} = 1 for map { values %$_ } values %{ $gmap };
    }
    return \%reserved;
}

# Pass 1e: build the method/sub rename map.  With a bundle-wide global_subs
# map ($gs) that map is authoritative; otherwise a name is eligible only if
# it never appears inside a stringy/regex token (dispatch by string —
# can(), q{...}, "$t->format" interpolation — would silently bypass the
# rename), then assigned a short name that collides with no word that
# survives in the output.  Returns a hashref (possibly empty).
sub _build_sub_map {
    my ($doc, $gs, $rename_subs, $rename_exports) = @_;
    my %submap;
    if ($gs) {
        %submap = %$gs if %$gs;
    } elsif ($rename_subs) {
        my %in_string_word;
        my $tok = $doc->first_token;
        while ($tok) {
            my $r = ref($tok);
            if ($r =~ /^(?:PPI::Token::Quote::(?:Double|Interpolate|Single|Literal)
                         |PPI::Token::QuoteLike::(?:Regexp|Words|Readline|Backtick|Command)
                         |PPI::Token::Regexp::(?:Match|Substitute))$/x) {
                # Import/export protocol words are renamed in step with the
                # subs they name; they must not freeze the name (see
                # rename_exports / _protocol_site).  Anything else quoting a
                # name — can('x'), qw in data, template text — freezes it.
                my $protocol = $rename_exports
                    && ($r =~ /^PPI::Token::Quote::(?:Single|Double|Literal)$/
                     || $r eq 'PPI::Token::QuoteLike::Words')
                    && _protocol_site($tok);
                unless ($protocol) {
                    my $c = $tok->content;
                    while ($c =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word{$1} = 1 }
                }
            } elsif ($r eq 'PPI::Token::HereDoc') {
                my @hd = $tok->heredoc;
                my $c = join('', @hd);
                while ($c =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word{$1} = 1 }
            }
            $tok = $tok->next_token;
        }
        my @sub_names;
        $tok = $doc->first_token;
        while ($tok) {
            if (ref($tok) eq 'PPI::Token::Word' && $tok->content eq 'sub') {
                my $next = $tok->snext_sibling;
                if ($next && $next->isa('PPI::Token::Word')
                    && _sub_eligible($next->content, \%in_string_word)) {
                    push @sub_names, $next->content;
                }
            }
            $tok = $tok->next_token;
        }
        my %reserved;
        $tok = $doc->first_token;
        while ($tok) {
            $reserved{$tok->content} = 1 if ref($tok) eq 'PPI::Token::Word';
            $tok = $tok->next_token;
        }
        my $scounter = 0;
        for my $name (@sub_names) {
            next if exists $submap{$name};
            my $short;
            do { $short = name_gen($scounter++) } while _sub_short_taken($short, \%reserved);
            $submap{$name} = $short;
        }
    }
    return \%submap;
}

# Record each token's position and the current package in lexical order, so a
# later token walk can resolve an unqualified name to its package the same
# way the symbol pass does.  Returns (\%index_of_token, \@package_at_index).
sub _token_package_index {
    my ($doc) = @_;
    my (%idx, @pkg);
    my $pkg = 'main';
    my $n = 0;
    my $t = $doc->first_token;
    while ($t) {
        $idx{ refaddr($t) } = $n;
        if (ref($t) eq 'PPI::Token::Word' && $t->content eq 'package'
             && $t->statement && $t->statement->isa('PPI::Statement::Package')) {
            $pkg = $t->statement->namespace;
        }
        $pkg[$n] = $pkg;
        $n++;
        $t = $t->next_token;
    }
    return (\%idx, \@pkg);
}

# Pass 2 (whitespace): collapse inter-token whitespace to a single space only
# where two neighbouring tokens would otherwise glue into different syntax
# (needs_space); delete it everywhere else.  The __END__/__DATA__ marker keeps
# the newline that makes it a marker, both before and after it.
sub _strip_whitespace {
    my ($doc) = @_;
    my $pending = 0;        # heredoc openers awaiting a newline anchor
    my $tok = $doc->first_token;
    while ($tok) {
        if (ref($tok) eq 'PPI::Token::HereDoc') {
            $pending++;
        } elsif (ref($tok) eq 'PPI::Token::Whitespace') {
            my $prev = $tok->previous_sibling;
            my $next = $tok->next_sibling;
            $prev = $prev->previous_sibling while $prev && ref($prev) eq 'PPI::Token::Whitespace';
            $next = $next->next_sibling     while $next && ref($next) eq 'PPI::Token::Whitespace';
            my $has_nl = $tok->content =~ /\n/;
            if ($prev && $prev->isa('PPI::Token::Separator') && $has_nl) {
                # __END__ / __DATA__ marker: freeze the whitespace after the
                # marker (skip the collapse below). The marker must finish
                # its own line, or the following data is folded into the
                # marker's line — changing what <DATA> yields, and, when the
                # data starts with punctuation, gluing it onto the marker
                # (`__DATA__\n{pod}` -> `__DATA__{pod}`), ending the data
                # section where it did not before.
            } elsif ($next && ($next->isa('PPI::Statement::Data') || $next->isa('PPI::Statement::End'))
                     && $has_nl) {
                # ... and the newline before it: collapsing that turns
                # `;__DATA__` into one line, and a mid-line marker is no
                # marker at all — perl only honours it at the start of a line,
                # so the data section would silently vanish.
            } elsif ($pending && $has_nl) {
                # Heredoc anchor: PPI::Document::serialize emits a heredoc's
                # body + terminator at the first newline-containing token after
                # the opener.  Collapsing that newline moves the body to EOF.
                $tok->set_content("\n");
                $pending = 0;
            } elsif ($prev && $next && needs_space($prev, $next)) {
                $tok->set_content(' ');
            } else {
                $tok->set_content('');
            }
        }
        $tok = $tok->next_token;
    }
}

# Pass 2 (renames): rename symbols, subs and module components in place, one
# token at a time so each token is rewritten exactly once.  Whitespace is
# already collapsed by _strip_whitespace; the rename never changes the
# char-class edges @needs_space inspects (a shortened identifier still ends
# and starts \w, sigils and delimiters are untouched), so the two walks can
# safely be separate.
sub _apply_renames {
    my ($doc, %a) = @_;
    my $rename = $a{rename} || {};
    my $gmap = $a{gmap};
    my $glex = $a{glex};
    my $mods = $a{mods} || {};
    my %submap = %{ $a{submap} || {} };
    my $rename_vars = $a{rename_vars};
    my $rename_exports = $a{rename_exports};
    my $cur_pkg = 'main';                  # current package for unqualified refs
    my $tok = $doc->first_token;
    while ($tok) {
        my $ref = ref($tok);

        if (%submap && $ref eq 'PPI::Token::Symbol'
         && $tok->content =~ /^&((?:[A-Za-z_]\w*::)*)([A-Za-z_]\w*)$/) {
            # &name / &Pkg::name / \&Pkg::name are direct sub references.
            if (defined(my $new = $submap{$2})) {
                $tok->set_content('&' . $1 . $new);
            }
        } elsif (%submap && $ref eq 'PPI::Token::Symbol'
                 && $tok->content =~ /^\*((?:[A-Za-z_]\w*::)*)([A-Za-z_]\w*)$/
                 && defined($submap{$2})) {
            # A glob named like a mapped sub (*alias = \&sub, *CONST = $code,
            # local *name) is renamed in step with the calls, so the sub it
            # installs and every caller agree.  A data alias (*g = \@arr) is
            # left alone.
            if ((_glob_assign_kind($tok) // '') ne 'data') {
                $tok->set_content('*' . $1 . $submap{$2});
            }
        } elsif (($rename_vars || $gmap || $mods->{pkgs}) && ($ref eq 'PPI::Token::Symbol' || $ref eq 'PPI::Token::ArrayIndex')) {
            my ($sigil, $name) = $tok->content =~ /^((?:\$#|[\$\@\%]))(.+)$/ or do {
                $tok = $tok->next_token; next;
            };
            # Module rename first: $App::Saisons::VERSION -> $a::Saisons::VERSION.
            # The rest of the chain re-checks the rewritten name ($gmap keys are
            # the renamed packages in a bundle).
            if ($mods->{pkgs} && $name =~ /::/) {
                my $ren = rename_module_name($name, $mods);
                if (defined $ren && $ren ne $name) {
                    $tok->set_content($sigil . $ren);
                    $name = $ren;
                }
            }
            if ($rename_vars && exists $rename->{$name}) {
                $tok->set_content($sigil . $rename->{$name});
            } elsif ($gmap && $name =~ /^(\S+?)::(\w+)$/) {
                # Fully-qualified $PKG::name: unambiguous, so rename whenever
                # the enclosing package's global is in the bundle map.
                my ($g_pkg, $g_base) = ($1, $2);
                my $gopkg = _gmap_key($g_pkg, $gmap, $mods);
                if (defined(my $g_new =
                        $gmap->{$gopkg} && $gmap->{$gopkg}{$g_base})) {
                    $tok->set_content($sigil . $g_pkg . '::' . $g_new);
                }
            } elsif ($gmap && !( $glex && $glex->{$name} )) {
                # Unqualified name: a package global of the current package.
                # Skip it if any `my $name` anywhere in the bundle could make
                # it ambiguous.  (Short names are generated to avoid every
                # bundle lexical and global, so they stay unambiguous too.)
                my $opkg = _gmap_key($cur_pkg, $gmap, $mods);
                if (defined(my $g_new = $gmap->{$opkg} && $gmap->{$opkg}{$name})) {
                    $tok->set_content($sigil . $g_new);
                }
            }
        } elsif ($ref eq 'PPI::Token::Word' && $tok->content eq 'package'
                 && $tok->statement && $tok->statement->isa('PPI::Statement::Package')) {
            $cur_pkg = $tok->statement->namespace;
        } elsif ($ref eq 'PPI::Token::Word') {
            # Module rename: `package App::Thing`, `App::Thing::sub(...)`, bare
            # class names — everything but the leaf components.  Runs before
            # the sub rename so a qualified Pkg::sub tail is shortened on the
            # already-rewritten package part; the current package is re-read so
            # unqualified $gmap lookups track the renamed namespace.
            if ($mods->{pkgs} && $tok->content =~ /::/) {
                my $ren = rename_module_name($tok->content, $mods);
                if (defined $ren && $ren ne $tok->content) {
                    $tok->set_content($ren);
                    my $st = $tok->statement;
                    if ($st && $st->isa('PPI::Statement::Package')) {
                        $cur_pkg = $st->namespace;
                    }
                }
            }
            if (%submap) {
                # The module-name word of a use/require names a package, not a
                # sub — never shorten it via the sub map (a pragma named in
                # %USE_LITERAL_ARGS is already excluded from protocol sites).
                my $ist = $tok->statement;
                my $inc_mod = $ist && $ist->isa('PPI::Statement::Include')
                    && defined $ist->module && $ist->module eq $tok->content;
                if (!$inc_mod) {
                    my $name = $tok->content;
                    my $new = $submap{$name};
                    if (defined $new) {
                        if ($rename_exports && _protocol_site($tok)) {
                            # qw() import-list / export-table / bareword can()-arg:
                            # rename with no context check — these are always the
                            # sub name, and the last bareword of a qw() has no
                            # sibling to disambiguate it.
                            $tok->set_content($new);
                        } elsif (_sub_word_context($tok, 0)) {
                            $tok->set_content($new);
                        }
                    } elsif ($name =~ /^(.+)::([A-Za-z_]\w*)$/ && defined($new = $submap{$2})) {
                        # Qualified Pkg::name (PPI keeps it as one Word) — rename the
                        # tail only when the whole token is a sub/function reference.
                        if (_sub_word_context($tok, 1)) {
                            $tok->set_content($1 . '::' . $new);
                        }
                    }
                }
            }
        }

        $tok = $tok->next_token;
    }
}

# The renamed form of a string that names a bundled module, either as a
# package (`App::Thing`) or a path (`App/Thing.pm`); undef if it does not
# name one.  Used for quoted strings and qw() words alike.
sub _renamed_module_string {
    my ($s, $mods) = @_;
    my $new;
    if ($s =~ /\A[A-Za-z_]\w*(?:\/[A-Za-z_]\w*)+\.pm\z/) {
        $new = rename_module_path($s, $mods);
    } elsif ($s =~ /\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)+\z/) {
        $new = rename_module_name($s, $mods);
    }
    return defined $new && $new ne $s ? $new : undef;
}

# Protocol-string + module-name string rewrite.  Runs after the token walk so
# %submap is final (bundle global_subs or the file's own map).  Only plain
# single-word / module-shaped / module-path strings are touched; any string
# with escapes, sigils or spaces is left alone.
sub _rewrite_protocol_strings {
    my ($doc, %a) = @_;
    my $submap = $a{submap} || {};
    my $rename_exports = $a{rename_exports};
    my $gmap = $a{gmap};
    my $glex = $a{glex};
    my $mods = $a{mods} || {};
    return unless (($rename_exports && %$submap) || ($mods && $mods->{pkgs}));

    # Record each token's package so $var words in an @EXPORT_OK=qw() list
    # resolve to the current (renamed) package's bundle-global entry.
    my ($pix, $ppkg) = _token_package_index($doc);

    my $st = $doc->first_token;
    while ($st) {
        my $sr = ref($st);
        if ($sr eq 'PPI::Token::Quote::Single'
         || $sr eq 'PPI::Token::Quote::Double'
         || $sr eq 'PPI::Token::Quote::Literal') {
            my $c = $st->content;
            my ($q, $inner) = $c =~ /^(['"])(.*)\1$/s ? ($1, $2) : (undef, undef);
            if (defined $q) {
                my $rewritten;
                if ($rename_exports && $inner =~ /^[A-Za-z_]\w*$/
                    && _protocol_site($st)
                    && defined(my $nnew = $submap->{$inner})) {
                    $rewritten = $nnew;
                } elsif ($mods->{pkgs}) {
                    $rewritten = _renamed_module_string($inner, $mods);
                }
                $st->set_content($q . $rewritten . $q) if defined $rewritten;
            }
        }
        elsif ($sr eq 'PPI::Token::QuoteLike::Words'
            && (($rename_exports && _protocol_site($st)) || $mods->{pkgs})) {
            # qw(import list) / qw(export table): one token holding several
            # barewords.  Sub and variable names are only renamed when the
            # whole literal sits at a protocol site (use list, @EXPORT*
            # assignment) — a plain `my @x = qw(foo)` is data.  Package names
            # (`our @ISA = qw(Moo::Object)`) follow the module rename like
            # any other string.
            my $protocol = $rename_exports && _protocol_site($st);
            my $c = $st->content;
            if ($c =~ /^qw(.)(.*\z)/s) {
                # qw(DELIMS): (.) consumes the opener, so $2 is the
                # body plus the trailing closer.
                my $open = $1;
                my %cls = ('(' => ')', '[' => ']', '{' => '}', '<' => '>');
                my $close = $cls{$open} // $open;
                my $tail = $2;
                if (substr($tail, -1) eq $close) {
                    my $body = substr($tail, 0, length($tail) - 1);
                    if ($body !~ /^[A-Za-z_]\w*=[A-Za-z_]\w*$/) {
                        my @parts = split(/(\s+)/, $body);
                        my $changed;
                        for my $p (@parts) {
                            if ($p eq '' || $p =~ /^\s+$/) { next }
                            if ($protocol && $p =~ /^[A-Za-z_]\w*$/
                                && defined(my $wnew = $submap->{$p})) {
                                $p = $wnew;
                                $changed = 1;
                            } elsif ($protocol && $p =~ /^\$([A-Za-z_]\w*)$/
                                     && defined(my $vnew = _protocol_var_new_name(
                                           $1, $ppkg->[ $pix->{refaddr($st)} ],
                                           $st, $gmap, $glex, $mods))) {
                                $p = '$' . $vnew;
                                $changed = 1;
                            } elsif ($mods->{pkgs}
                                     && defined(my $mnew = _renamed_module_string($p, $mods))) {
                                $p = $mnew;
                                $changed = 1;
                            }
                        }
                        $st->set_content('qw'
                            . $open . join('', @parts) . $close) if $changed;
                    }
                }
            }
        }
        $st = $st->next_token;
    }
}

# ---------------------------------------------------------------------------
# Optional value-preserving rewrite pass.
# ---------------------------------------------------------------------------

# Optional pass that rewrites code to shorter equivalent forms, on top of the
# prune/rename/whitespace passes.  Kept as its own method with a single call
# site above so it can be disabled (rewrite => 0) or deleted wholesale (drop
# this method and that one call) if it ever proves unsafe.  Only rewrites that
# are value-preserving are attempted:
#   foreach -> for                      keywords are synonyms
#   m/.../  -> /.../ after =~ or !~     m is optional with / delimiters
#   `;` before `}` dropped              trailing empty statement
#   `$x += 1;` -> `$x++;` (mid-block)   *= 1 vs ++ differ in return value
#   `$x = $x OP $y;` -> `$x OP= $y;`    both assignment forms return OP= value
#   `print($x);` -> `print $x;`         parens dropped on builtin calls
my %PAREN_DROP = map { $_ => 1 } qw(
    print printf sprintf say warn die return exit chomp chop shift unshift
    push pop splice keys values each delete exists defined ref bless length
    substr join split reverse sort grep map scalar rand srand int sqrt abs
    exp log sin cos lc uc lcfirst ucfirst ord chr caller wantarray
);
my %OP_ASSIGN = map { $_ => 1 } qw(. + - * / %);

# ---------------------------------------------------------------------------
# Stringy / regex text rewriters, so quoted text and patterns track the
# symbol renames.
# ---------------------------------------------------------------------------

# Rewrite interpolated variable references inside string-like tokens so the
# quoted text keeps resolving to the same variable after symbol renames.
#
#   "my name is $name"     ->  "my name is $c"
#   qq{_build_${name}}     ->  qq{_build_${c}}
#   <<"EOF" ... $name ...  ->  body rewritten too
#
# The symbol pass renames by NAME, not by scope (every $name in the file is
# $c once `my $name` is renamed), so the string text follows the same rule: a
# "$name" is rewritten exactly when the symbol pass rewrites that name.
# Qualified $PKG::name uses $gmap; an unqualified name uses $rename (lexical)
# or the current package's $gmap entry unless the name is a lexical anywhere
# in the bundle ($glex).
#
# Names refused by Pass 1a (they appear in a regex code region) are never in
# $rename, so they stay put.  Escaped dollars ("\$name" or "\\\\$name") and
# literal-only tokens (q{...}, <<'EOF', m'...') are left untouched, because
# there the text is literal data, not a variable reference.
sub _rewrite_names_in_strings {
    my ($doc, $rename, $gmap, $glex, $mods) = @_;
    return unless %$rename || ($gmap && %$gmap) || ($mods && $mods->{pkgs});

    my ($idx, $pkg) = _token_package_index($doc);

    my $tok = $doc->first_token;
    while ($tok) {
        my $r = ref($tok);
        my $here = ($r eq 'PPI::Token::HereDoc')
                 && ($tok->{_mode} || '') =~ /^(?:interpolate|command)$/;
        my $quote = $r =~ /^(?:PPI::Token::Quote::(?:Double|Interpolate)
                             |PPI::Token::QuoteLike::(?:Readline|Backtick|Command))$/x;
        if ($quote || $here) {
            my $src = $quote ? $tok->content : join('', @{ $tok->{_heredoc} // [] });
            my $new = _rewrite_string_text($src, $pkg->[ $idx->{ refaddr($tok) } ],
                                           $gmap, $glex, $rename || {}, $mods);
            if ($new ne $src) {
                if ($quote) {
                    $tok->set_content($new);
                } else {
                    @{ $tok->{_heredoc} } = split /(?<=\n)/, $new;
                }
            }
        }
        $tok = $tok->next_token;
    }
}

# Split a regex pattern/replacement section into ordinary text and embedded
# code regions ((?{ ... }) / (??{ ... })).  Code regions are returned tagged
# 'code', everything else 'text'.  The escaping of a following character is
# tracked so \(?{ never starts a code region.
sub _regex_parts {
    my ($text) = @_;
    my @parts;
    my $i = 0;
    my $n = length $text;
    my $acc = '';
    while ($i < $n) {
        my $ch = substr($text, $i, 1);
        if ($ch eq '\\') {
            $acc .= $ch;
            $i++;
            $acc .= substr($text, $i, 1) if $i < $n;
            $i++;
            next;
        }
        if ($ch eq '(' && substr($text, $i + 1, 1) eq '?'
         && (substr($text, $i + 2, 1) eq '{' || substr($text, $i + 3, 1) eq '{')) {
            push @parts, ['text', $acc];
            $acc = '';
            my $j = $i + (substr($text, $i + 3, 1) eq '{' ? 4 : 3);
            my $depth = 0;
            while ($j < $n) {
                my $d = substr($text, $j, 1);
                if ($d eq '\\') { $j += 2; next }
                elsif ($d eq '{') { $depth++ }
                elsif ($d eq '}' && $depth) { $depth-- }
                elsif ($d eq '}' && !$depth) { last }
                $j++;
            }
            if ($j < $n) {
                $j++;
                $j++ if substr($text, $j, 1) eq ')';
            }
            push @parts, ['code', substr($text, $i, $j - $i)];
            $i = $j;
            next;
        }
        $acc .= $ch;
        $i++;
    }
    push @parts, ['text', $acc] if length $acc;
    return @parts;
}

# Pass 1a / bundle-collect helper: mark every variable name appearing inside a
# regex code region as unrenameable ($in_string).  A pattern's
# (?{ ... })/(??{ ... }) blocks and a s///e replacement are real Perl code;
# the minifier leaves them verbatim, so a lexical referenced there must keep
# its name too.  With a second hash, code-region BARE WORDS freeze the sub map
# ($in_string_word) the same way — they can never be rewritten in step.
sub _regex_exempt_names {
    my ($in_string, $in_string_word, $class, $content) = @_;
    my $pr = _parse_regex($class, $content) or return;
    return if $pr->{single};
    for my $part (_regex_parts($pr->{pat})) {
        next unless $part->[0] eq 'code';
        while ($part->[1] =~ /[\$\@]\{?([A-Za-z_]\w*)/g) {
            $in_string->{$1} = 1;
            $in_string_word->{$1} = 1 if $in_string_word;
        }
        if ($in_string_word) {
            while ($part->[1] =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word->{$1} = 1 }
        }
    }
    if (defined $pr->{repl} && $pr->{mods} =~ /e/) {
        while ($pr->{repl} =~ /[\$\@]\{?([A-Za-z_]\w*)/g) {
            $in_string->{$1} = 1;
            $in_string_word->{$1} = 1 if $in_string_word;
        }
        if ($in_string_word) {
            while ($pr->{repl} =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word->{$1} = 1 }
        }
    }
}

# Rewrite variables interpolated inside every regex Match/Substitute/
# QuoteLike::Regexp token, keeping token text and code in step with both the
# file's my-field renames (%rename) and the bundle-wide global map ($gmap;
# resolved exactly like _rewrite_names_in_strings / _string_new_name).  Code
# regions, single-quoted regexes (m'...', no interpolation) and escaped
# "$name" (\$x literal) are left exactly as-is.
sub _rewrite_names_in_regexes {
    my ($doc, $rename, $gmap, $glex, $mods) = @_;
    return unless %$rename || ($gmap && %$gmap);
    # Record each token's current package so unqualified bundle globals resolve
    # ($gmap keys are the renamed package names, same as the package words).
    my ($idx, $pkg) = _token_package_index($doc);
    my $tok = $doc->first_token;
    while ($tok) {
        my $r = ref($tok);
        if (($r eq 'PPI::Token::Regexp::Match'
          || $r eq 'PPI::Token::Regexp::Substitute'
          || $r eq 'PPI::Token::QuoteLike::Regexp')
        && $r ne 'PPI::Token::Regexp::Transliterate') {
            my $new = _rewrite_regex_token($r, $tok->content, $rename,
                                           $gmap, $glex, $mods,
                                           $pkg->[ $idx->{ refaddr($tok) } ]);
            $tok->set_content($new) if defined $new;
        }
        $tok = $tok->next_token;
    }
}

# Parse a regex token's content into its parts.  Returns undef when the shape
# is not understood; otherwise a hashref with the opening keyword, the
# pattern's delimiters/text, the replacement delimiters/text (for s///),
# the trailing modifier letters, and whether the delimiter was a single quote
# (which disables interpolation entirely).
sub _parse_regex {
    my ($class, $c) = @_;
    my $kw = '';
    my $idx = 0;
    if ($class eq 'PPI::Token::QuoteLike::Regexp') {
        $kw = 'qr'; $idx = 2;
    } elsif ($class eq 'PPI::Token::Regexp::Substitute') {
        $kw = 's'; $idx = 1;
    } else {
        $kw = $c =~ /^m/ ? 'm' : '';
        $idx = $kw ? 1 : 0;
    }
    $idx++ while substr($c, $idx, 1) =~ /\s/;
    my $open1 = substr($c, $idx, 1);
    return if !length $open1 || $open1 =~ /\w/;
    my %pair = ('(' => ')', '[' => ']', '{' => '}', '<' => '>');
    my $close1 = exists $pair{$open1} ? $pair{$open1} : $open1;
    my ($pat, $i) = _regex_close_index($c, $idx + 1, $open1, $close1);
    return unless defined $pat;
    my $pr = {
        kw => $kw, open1 => $open1, close1 => $close1, pat => $pat,
        open2 => '', close2 => '', repl => undef, mods => '',
        single => $open1 eq q{'}, paired => exists $pair{$open1},
    };
    if ($class eq 'PPI::Token::Regexp::Substitute') {
        my $j = $pr->{paired} ? $i + 1 : $i;
        $j++ while substr($c, $j, 1) =~ /\s/;
        my $open2 = substr($c, $j, 1);
        return if !length $open2;
        my $paired2 = exists $pair{$open2};
        my $close2 = $paired2 ? $pair{$open2} : $open2;
        my ($re, $k) = _regex_close_index($c, $j + 1, $open2, $close2);
        return unless defined $re;
        $pr->{open2} = $paired2 ? $open2 : '';
        $pr->{close2} = $close2;
        $pr->{repl} = $re;
        $pr->{mods} = substr($c, $k + 1) || '';
        $pr->{single} = 1 if $open2 eq q{'} || $open1 eq q{'};
    } else {
        $pr->{mods} = substr($c, $i + 1) || '';
    }
    return $pr;
}

# Return (pattern_text, index_of_closing_delimiter) for the section of $c
# beginning after $from, delimited with $open/$close (paired or single).
sub _regex_close_index {
    my ($c, $from, $open, $close) = @_;
    my $n = length $c;
    my $depth = 0;
    my $esc = 0;
    for (my $i = $from; $i < $n; $i++) {
        my $ch = substr($c, $i, 1);
        if ($esc) { $esc = 0; next }
        if ($ch eq '\\') { $esc = 1; next }
        if ($ch eq $open && $open ne $close) { $depth++; next }
        if ($ch eq $close) {
            if ($depth) { $depth-- }
            else { return (substr($c, $from, $i - $from), $i) }
        }
    }
    return;
}

# Rewrite one regex token; returns the new content or undef if nothing
# changed.
sub _rewrite_regex_token {
    my ($class, $content, $rename, $gmap, $glex, $mods, $pkg) = @_;
    my $pr = _parse_regex($class, $content) or return undef;
    return undef if $pr->{single};
    my $np = _rewrite_regex_text($pr->{pat}, $rename, $gmap, $glex, $mods, $pkg);
    my $nre;
    if (defined $pr->{repl}) {
        $nre = $pr->{mods} =~ /e/ ? $pr->{repl}
                                  : _rewrite_regex_text($pr->{repl}, $rename, $gmap, $glex, $mods, $pkg);
    }
    my $out = $pr->{kw} . $pr->{open1} . $np . $pr->{close1};
    $out .= $pr->{open2} . $nre . $pr->{close2} if defined $nre;
    $out .= $pr->{mods};
    return $out eq $content ? undef : $out;
}

# Rewrite interpolated $name/@name/%name (and ${name}) references in a single
# pattern or replacement section, leaving code regions, escapes and qualified
# names alone.
sub _rewrite_regex_text {
    my ($text, $rename, $gmap, $glex, $mods, $pkg) = @_;
    my $out = '';
    for my $part (_regex_parts($text)) {
        if ($part->[0] eq 'code') { $out .= $part->[1]; next }
        my $s = $part->[1];
        my $d = '';
        my $i = 0;
        my $n = length $s;
        while ($i < $n) {
            my $ch = substr($s, $i, 1);
            if ($ch eq '\\') {
                $d .= $ch;
                $i++;
                $d .= substr($s, $i, 1) if $i < $n;
                $i++;
                next;
            }
            if ($ch eq '$' || $ch eq '@' || $ch eq '%') {
                my $start = $i;
                my $sig = $ch;
                $i++;
                if ($ch eq '$' && substr($s, $i, 1) eq '#') { $sig = '$#'; $i++ }
                my $braced = 0;
                if (substr($s, $i, 1) eq '{' && substr($s, $i + 1, 1) =~ /[A-Za-z_]/) {
                    $braced = 1;
                    $i++;
                }
                my $ws = $i;
                while ($i < $n && substr($s, $i, 1) =~ /[A-Za-z0-9_]/) { $i++ }
                my $w = substr($s, $ws, $i - $ws);
                $i++ if $braced && substr($s, $i, 1) eq '}';
                if (length $w) {
                    my $nn = _string_new_name($pkg, $gmap, $glex, $rename, $w, $mods);
                    if (defined $nn && $nn ne $w) {
                        $d .= $sig . ($braced ? '{' : '') . $nn . ($braced ? '}' : '');
                    } else {
                        $d .= substr($s, $start, $i - $start);
                    }
                } else {
                    $d .= substr($s, $start, $i - $start);
                }
                next;
            }
            $d .= $ch;
            $i++;
        }
        $out .= $d;
    }
    return $out;
}

# Map a "$name" inside string text to its new name, mirroring the symbol
# pass's name-based decisions.
sub _string_new_name {
    my ($pkg, $gmap, $glex, $rename, $full, $mods) = @_;
    my ($qual, $base) = $full =~ /^(.*)::([^:]+)$/ ? ($1, $2) : (undef, $full);
    if (defined $qual) {
        if ($gmap) {
            my $ge = $gmap->{$qual};
            if ($ge && $ge->{$base}) {
                return $ge->{$base};
            }
        }
        # Module rename moved the namespace ($App::Saisons::VERSION ->
        # $a::Saisons::VERSION when App::Saisons -> a::b): the bundle's global
        # map is keyed on the renamed package, so resolve the new qualifier
        # first when this string text lives under a renamed package.
        if ($gmap && $mods->{pkgs} && $qual =~ /::/) {
            my $rq = rename_module_name($qual, $mods);
            if (my $re = $gmap->{$rq}) {
                return $re->{$base} if $re->{$base};
            }
        }
        # Reverse direction (original-keyed map + renamed qualifier in hand):
        # the module rename has already run on the token, so the qualifier is
        # the renamed name while the map still uses the original package.
        if ($gmap && (my $oq = _gmap_key($qual, $gmap, $mods))) {
            return $gmap->{$oq}{$base}
                if $oq ne $qual && exists $gmap->{$oq} && $gmap->{$oq}{$base};
        }
        return;
    }
    return $rename->{$base} if $rename && defined $rename->{$base};
    {
        # First try the current package directly; if the module rename has
        # already run on the statement (renamed $cur_pkg / $ppkg against an
        # original-keyed map), fall back through the reverse map.  `exists`
        # guards prevent autovivifying bogus empty entries for absent keys.
        my $opkg = _gmap_key($pkg, $gmap, $mods);
        return $gmap->{$opkg}{$base}
            if $gmap
            && exists $gmap->{$opkg}
            && !( $glex && $glex->{$base} )
            && $gmap->{$opkg}{$base};
    }
    return;
}

# The bundle-global map may be keyed either on the original package names
# (collect_bundle_globals output, direct process() callers) or on the renamed
# names (bin/slimpack re-keys it before processing each source).  Resolve a
# possibly-renamed package name to whichever key the caller's map uses:
# direct key first, then the reverse map (renamed name in hand, original-keyed
# map), then the forward module rename (original name in hand, renamed-keyed
# map, as in Pass 1 string/regex rewriting which runs before the module rename
# has rewritten the package words).
sub _gmap_key {
    my ($pkg, $gmap, $mods) = @_;
    return $pkg unless $gmap;
    return $pkg if exists $gmap->{$pkg};
    if ($mods) {
        return $mods->{rev}{$pkg} if $mods->{rev} && $mods->{rev}{$pkg};
        if ($mods->{pkgs} && @{ $mods->{pkgs} } && $pkg =~ /::/) {
            my $r = rename_module_name($pkg, $mods);
            return $r if $r ne $pkg && exists $gmap->{$r};
        }
    }
    return $pkg;
}

# New name for a "$var"-shaped word inside an export/import qw() list at a
# protocol site.  The variable is a bundle global of the current (renamed)
# package (@EXPORT_OK=qw($x)) or of the imported module (use Pkg qw($x)); the
# resolution delegates to _string_new_name (module-name remap for the
# qualifier included).  Returns undef when the name is not a renameable
# bundle global.
sub _protocol_var_new_name {
    my ($name, $pkg, $st, $gmap, $glex, $mods) = @_;
    my $qual;
    if ($st && $st->statement && $st->statement->isa('PPI::Statement::Include')
        && $st->statement->type eq 'use') {
        my $m = $st->statement->module;
        $qual = $m if defined $m && length $m;
    }
    my $full = defined $qual ? "${qual}::$name" : $name;
    return _string_new_name($pkg, $gmap, $glex, {}, $full, $mods);
}

# Substitute interpolated "$var"/"${var}"/"@var"/"%var" references inside an
# opaque token's text.  Escaped dollars (odd run of backslashes before the
# sigil) stay literal and are preserved.  Returns the rewritten text.
sub _rewrite_string_text {
    my ($src, $pkg, $gmap, $glex, $rename, $mods) = @_;
    my $guard = qr/(?<!\\)(?:\\{2})*\K/;
    my $var   = qr/([\$\@%])(\{?)((?:[A-Za-z_]\w*::)*[A-Za-z_]\w+)(\}?)/;
    # ${ \ $name ... } style deref interpolation (e.g. "${\$spec->{builder}}"):
    # rename the inner variable name, preserving the ${\  form exactly.
    $src =~ s! $guard ([\$\@%])\{\\([\$\@%])([A-Za-z_]\w*) !{
        my ($sig, $isig, $iname) = ($1, $2, $3);
        my $new = _string_new_name($pkg, $gmap, $glex, $rename, $iname, $mods);
        defined $new ? $sig.'{\\'.$isig.$new : $&;
    }!gex;
    $src =~ s{ $guard $var }{
        my ($sig, $op, $full, $cl) = ($1, $2, $3, $4);
        my $new = _string_new_name($pkg, $gmap, $glex, $rename, $full, $mods);
        defined $new && $sig.$op.$new.$cl || $&;
    }gex;
    # Module rename of a fully-qualified global in interpolating text
    # ("$App::Saisons::VERSION" -> "$a::Saisons::VERSION"): the namespace
    # prefix follows the package rename even when the base name is exempt from
    # variable renaming (all-caps, package globals, ...).
    if ($mods && $mods->{pkgs}) {
        my $mvar = qr/([\$\@%])(\{?)((?:[A-Za-z_]\w*::)+[A-Za-z_]\w+)(\}?)/;
        $src =~ s{ $guard $mvar }{
            my ($sig, $op, $full, $cl) = ($1, $2, $3, $4);
            my ($qual, $base) = $full =~ /^(.*)::([^:]+)$/;
            my $rq = defined $qual ? rename_module_name($qual, $mods) : $qual;
            if (defined $rq && $rq ne $qual) {
                my $nb = $base;
                if ($gmap && exists $gmap->{$rq} && $gmap->{$rq}{$base}) {
                    $nb = $gmap->{$rq}{$base};
                }
                $sig . $op . $rq . '::' . $nb . $cl;
            } else {
                $&;
            }
        }gex;
    }
    return $src;
}

sub _rewrite_doc {
    my ($doc) = @_;

    # first_token-style walk that skips (already-collapsed) whitespace tokens
    my $tok = $doc->first_token;
    while ($tok) {
        if (ref($tok) eq 'PPI::Token::Word' && $tok->content eq 'foreach') {
            # foreach after an arrow or brace is a method name / hash key
            # ($o->foreach, ->{foreach}), not the loop keyword, so only rewrite
            # it in any other position.
            my $prev = $tok->previous_token;
            $prev = $prev->previous_token while $prev && $prev->isa('PPI::Token::Whitespace');
            $tok->set_content('for')
                unless $prev && ($prev->content eq '->' || $prev->content eq '{' || $prev->content eq '::');
        } elsif ($tok->isa('PPI::Token::Regexp::Match') && $tok->content =~ /^m\//) {
            my $prev = $tok->previous_token;
            $prev = $prev->previous_token while $prev && $prev->isa('PPI::Token::Whitespace');
            $tok->set_content(substr $tok->content, 1)
                if $prev && $prev->isa('PPI::Token::Operator')
                   && ($prev->content eq '=~' || $prev->content eq '!~');
        } elsif ($tok->isa('PPI::Token::Structure') && $tok->content eq ';') {
            my $next = $tok->next_token;
            $next = $next->next_token while $next && $next->isa('PPI::Token::Whitespace');
            $tok->set_content('') if $next && $next->content eq '}';
        }
        $tok = $tok->next_token;
    }

    for my $stmt (@{ $doc->find('PPI::Statement') || [] }) {
        _rewrite_incdec($stmt);
        _rewrite_opassign($stmt);
        _rewrite_parendrop($stmt);
    }
}

sub _rewrite_incdec {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 4;
    return unless $k[0]->isa('PPI::Token::Symbol') || $k[0]->isa('PPI::Token::ArrayIndex');
    return unless $k[1]->isa('PPI::Token::Operator') && $k[1]->content =~ /^[+-]=$/;
    return unless $k[2]->isa('PPI::Token::Number') && $k[2]->content eq '1';
    return unless $k[3]->isa('PPI::Token::Structure') && $k[3]->content eq ';';
    # `$x += 1` returns the new value but `$x++` the old one, so only rewrite
    # statements that are NOT the last one of their enclosing block: the value
    # of any non-final statement is always discarded (void context).
    my $next = $stmt->next_sibling;
    $next = $next->next_sibling while $next && $next->isa('PPI::Token::Whitespace');
    return unless $next;
    $k[1]->set_content($k[1]->content eq '+=' ? '++' : '--');
    $k[2]->set_content('');
}

sub _rewrite_opassign {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 5 || (@k == 6 && $k[5]->isa('PPI::Token::Structure') && $k[5]->content eq ';');
    return unless $k[0]->isa('PPI::Token::Symbol') || $k[0]->isa('PPI::Token::ArrayIndex');
    return unless $k[1]->isa('PPI::Token::Operator') && $k[1]->content eq '=';
    return unless $k[2]->isa(ref $k[0]) && $k[2]->content eq $k[0]->content;
    return unless $k[3]->isa('PPI::Token::Operator') && $OP_ASSIGN{$k[3]->content};
    # Both `$x = $x OP $y` and `$x OP= $y` return $x OP $y, so the rewrite is
    # value-preserving in any context.  The RHS is restricted (by the @k shape
    # above) to a single token, ruling out precedence surprises.
    $k[1]->set_content($k[3]->content . '=');
    $k[2]->set_content('');
    $k[3]->set_content('');
}

sub _rewrite_parendrop {
    my ($stmt) = @_;
    return unless $stmt->isa('PPI::Statement');
    my @k = grep { !$_->isa('PPI::Token::Whitespace') } $stmt->children;
    return unless @k == 2 || (@k == 3 && $k[2]->isa('PPI::Token::Structure') && $k[2]->content eq ';');
    return unless $k[0]->isa('PPI::Token::Word') && $PAREN_DROP{$k[0]->content};
    return unless $k[1]->isa('PPI::Structure::List');
    # Start/end must be exactly the call's argument list (statement-terminal
    # above), and the first argument must be a plain scalar/array/hash variable
    # so the keyword can never glue onto a literal ('print 1' -> print1).
    my $t = $k[1]->start->next_token;
    while ($t && $t->isa('PPI::Token::Whitespace')) { $t = $t->next_token }
    return unless $t && ($t->isa('PPI::Token::Symbol') || $t->isa('PPI::Token::ArrayIndex'));
    $k[1]->start->set_content(' ');
    $k[1]->finish->set_content('');
    return;
}

sub minify_file {
    my ($path, %opts) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    my $src = do { local $/; <$fh> };
    close $fh;
    # The #! line is a PPI comment, so process() strips it like any other;
    # a minified script must stay runnable, so put it back.
    my ($bang) = $src =~ m{^(\#![^\n]*(?:\n|\z))};
    my $min = process($src, %opts);
    return $bang && $min !~ /^\#/ ? $bang . $min : $min;
}
# Extract the statically-declared module dependencies from Perl source.
# Returns a list of module names found via `use`, `require`, `use base`,
# `use parent`, and string-form `require "Foo/Bar.pm"`.  Pragmas (strict,
# warnings, lib, etc.) are skipped.
# Minify and extract dependencies in a single PPI parse.  Returns
# ($minified, @deps) where the minified string is what process() would return
# and @deps is what module_deps() would return on the same source.  Like
# process(), a source that PPI cannot parse is passed through unchanged and
# yields no dependencies.
sub process_deps {
    my ($src, %opts) = @_;
    my $doc = PPI::Document->new(\$src);
    return ($src) unless $doc;
    my @deps = _deps_from_document($doc);
    my $min = _minify_doc($doc, %opts);
    return ($min, @deps);
}
# Bundle-aware global renaming: given the sources of every module that will
# end up in one bundle, build a package => { old => short } map renaming the
# `our`-declared package globals.  Safe precisely because the whole dependency
# graph is packed together, so "another module might reference $PKG::x" no
# longer applies: every qualified reference in the bundle is rewritten too.
# Returns ($map, $lexicals, $subs_map, $mods) where $lexicals is every my/state
# name seen (used to leave ambiguous unqualified references alone),
# $subs_map is the bundle-wide method-rename map (see global_subs in
# process()), and $mods is the module-rename struct
# ({ map => { component => short }, pkgs => [longest-first package names] })
# renaming namespace components of the bundled packages (rename_module_name).
# An optional trailing hashref selects behaviour: rename_exports => 1 records
# import/export protocol words (use ... qw(), @EXPORT_OK = qw(...), can('x'))
# as eligible for renaming instead of freezing them (see global_subs +
# rename_exports in process()).
sub collect_bundle_globals {
    my @args = @_;
    my %opts;
    if (ref $args[-1] eq 'HASH') { %opts = %{ pop @args } }
    my @sources = @args;
    my (%globals, %lexicals, %in_string, %in_string_word, %subs, %words, %pkgs,
        %data_globs, %xs_pkgs, %mod_in_string);
    for my $src (@sources) {
        next unless defined $src;
        my $doc = PPI::Document->new(\$src) or next;
        _collect_bundle_globals_doc($doc, \%globals, \%lexicals, \%in_string,
                                    \%in_string_word, \%subs, \%words, \%pkgs,
                                    \%data_globs, $opts{rename_exports},
                                    \%mod_in_string);
        $xs_pkgs{$_} = 1 for _xs_packages($doc);
    }
    # An XS module finds its compiled code by package name, so it and every
    # package under it keep their names.
    for my $p (keys %pkgs) {
        delete $pkgs{$p} if grep { $p eq $_ || index($p, "${_}::") == 0 } keys %xs_pkgs;
    }
    my @disallowed = (keys %lexicals, keys %in_string);
    my %disallowed = map { $_ => 1 } @disallowed;
    my %map;
    my $counter = 0;
    for my $pkg (sort keys %globals) {
        for my $name (sort keys %{ $globals{$pkg} }) {
            next unless _var_renameable($name, is_global => 1,
                                        lexicals => \%lexicals,
                                        in_string => \%in_string);
            my $short;
            do { $short = name_gen($counter++) } while $KEEP{$short} || $disallowed{$short};
            $map{$pkg}{$name} = $short;
        }
    }
    # Bundle-wide, name-global sub/method map (see global_subs in process()).
    # One pool of short names shared by every module, reserved away from every
    # word that survives anywhere in the bundle.
    my %subs_map;
    my $scounter = 0;
    for my $name (sort keys %subs) {
        next unless _sub_eligible($name, \%in_string_word);
        next if $data_globs{$name};
        my $short;
        do { $short = name_gen($scounter++) } while _sub_short_taken($short, \%words);
        $subs_map{$name} = $short;
    }
    # Module-rename struct: every namespace component of a declared bundled
    # package — the leaf included, since the bundle is closed and the loader's
    # %INC keys are rewritten with the same component map — gets a short name,
    # reserved away from every surviving word and from the global/sub short
    # names.
    my %modreserved = (%KEEP, %PERL_WORDS, %words, %lexicals, %in_string_word);
    $modreserved{$_} = 1 for map { values %$_ } values %map;
    $modreserved{$_} = 1 for values %subs_map;
    my %modmap;
    my $mcounter = 0;
    for my $p (sort { length $b <=> length $a } keys %pkgs) {
        next unless $p =~ /::/;
        my @pc = split /::/, $p;
        for (@pc) {
            next if defined $modmap{$_};
            # A component of a qualified name mentioned inside a string stays:
            # the string may be eval'd as code (Sub::Defer's q[...] template
            # says `package Sub::Defer;`), and strings are never rewritten to
            # follow module renames.
            next if $mod_in_string{$_};
            my $short;
            do { $short = name_gen($mcounter++) }
                while $KEEP{$short} || $PERL_WORDS{$short} || $modreserved{$short};
            $modmap{$_} = $short;
        }
    }
    my %modinfo;
    if (%modmap) {
        $modinfo{map}  = \%modmap;
        $modinfo{pkgs} = [ sort { length $b <=> length $a } keys %pkgs ];
        # Reverse package mapping (renamed => original).  Full pipeline builds
        # are re-keyed to the renamed names (see bin/slimpack), but direct
        # process() callers keep the original keys, so string/word rewriters
        # need to resolve a already-renamed namespace back to its source.
        my %rev;
        for my $p (keys %pkgs) {
            my $r = rename_module_name($p, \%modinfo);
            $rev{$r} = $p if defined $r && $r ne $p;
        }
        $modinfo{rev} = \%rev if %rev;
    }
    return (\%map, \%lexicals, \%subs_map, \%modinfo);
}

# Single-source half of collect_bundle_globals().  One linear token walk:
# remembers the current package, records `our`/`my`/`state` declarations from
# PPI::Statement::Variable tokens, flags names that appear inside opaque
# (stringy/regex) tokens so nothing embedded in text is ever renamed, records
# `sub` definitions for the bundle-wide method-rename map, and notes every
# bare word in the source so generated short method names never collide with
# anything that survives.
sub _collect_bundle_globals_doc {
    my ($doc, $globals, $lexicals, $in_string, $in_string_word, $subs, $words,
        $pkgs, $data_globs, $rexport, $mod_in_string) = @_;
    my $cur_pkg = 'main';
    my %seen_stmt;
    my $tok = $doc->first_token;
    while ($tok) {
        my $r = ref($tok);
        $words->{$tok->content} = 1 if $r eq 'PPI::Token::Word';
        if ($r eq 'PPI::Token::Word' && $tok->content eq 'package'
            && $tok->statement && $tok->statement->isa('PPI::Statement::Package')) {
            $cur_pkg = $tok->statement->namespace;
            $pkgs->{$cur_pkg} = 1 if defined $cur_pkg && length $cur_pkg;
        } elsif ($r eq 'PPI::Token::Word' && $tok->content =~ /^(?:my|state|our)$/
                 && $tok->statement && !$seen_stmt{$tok->statement}++) {
            my $st = $tok->statement;
            my ($type, @names);
            if ($st->isa('PPI::Statement::Variable')) {
                $type = $st->type;
                for my $v ($st->variables) {
                    my ($sigil, $n) = $v =~ /^([\$\@\%])(.+)$/ or next;
                    push @names, $n if $n !~ /::/;
                }
            } else {
                # Postfix declarations (`return if our $ready`) are classified by
                # PPI as PPI::Statement::Break rather than Variable, so ->variables
                # is unavailable and they were silently never collected.  Grab the
                # first symbol (or parenthesised list) after the keyword only;
                # anything after an operator (`if our $x or $y`) is a read of a
                # package global, not a declaration, and must not be collected.
                $type = $tok->content;
                my $next = $tok->snext_sibling;
                my @syms = $next && $next->isa('PPI::Token::Symbol')
                    ? ($next)
                    : $next && $next->isa('PPI::Structure::List')
                    ? @{ $next->find('PPI::Token::Symbol') // [] }
                    : ();
                for my $sym (@syms) {
                    my ($sigil, $n) = $sym->content =~ /^([\$\@\%])(.+)$/ or next;
                    push @names, $n if $n !~ /::/;
                }
            }
            for my $n (@names) {
                $lexicals->{$n} = 1 if $type eq 'my' || $type eq 'state';
                $globals->{$cur_pkg}{$n} = 1 if $type eq 'our';
            }
        } elsif ($r eq 'PPI::Token::Word' && $tok->content eq 'sub') {
            my $next = $tok->snext_sibling;
            if ($next && $next->isa('PPI::Token::Word')) {
                my $n = $next->content;
                $n =~ s/^.*:://;    # sub Pkg::name -> name (name-global map)
                $subs->{$n} = 1;
            }
        } elsif ($r eq 'PPI::Token::Symbol'
                 && $tok->content =~ /^\*((?:[A-Za-z_]\w*::)*)([A-Za-z_]\w*)$/) {
            # A glob assignment that installs a sub (*alias = \&sub,
            # *CONST = $coderef, *x = sub {...}) defines a sub name like
            # `sub name` does, so record it in the sub map; _apply_renames
            # renames the glob in step with its callers.  A name also used as
            # a data alias (*g = \@arr) anywhere in the bundle is never
            # renamed, since the map is name-global.
            my $kind = _glob_assign_kind($tok) // '';
            $subs->{$2} = 1       if $kind eq 'code';
            $data_globs->{$2} = 1 if $kind eq 'data';
        } elsif ($r eq 'PPI::Token::Regexp::Match'
              || $r eq 'PPI::Token::Regexp::Substitute'
              || $r eq 'PPI::Token::QuoteLike::Regexp') {
            # Regex pattern/replacement TEXT is rewritten in step with the name
            # renames (_rewrite_names_in_regexes), so only names inside opaque
            # code regions ((?{ }), s///e) freeze the variable.  Bare words in
            # pattern text are literals (never rewritable) and still freeze the
            # sub map.
            _regex_exempt_names($in_string, $in_string_word, $r, $tok->content);
            my $pr = _parse_regex($r, $tok->content);
            if ($pr && !$pr->{single}) {
                for my $part (_regex_parts($pr->{pat})) {
                    next unless $part->[0] eq 'text';
                    while ($part->[1] =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word->{$1} = 1 }
                }
                if (defined $pr->{repl} && $pr->{mods} !~ /e/) {
                    while ($pr->{repl} =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word->{$1} = 1 }
                }
            }
        } elsif ($r =~ /^PPI::Token::(?:Quote::(?:Interpolate|Double|Single|Literal)|QuoteLike::(?:Readline|Backtick|Command|Words)|HereDoc)$/) {
            my $str = $tok->content;
            $str .= join('', $tok->heredoc) if $r eq 'PPI::Token::HereDoc' && $tok->can('heredoc');
            # A qualified name in a NON-interpolating string freezes its
            # components in the module map: the string may be eval'd as code
            # (Sub::Defer's q[...] template says `package Sub::Defer;`), and
            # unlike interpolating text these strings are never rewritten to
            # follow module renames.
            if ($mod_in_string
                && ($r eq 'PPI::Token::Quote::Single'
                 || $r eq 'PPI::Token::Quote::Literal'
                 || ($r eq 'PPI::Token::HereDoc'
                     && ($tok->{_mode} || '') !~ /^(?:interpolate|command)$/))) {
                while ($str =~ /\b((?:[A-Za-z_]\w*::)+[A-Za-z_]\w*)\b/g) {
                    $mod_in_string->{$_} = 1 for split /::/, $1;
                }
            }
            # With rename_exports, protocol words AND $-exported variables (use
            # import lists, @EXPORT_OK qw lists, can('x') strings) are renamed
            # in step with the sub/variable they name, so they do not freeze it.
            my $protocol = $rexport
                && ($r =~ /^PPI::Token::Quote::(?:Single|Double|Literal)$/
                 || $r eq 'PPI::Token::QuoteLike::Words')
                && _protocol_site($tok);
            if (!$protocol) {
                while ($str =~ /[\$\@]\{?(\w{2,})\b/g) { $in_string->{$1} = 1 }
                while ($str =~ /\b([A-Za-z_]\w*)\b/g) { $in_string_word->{$1} = 1 }
            }
        }
        $tok = $tok->next_token;
    }
}
# Extract the statically-declared module dependencies from an already-parsed
# PPI document.  Shared by module_deps() and process_deps() so both report the
# same dependency list.
sub _deps_from_document {
    my ($doc) = @_;
    my @deps;
    my $incs = $doc->find('PPI::Statement::Include') || [];
    for my $i (@$incs) {
        my $type = $i->type;
        next unless defined $type && ($type eq 'use' || $type eq 'require');
        my $mod = $i->module;
        if (defined $mod && length $mod) {
            if ($mod eq 'parent' || $mod eq 'base') {
                for my $tok ($i->arguments) {
                    if ($tok->isa('PPI::Token::QuoteLike::Words')) {
                        push @deps, $tok->literal;
                    } elsif ($tok->isa('PPI::Token::Quote')) {
                        my $str = $tok->string;
                        push @deps, $str if defined $str && length $str;
                    }
                }
                next;
            }
            next if $i->pragma;
            push @deps, $mod;
        } elsif ($type eq 'require') {
            for my $tok ($i->schildren) {
                next unless $tok->isa('PPI::Token::Quote')
                         || $tok->isa('PPI::Token::HereDoc');
                my $str = $tok->string // next;
                next unless $str =~ s{\.pm$}{};
                $str =~ s{/}{::}g;
                push @deps, $str if length $str && $str !~ /[\$\@\%\$\{]/;
            }
        }
    }
    return @deps;
}

sub module_deps {
    my ($src) = @_;
    my $doc = PPI::Document->new(\$src) // die "PPI parse failed";
    return _deps_from_document($doc);
}

=head1 NAME

App::SlimPacker::Minify - PPI-based Perl source minifier and bundle-aware renaming engine

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use App::SlimPacker::Minify qw(process minify_file);

    my $min = minify_file('lib/My/Module.pm');     # read a file and minify it
    my $min = process($source);                    # same, from a string

    my $min = process($source, rename_subs => 1);  # also rename subs/methods
    my $min = process($source, rename_vars => 0);  # only strip comments,
                                                   # POD and whitespace

Given

    package My::Greeter;
    use strict;
    use warnings;

    # Build a greeter
    sub new {
        my ($class, %args) = @_;
        return bless {%args}, $class;
    }

    sub greeting_for {
        my ($self, $name) = @_;
        return "Hello, $name!";
    }
    1;

C<< process($source, rename_subs => 1) >> returns

    package My::Greeter;use strict;use warnings;sub new{my($c,%d)=@_;return bless{%d},$c;}sub a{my($e,$f)=@_;return "Hello, $f!";}1;

=head1 DESCRIPTION

A PPI-based minifier for Perl source.  It removes comments, POD and
whitespace and renames C<my> variables to short names.  It can also rename
subs, methods, C<our> globals and package names.

A single file can only be renamed so far: a sub or package name may be used
by other files.  When you minify a whole program at once, as L<slimpack>
does, L</collect_bundle_globals(@sources)> collects names across all files
so they can be renamed consistently.  See L</EXAMPLES>.

L<App::SlimPacker> re-exports all of these functions.

=head1 EXAMPLES

=head2 Minifying several files together

    use Path::Tiny ();
    use App::SlimPacker::Minify
        qw(process collect_bundle_globals rename_module_name rename_module_path);

    my %src = (
        'My/Greeter.pm' => Path::Tiny::path('lib/My/Greeter.pm')->slurp_utf8,
        'main.pl'       => Path::Tiny::path('main.pl')->slurp_utf8,
    );

    my ($globals, $lexicals, $subs, $modules) = collect_bundle_globals(values %src);

    # $globals is keyed by package name, which module renaming changes too
    my %globals = map { rename_module_name($_, $modules) => $globals->{$_} }
        keys %{ $globals };

    for my $file (sort keys %src) {
        my $min = process($src{$file},
            rename_subs     => 1,
            global_rename   => \%globals,
            global_lexicals => $lexicals,
            global_subs     => $subs,
            global_modules  => $modules,
        );
        # package names changed, so the file names must too:
        # My/Greeter.pm -> c/d.pm, main.pl stays main.pl
        my $out = Path::Tiny::path('out', rename_module_path($file, $modules));
        $out->parent->mkpath;
        $out->spew_utf8($min);
    }

With a C<main.pl> of

    use My::Greeter;
    my $greeter = My::Greeter->new;
    print $greeter->greeting_for('world'), "\n";

this writes

    # out/c/d.pm
    package c::d;...sub a{my($e,$f)=@_;return "Hello, $f!";}1;

    # out/main.pl
    use c::d;my$c=c::d->new;print$c->a('world'),"\n";

and C<perl -Iout out/main.pl> still prints C<Hello, world!>.

=head1 FUNCTIONS

=head2 process($source, %options)

Minifies Perl source code using PPI.  Returns the minified string.

Options:

=over 4

=item rename_vars => 0|1

Rename C<my> variables to short names (C<a>, C<b>, ... C<aa>, ...).
Enabled by default.  Set to C<0> to keep variable names intact (useful for
C<fatlib> core modules).  Alias: C<rename>.

=item rewrite => 0|1

Apply an additional, optional pass that rewrites code into shorter equivalent
forms.  Disabled by default.  The rewrites are all value-preserving and built
as a self-contained, removable step so the whole pass can be switched off
(C<rewrite => 0>) or deleted (the C<_rewrite_doc> method and its one call site
in C<_minify_doc>) if it ever causes problems.

Currently: C<foreach> -> C<for>; C<m/.../> -> C</.../> when preceded by
C<=~> or C<!~> (the C<m> is optional with C</> delimiters); trailing C<;>
before a closing C<}> is dropped; a C<$x += 1;> statement in a non-final
position becomes C<$x++;> (and C<->= 1> -> C<-->); C<$x = $x OP $y;> with a
single-token RHS becomes C<$x OP= $y;> for C<. + - * / %>; and
parentheses are dropped from statement-terminal builtin calls that take a
variable argument (C<print($x)>, C<return($y)>, C<push(@a, $x)>).

=item global_rename_vars => \%map

Alias: C<global_rename>.

=item global_rename => \%map

Also rename package globals using a map built by
L</collect_bundle_globals(@sources)>.

=item global_lexicals => \%lexicals

Bundle-wide set of C<my>/C<state> names, used to leave an unqualified
reference untouched when a lexical of the same name exists anywhere in the
bundle.  Returned as the second value of
L</collect_bundle_globals(@sources)>; only meaningful together with
C<global_rename>.

=item rename_subs => 0|1

Rename sub and method names to short names as well.  Off by default here;
L<slimpack> and L<minify> turn it on unless given C<--no-rename-subs>.

=item global_subs => \%subs

Bundle-wide C<< name => short_name >> map for L</rename_subs>, returned as
the third value of L</collect_bundle_globals(@sources)>.  Passing it renames
the subs it lists even without C<rename_subs>.

=item global_modules => \%modinfo

Rename package names (C<My::Greeter> becomes C<c::d>) using the struct
returned as the fourth value of L</collect_bundle_globals(@sources)>.  There
is no separate on/off option: packages are renamed when this is passed.
L<slimpack> passes it unless given C<--no-rename-modules>.

=item rename_exports => 0|1

Extend L</rename_subs> to the export/import protocol.  Off by default.

=back

=head2 process_deps($source, %options)

Minifies and resolves dependencies in a single PPI parse.  Returns
C<< ($minified, @deps) >> where C<$minified> is what L</process($source, %options)> would return
for the same source and C<@deps> is what L</module_deps($source)> would return.  Use it
when both quantities are needed for the same file to avoid parsing it twice;
this is what the bundler does for every reachable module.

=head2 collect_bundle_globals(@sources)

Returns C<< ($map, $lexicals, $subs, $modinfo) >> for bundle-aware renaming.
C<@sources> is the original text of every module that will land in one bundle
(the boot program included).  C<$lexicals> is a hashref of every C<my>/C<state>
name found anywhere in those sources.  C<$map> is
C<< package => { global_name => short_name } >> describing a rename of the
C<our>-declared package globals, sized to fit the longest name in the bundle.
Postfix declarations like C<return if our $flag> are covered too: PPI classifies
them as an ordinary statement (L<PPI::Statement::Break>) rather than a variable
declaration, so they are picked up from the keyword's first symbol instead.
Feed both back into L</process($source, %options)> (and
L</process_deps($source, %options)>) as C<global_rename> / C<global_lexicals>.

Renaming package globals is only safe when the bundle knows its whole
dependency graph: minifying a single file on its own leaves C<our> globals
alone, but every module packed together can agree on one short name.
Referenced from an interpolating string, the quotation is rewritten to match.
C<$VERSION>, C<$AUTOLOAD>, C<@ISA>, ALL_CAPS, control-variable (C<$^...>) and
single-character names are never renamed, and a global is skipped if its name
is a C<my> lexical anywhere in the bundle.  The generated short names avoid
every bundle lexical and reserved name, so an unqualified reference can never
become ambiguous.

C<$subs> is a flat C<< name => short_name >> hash for L</rename_subs>,
collected the same way as L</process($source, %options)> but over all
C<@sources> at once, so cross-module calls keep agreeing on one short name.
Short names avoid every Perl keyword, all C<sub> names seen in C<@sources>,
and every word appearing inside a string-like token (so a runtime string
dispatch can never alias a renamed sub).  Does not renumber: the C<rename_subs>
pass over each module consumes slots from the same C<name_gen> sequence as the
variable pass.  Pass it to L</process($source, %options)> /
L</process_deps($source, %options)> as C<global_subs>.

C<$modinfo> is the module-rename struct for C<global_modules>:
C<< { map => { component => short }, pkgs => [ package names, longest first ] } >>.
Every namespace component of a declared bundled package gets a short name,
the leaf included (the loader's C<%INC> keys are rewritten from the same
map).  Pass it to L</process($source, %options)> /
L</process_deps($source, %options)> as C<global_modules>.

An optional trailing hashref selects behaviour: C<< rename_exports => 1 >>
records import/export protocol words (C<use ... qw()>, C<@EXPORT_OK = qw(...)>,
C<can('x')>) as C<sub>-rename candidates instead of freezing them, matching the
C<rename_exports> option of L</process($source, %options)>.

=head3 rename_module_name($name, $modinfo)

Helper for C<global_modules>: given a Perl-style class name (C<App::Saisons>,
C<App::Saisons::UI::something>) and the C<$modinfo> struct, returns the
renamed form if the name matches one of the declared bundles, the original
text otherwise.

The name matches when it is a declared package, a C<Pkg::...> prefix of one
(a renamed prefix plus an untouched tail, e.g. C<bk::bl::UI::Foo>), or a
strict namespace ancestor of one (C<App::Saisons> given C<App::Saisons::UI>).
A declared package maps every component, the leaf included (see
C<global_modules>); ancestors map every component too and tails keep whatever
came after the matched prefix.

Note C<$modinfo-E<gt>{pkgs}> must be sorted longest-first for correct
matching; L</collect_bundle_globals(@sources)> produces it that way.

=head2 minify_file($path, %options)

Reads the file at C<$path> and runs it through L</process($source, %options)> with the given
options.  Dies if the file cannot be read.  Returns the minified string.

A leading C<#!> shebang line is preserved: C<process> strips it as a comment,
and a minified script must stay runnable.

=head2 module_deps($source)

Returns a list of module names statically declared as dependencies in the given
Perl source.  Extracts modules from C<use>, C<require>, C<use base>,
C<use parent>, and string-form C<require "Foo/Bar.pm">.  Pragmas (C<strict>,
C<warnings>, C<lib>, etc.) are skipped.

=head2 name_gen($n)

Returns a short variable name for the index C<$n>: C<0> -> C<a>, C<1> -> C<b>,
C<25> -> C<z>, C<26> -> C<aa>, etc.

=head2 needs_space($left_token, $right_token)

Returns 1 if a space is needed between two PPI tokens to prevent them from
merging into a single token, 0 otherwise.

=head1 AUTHOR

Nicolas Mendoza, C<< <mendoza at pvv.ntnu.no> >>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the Artistic License 2.0.  See the F<LICENSE>
file in this distribution for the full text.

=head1 SEE ALSO

L<App::SlimPacker>, L<slimpack>, L<PPI>

=cut

1;
