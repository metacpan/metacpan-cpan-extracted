use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The reference's index lists every module, A to Z, and what callers use
# from each, A to Z, a heading each, as Ekorn's does (roadmap 2026-0039).
# This keeps it in step with the code: each module has an entry; each
# name a public module exports, and each public method it defines, is
# listed, but for those named internal below; each name listed is one
# the module can call; each has a synopsis, says "Exported by default."
# or "Exported on request." as it's exported, and ends with a link to a
# section of the reference, which doesn't open with the synopsis again
# (2026-0042); Tooling names each of its tags; and an internal module
# lists nothing.
# An author test, as the reference isn't in the distribution.

use B          qw();
use File::Find qw();

my $REFERENCE = 'docs/REFERENCE.md';
skip_all "the reference isn't here" unless -e $REFERENCE;

# Modules for DBIx::Squirrel's own use: their entries list nothing.
my %INTERNAL_MODULE = map { $_ => 1 } qw(
    DBIx::Squirrel::Placeholders
    DBIx::Squirrel::Util
);

# Functions and methods of public modules that are for the modules' own
# use, as the reference says, so not listed.
my %INTERNAL = (
    'DBIx::Squirrel::Context' => [qw(statement_context within)],
    'DBIx::Squirrel::Errors'  => [qw(at_caller failed in_method)],
    'DBIx::Squirrel::Result'  => [qw(class_for)],
);


# Return the key a name sorts by: in any case, with one starting with a
# symbol last.
sub sort_key ($name) {
    my $key = lc $name;
    $key = "\x{ffff}$key" if $key =~ s( \A [^a-z0-9:]+ )()x;
    return $key;
}


# Return a heading's anchor, as GitHub makes it.
sub anchor ($heading) {
    my $anchor = lc $heading;
    $anchor =~ s( [^\w\-\ ] )()xg;
    $anchor =~ s( \  )(-)xg;
    return $anchor;
}


# Return the anchors of the reference's headings before the index, each
# true if its section opens with a synopsis, and the index's entries, in
# order: each a module's name, the text saying what it is, and its
# names, in order, each with its text.
sub index_entries () {
    open my $in, '<', $REFERENCE or die "Can't read $REFERENCE: $!";
    my $text = do { local $/; <$in> };
    close $in;
    my($body, $index) = $text =~ m( \A (.*?) ^\#\#\ Index\n (.*) \z )xms
        or die "No index in $REFERENCE";
    my @lines = split m( \n )x, $body;
    my(%anchors, $in_code);
    for my $i (0 .. $#lines) {
        $in_code = !$in_code if $lines[$i] =~ m( \A ``` )x;
        next if $in_code || $lines[$i] !~ m( \A \#+ \  (.+) \z )x;    # a comment in code isn't a heading
        my $anchor = anchor($1);
        next if exists $anchors{$anchor};
        my($next) = grep { $lines[$_] =~ m( \S )x } $i + 1 .. $#lines;
        $anchors{$anchor} = $lines[$next // $i] =~ m( \A <!--\ not\ run\ --> )x ? 1 : 0;
    }
    my @entries;
    for my $block (split m( (?= ^\#\#\#\  ) )xm, $index) {
        my($module, $about, $rest)
            = $block =~ m( \A \#\#\#\ (\S+) \n (.*?) (?: ^ (\#\#\#\#\ .*) | \z ) )xms
            or next;
        my @names = map { [m( \A \#\#\#\#\ (\S+) \n (.*) \z )xs] }
            split m( (?= ^\#\#\#\#\  ) )xm, $rest // '';
        push @entries, {module => $module, about => $about, names => \@names};
    }
    return \%anchors, @entries;
}


# Return the module each file under lib is: .pm and .pod alike.
sub modules () {
    my @files;
    File::Find::find(
        sub { push @files, $File::Find::name if m( \. (?: pm | pod ) \z )x },
        'lib',
    );
    return sort map { s( \A lib/ | \. \w+ \z )()xgr =~ s( / )(::)xgr } @files;
}


# Return a module's public names: what it exports, and the subs it
# defines, but for import and those starting with _.
sub public_names ($module) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my %names = map { $_ => 1 } @{ "${module}::EXPORT" },
        @{ "${module}::EXPORT_OK" };
    for my $name (keys %{ "${module}::" }) {
        my $code = *{ "${module}::$name" }{CODE} or next;
        next if $name eq 'import' || $name =~ m( \A _ )x;
        $names{$name} = 1
            if B::svref_2object($code)->GV->STASH->NAME eq $module;
    }
    delete @names{@{ $INTERNAL{$module} // [] }};
    return sort keys %names;
}


my($anchors, @entries) = index_entries();
my @modules = modules();

is [map { $_->{module} } @entries],
    [sort { sort_key($a) cmp sort_key($b) } @modules],
    'each module has an entry, A to Z';

for my $entry (@entries) {
    my $module = $entry->{module};
    my @names  = map { $_->[0] } @{ $entry->{names} };
    is \@names, [sort { sort_key($a) cmp sort_key($b) } @names],
        "$module: its names A to Z";
    is [
        map  { $_->[0] }
        grep { $_->[1] !~ m( \s See \s+ \[ [^\]]+ \] \( \#[^\)]+ \) \. \s* \z )xs }
            @{ $entry->{names} }
        ],
        [], "$module: each name ends with a link to where it's described";

    # Its synopsis, all its forms, as code, is here; its link goes to a
    # section of the reference text that shows it in use, which doesn't
    # repeat the synopsis (2026-0042).
    is [
        map  { $_->[0] }
        grep { $_->[1] !~ m( ^```perl\n .+? ^```$ )xms } @{ $entry->{names} }
        ],
        [], "$module: each name has a synopsis";
    my %to = map {
        my($to)
            = $_->[1] =~ m( \s See \s+ \[ [^\]]+ \] \( \# ([^\)]+) \) \. \s* \z )xs;
        ($_->[0] => $to)
    } @{ $entry->{names} };
    is [grep { !defined $to{$_} || !exists $anchors->{$to{$_}} } sort keys %to],
        [], "$module: each name links to a section of the reference";
    is [grep { defined $to{$_} && $anchors->{$to{$_}} } sort keys %to],
        [], "$module: no section it links to opens with a synopsis";
}

for my $entry (@entries) {
    my($module, $about) = @$entry{qw(module about)};
    my %listed = map { $_->[0] => $_->[1] } @{ $entry->{names} };
    if ($module =~ m( ::Manual:: )x || $INTERNAL_MODULE{$module}) {
        is [sort keys %listed], [], "$module: lists nothing";
        next;
    }
    (my $file = "$module.pm") =~ s( :: )(/)xg;
    require $file;
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # Tooling lists no names, but says what its tags are.
    if ($module eq 'DBIx::Squirrel::Tooling') {
        is [sort keys %listed], [], "$module: lists no names";
        my @tags = sort keys %{ "${module}::EXPORT_TAGS" };
        is [grep { $about !~ m( `:\Q$_\E` )x } @tags], [], "$module: names each tag";
        next;
    }

    is [grep { !$listed{$_} } public_names($module)], [],
        "$module: lists every public name";
    is [grep { !$module->can($_) } sort keys %listed], [],
        "$module: lists only names it has";

    # An exported name it lists says how; a name exported by default is
    # so on request too.
    my %default = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT" };
    my %request = map { $_ => 1 } grep { $listed{$_} } @{ "${module}::EXPORT_OK" };
    is [
        grep { $listed{$_} !~ m( \s Exported \s+ by \s+ default \. )x }
        sort keys %default
        ],
        [],
        "$module: says which are exported by default";
    my @on_request = grep { !$default{$_} } sort keys %request;
    is [grep { $listed{$_} !~ m( \s Exported \s+ on \s+ request \. )x }
            @on_request], [],
        "$module: says which are exported on request";
}

done_testing;
