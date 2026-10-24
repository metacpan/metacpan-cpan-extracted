package Configd::Language;
$Configd::Language::VERSION = '0.005';
#ABSTRACT: Base class for the languages: how one config file format is read, merged and written back.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use File::Basename ();
use File::Path     qw{make_path};
use File::Temp     ();


sub slurp {
    my ($path) = @_;
    open( my $fh, '<:encoding(UTF-8)', $path ) or die "Could not read $path: $!\n";
    local $/ = undef;
    my $text = <$fh>;
    close $fh;
    return $text // q{};
}

sub spew {
    my ( $path, $text, $mode, $owner ) = @_;

    my @was = stat $path;

    # fileparse gives back (name, directory, suffix); it is the directory we
    # want, so that the rename below is within one filesystem and therefore
    # atomic.
    my ( undef, $dir )  = File::Basename::fileparse($path);
    my ( $fh,   $temp ) = File::Temp::tempfile( '.configd-XXXXXX', DIR => $dir );

    binmode( $fh, ':encoding(UTF-8)' );
    print {$fh} $text or die "Could not write $temp: $!\n";
    close $fh         or die "Could not write $temp: $!\n";

    rename( $temp, $path ) or do {
        my $error = $!;
        unlink $temp;
        die "Could not put $temp in place as $path: $error\n";
    };

    chmod( ( @was ? $was[2] & 0o7777 : $mode // 0o644 ), $path );

    # Only root can give a file away, and only root should try.  Under a unit
    # with SystemCallFilter=~@privileged a chown that cannot succeed is not
    # EPERM, it is SIGSYS: the process is killed and core-dumped part way
    # through writing a config file.  The drop-in asks for privilege with a `+`
    # so that this is root in practice, and this is the belt for that braces --
    # configd should not be a landmine under anybody else's ExecStartPre.
    return $path if $> != 0;

    if (@was) {
        chown( $was[4], $was[5], $path ) if $was[4] != $> || $was[5] != $);
    }
    elsif ( defined $owner ) {
        my ( $user, $group ) = split( q{:}, $owner );
        my $uid = defined $user  && length $user  ? getpwnam($user)  : undef;
        my $gid = defined $group && length $group ? getgrnam($group) : undef;

        # An account that is not there is not an error: the file is being built
        # somewhere the service is not installed, which is what --root is for.
        chown( $uid // -1, $gid // -1, $path );
    }

    return $path;
}


sub files {
    return ();
}


sub units {
    return ();
}


sub reloads {
    return 1;
}


sub services {
    my ($self) = @_;
    return $self->units();
}


sub parse {
    my ($self) = @_;
    die( ( ref $self || $self ) . " does not know how to parse anything\n" );
}


sub emit {
    my ($self) = @_;
    die( ( ref $self || $self ) . " does not know how to write anything\n" );
}


sub accumulates {
    return 0;
}


sub repeats {
    return 0;
}


sub separator {
    return ', ';
}


sub items {
    my ( $self, $key, $value ) = @_;
    return () unless defined $value;

    my $punctuation = $self->separator($key) =~ s/\s+//gr;
    my @items       = (q{});
    my $depth       = 0;
    foreach my $char ( split m//, $value ) {
        if ( !$depth && ( $char =~ m/\s/ || index( $punctuation, $char ) >= 0 ) ) {
            push @items, q{} if length $items[-1];
            next;
        }
        $depth++ if $char eq '{';
        $depth-- if $char eq '}' && $depth;
        $items[-1] .= $char;
    }
    return grep { length } @items;
}


sub combine {
    my ( $self, $key, @items ) = @_;
    return @items;
}


sub new {
    my ( $class, %opts ) = @_;
    $opts{root} //= q{};
    $opts{root} =~ s{/\z}{};
    return bless {%opts}, $class;
}


sub name {
    my ($self) = @_;
    my $class = ref $self || $self;
    return ( split( q{::}, $class ) )[-1];
}


sub root {
    my ($self) = @_;
    return $self->{root};
}


sub path {
    my ( $self, $path ) = @_;
    return $self->{root} . $path;
}


sub fragment_dir {
    my ( $self, $file ) = @_;
    return $self->path( $file->{path} ) . '.d';
}


sub fragments {
    my ( $self, $file ) = @_;

    my $dir = $self->fragment_dir($file);
    opendir( my $dh, $dir ) or return ();
    my @names = sort grep { !m/\A[.]/ && !m/(?:[.](?:disabled|bak|dpkg-old|dpkg-new|dpkg-dist|rpmsave|rpmnew)|~)\z/ } readdir($dh);
    closedir $dh;

    return map { "$dir/$_" } grep { -f "$dir/$_" } @names;    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
}


sub merge {
    my ( $self, @sets ) = @_;

    my ( @order, %by_key );
    foreach my $set (@sets) {
        foreach my $directive (@$set) {
            my $key = $directive->{key};

            # Comments and blank lines.  Deliberately dropped rather than
            # collected: see the POD above.  A comment is anchored to the
            # setting under it, and once several fragments have had their say
            # there is no longer a setting for it to be anchored to.
            next if !defined $key;

            # A repeatable directive is identified by everything it says, so
            # two different `save` lines are two settings and two identical ones
            # are one.
            $key = "$key\0$directive->{value}"
              if !$self->accumulates($key) && $self->repeats($key);

            if ( !exists $by_key{$key} ) {
                push @order, $key;
                $by_key{$key} = {%$directive};
                next;
            }

            if ( $self->accumulates($key) ) {

                # An empty value resets rather than adding nothing, which is the
                # one thing accumulation otherwise cannot express: a fragment can
                # add to what came before it and never take anything out.  That
                # matters where 00-original is wrong rather than merely
                # incomplete -- a guest whose hostname is the domain it hosts has
                # the package's own mydestination naming a domain that must be a
                # virtual mailbox domain instead, and no amount of adding fixes
                # it.  systemd drop-ins spell the same thing the same way, and
                # for these parameters an empty value is what postfix reads it
                # as anyway.
                if ( !length( $directive->{value} // q{} ) ) {
                    $by_key{$key} = {%$directive};
                    next;
                }

                my %seen;
                my @items = grep { !$seen{$_}++ } map { $self->items( $key, $_ ) } $by_key{$key}{value}, $directive->{value};
                $by_key{$key}{value} = join( $self->separator($key), $self->combine( $key, @items ) );
                next;
            }

            # The later fragment is the one that meant it.
            $by_key{$key} = {%$directive};
        }
    }

    return [ map { $by_key{$_} } @order ];
}


sub build {
    my ( $self, $file ) = @_;

    my @sets;
    foreach my $fragment ( $self->fragments($file) ) {
        push @sets, $self->parse( slurp($fragment) );
    }

    return $self->emit( $self->merge(@sets) );
}


sub header {
    my ( $self, $file ) = @_;

    my $dir = $file->{path} . '.d';
    return <<"HEADER";
# Generated by configd.  Do not edit: this file is rebuilt from
# $dir every time the service starts or reloads,
# and anything you change here will be gone the next time that happens.
#
# Add a file to that directory instead, in this file's own syntax.  They are
# read in order by name, and later ones win.  What was here when configd
# adopted this file is 00-original, comments and all -- those stay in the
# fragments rather than being merged into this file, where they could only
# describe settings something later has since changed.
HEADER
}


sub write {
    my ( $self, $file ) = @_;

    my $target = $self->path( $file->{path} );
    my $wanted = $self->header($file) . $self->build($file);

    my $current = -e $target ? slurp($target) : undef;
    return 0 if defined $current && $current eq $wanted;

    # spew keeps whatever the file already was: postfix's master.cf is 0600 on a
    # mail server set up properly, and handing that back to 0644 while "just
    # regenerating a file" is not something anybody would go looking for.
    spew( $target, $wanted, $file->{mode}, $file->{owner} );

    return 1;
}


sub adopt {
    my ($self) = @_;

    my @adopted;
    foreach my $file ( $self->files() ) {
        my $target   = $self->path( $file->{path} );
        my $dir      = $self->fragment_dir($file);
        my $original = "$dir/00-original";

        unless ( -d $dir ) {
            make_path($dir);

            # No more permissive than the directory the config file lives in:
            # the fragments are the configuration now, and a 0755 directory
            # beside a 0700 one hands them to anybody.
            my ( undef, $parent ) = File::Basename::fileparse($target);
            my @stat = stat $parent;
            chmod( $stat[2] & 0o7777, $dir ) if @stat;
        }

        # Already ours.  Re-adopting would take the file we generated last time
        # and make it the first fragment, which duplicates every setting in it.
        if ( -f $original ) {    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
            $self->write($file);
            next;
        }

        # 00-original is a copy of the file, so it is as secret as the file.
        # Letting spew fall through to 0644 published redis.conf's requirepass,
        # and opendkim.conf's key locations, to every local user on any distro
        # whose /etc/<package> can be traversed.
        my @was = stat $target;
        if (@was) {
            spew( $original, slurp($target), $was[2] & 0o7777 );
            chown( $was[4], $was[5], $original ) if $> == 0;
        }
        else {
            spew( $original, q{}, $file->{mode} );
        }

        $self->write($file);
        push @adopted, $file->{path};
    }

    return @adopted;
}


sub release {
    my ($self) = @_;

    my @released;
    foreach my $file ( $self->files() ) {
        my $original = $self->fragment_dir($file) . '/00-original';
        next unless -f $original;    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)

        spew( $self->path( $file->{path} ), slurp($original) );
        push @released, $file->{path};
    }

    return @released;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Language - Base class for the languages: how one config file format is read, merged and written back.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package Configd::Language::example;

    use parent qw{Configd::Language};

    sub files { return ( { path => '/etc/example.conf', mode => 0o644 } ) }
    sub units { return ('example.service') }

    sub parse {
        my ( $self, $text ) = @_;
        return [ map { m/(\w+)=(.*)/ ? { key => $1, value => $2 } : { text => $_ } }
              split( qq{\n}, $text ) ];
    }

    sub emit {
        my ( $self, $directives ) = @_;
        return join( qq{\n}, map { defined $_->{key} ? "$_->{key}=$_->{value}" : $_->{text} } @$directives );
    }

    sub accumulates { my ( $self, $key ) = @_; return $key eq 'domains' }

=head1 DESCRIPTION

Plenty of software has no C<conf.d>.  Its configuration is one file, and
anything wanting to add to it has to edit that file -- which works exactly once.
The second thing to try it either overwrites what the first did or appends a
duplicate, and neither is what anybody wanted.  Provisioning two domains onto
one mail server is the case that keeps coming up: both want to be in
C<mydestination>, and C<postconf -e> only knows how to set it.

Configd gives that software a C<conf.d> anyway.  For each file it manages there
is a directory beside it -- C</etc/postfix/main.cf> gets C</etc/postfix/main.cf.d>
-- holding fragments in the file's own syntax.  The file itself becomes
B<generated output>: Configd reads every fragment in order, merges them, and
writes the result.  Nothing edits the file any more, and two things adding to it
no longer have to know about each other.

A B<language> is one config file format, and what it has to know is how to read
that format, how two fragments of it combine, and how to write it back.

=head2 Before you write a language: check there is not one already

B<Do not adopt a file whose software can already read a directory.>  A native
C<conf.d> is better than anything here by every measure -- the daemon reads the
fragments itself, there is no generated file to be edited by mistake, no drop-in
to go wrong on a hardened unit, and nothing to go stale if configd is removed.
Configd exists for the software that has no such thing, and using it where a
real mechanism exists trades a working feature for a moving part.

The check is quick, and the answers here were all surprising in one direction or
the other, so make it rather than assuming:

=over 4

=item * Is there a directory the daemon reads? C<ls /etc/E<lt>thingE<gt>/conf.d>,
and then whether the config actually names it.  chrony ships
F</etc/chrony/conf.d> and reads it only if C<chrony.conf> says C<confdir>.  A
directory that exists and is never read looks exactly like one that works.

=item * Is there an include directive, and B<does it take a glob or a
directory?>  A single-file include is not a C<conf.d>: adding a fragment still
means editing the main file, which is the thing we are trying to stop.  redis's
C<include> is a fatal error on a glob.  opendkim's C<Include> reads one file,
refuses a glob, and B<silently ignores a directory> -- it exits zero having read
nothing at all, so testing that it "worked" proves nothing unless the file you
point it at contains something it would reject.

=back

What the four here answered:

    postfix     nothing at all                                     -> ours
    opendmarc   Include is not a directive it knows                -> ours
    redis       include of one file; a glob is a fatal error       -> ours
    opendkim    Include of one file; glob refused, directory ignored -> ours
    chrony      confdir, shipped and supported since 4.0           -> NOT ours

chrony had a language here and lost it.  The fleet's own template was
overwriting the vendor's C<confdir> line out of the file, which left a conf.d
that looked like it worked and did nothing; putting the line back was one line
of template against a language, a drop-in and three bugs.

=head2 How it is kept honest

A generated file that anything else can edit will be edited, and the edit will
be lost the next time it is generated.  So the file is generated at the moment
the service reads it: Configd installs a systemd drop-in on the units the
language names, rebuilding the file before the daemon starts and again before it
is reloaded.  Whatever is in the fragments is what the running service has.

=head2 The first fragment is what was already there

Adopting a file moves it into its own fragment directory as C<00-original>
before anything else is written.  The distribution's defaults, and whatever the
administrator had done to it, become the first fragment and keep winning
wherever nothing later has an opinion.  That is also what makes adoption
reversible: put C<00-original> back and remove the drop-in.

=head1 NAME

Configd::Language - base class for the languages: how one config file format is
read, merged and written back.

=head1 READING AND WRITING

Done with core Perl rather than the usual conveniences.  This runs from
C<ExecStartPre>, so it stands between a service and starting: a dependency that
has to be installed first is a service that does not come up on a fresh guest.

For the same reason this distribution asks for perl 5.34 rather than the 5.41
the rest of the fleet is written against.  The perl that runs it is whichever one
the guest already has -- Ubuntu 24.04 ships 5.38, 22.04 ships 5.34 -- and a
config generator that needs a newer perl installed before it can generate a
config is no use on the machines that most need it.  5.34 is what C<0oNNN> octal
literals want; nothing here needs more than that.

=head2 slurp($path)

The whole of a file, decoded as UTF-8, or an exception naming what could not be
read.

=head2 spew($path, $text, $mode, $owner)

Writes through a temporary file in the same directory and renames over
the target, so a daemon reading at that moment gets the old file or the new one
and never half of either.

A file that was already there keeps the mode and ownership it had.  A new one is
created C<$mode>, or 0644, and owned by C<$owner> -- C<"user:group"> -- if one is
given and the account exists.

C<$owner> matters more than it looks.  A service that runs as its own user and
owns its own config, as opendkim and opendmarc both do, cannot read that config
if it is recreated as root: it does not fail to load a setting, it fails to
start.  This belongs here rather than in the callers because
C<File::Temp> makes its file 0600 and the rename carries that onto the target --
so every path that writes a config file would otherwise have to remember to put
the permissions back, and the one that forgot was C<release>, which handed a
0644 main.cf back as 0600.

=head1 METHODS TO OVERRIDE

=head2 files()

The files this language manages, as a list of hashrefs:

    { path => '/etc/postfix/main.cf', owner => 'root:root', mode => 0644 }

C<path> is the generated file; its fragment directory is C<path> with C<.d>
appended.  C<mode> and C<owner> are what a generated file is created as when there was
nothing there before; C<owner> is C<"user:group">.  A file that already exists
keeps the mode and ownership it had, so adopting one never changes either.

Give C<owner> whenever the service runs as its own user and owns its config.
Recreated as root, such a file does not lose a setting -- the daemon cannot read
it at all, and does not start.

=head2 units()

The systemd units to install the drop-in on, as a list of names.

A templated unit is named with the C<@> and no instance -- C<postfix@.service>
-- so that the drop-in applies to every instance of it.

=head2 reloads()

Whether C<systemctl reload> on this service actually makes the daemon re-read
its configuration.

True by default, which is right for most things.  Say false when the daemon has
no reload of its own: chronyd has none, so the packaged unit has no
C<ExecReload>, and adding one makes C<systemctl reload chrony> B<start
succeeding> while the running daemon carries on with the configuration it
started with.  A command that reports success and does nothing is worse than one
that fails.

Where this is false the drop-in installs C<ExecStartPre> only, and a
configuration change wants a restart.

=head2 services()

The units to actually restart once the drop-in is in place.

Usually the same ones, which is the default.  They come apart when the drop-in
belongs on a template: C<systemctl try-restart postfix@.service> is refused,
because a template is not a thing that runs --

    Unit name postfix@.service is missing the instance name.

-- so the drop-in goes on the template and the restart goes to whatever unit
actually has a process behind it.

=head2 parse($text)

The directives in a fragment, as an arrayref, in the order they were written.

Each directive is a hashref.  What is in it is the language's business, but two
keys are common to all of them because C<merge> reads them:

=over 4

=item * C<key> -- what makes two directives the same directive.  Two with the
same key are the same setting said twice, and the later one wins unless the
language says otherwise.  A directive with no key is never merged with anything
and is kept in the order it arrived, which is what comments and blank lines are.

=item * C<value> -- what C<key> was set to.

=back

=head2 emit($directives)

The text of a config file holding those directives, ready to write.

=head2 accumulates($key)

Whether a directive is a list that fragments add to, rather than a value that a
later fragment replaces.

False by default, which is the right answer for most settings: two fragments
setting C<myhostname> disagree, and the later one wins.  It is the wrong answer
for the ones that are lists -- C<mydestination>, C<virtual_mailbox_domains> --
where two fragments each naming a domain both meant it, and replacing loses one
of them.  That distinction is the whole reason this exists.

=head2 repeats($key)

Whether a directive may appear more than once, each occurrence meaning something
of its own.

False by default.  Redis takes C<save 900 1> and C<save 300 10> and means both;
chrony takes a C<server> line per time source.  Neither is a value a later
fragment replaces, and neither is a list to join with commas -- they are separate
lines that all have to survive.

Two occurrences that say exactly the same thing still collapse into one, which
is what makes a fragment safe to write without checking whether somebody else
already asked for it.

A key cannot both accumulate and repeat; C<accumulates> is checked first.

=head2 separator($key)

What joins the parts of an accumulating directive.  A comma and a space by
default, which is what postfix uses; whitespace-separated languages override it.

=head2 @items = $language->items($key, $value)

The items of the value of an accumulating directive, in order.  They are
separated by whitespace and by the punctuation of C<separator>, so a value
written over several lines, or with a trailing comma as postfix's own
C<mydestination> has, gives no empty item.  A separator inside braces does not
split, because postfix reads C<{ ... }> as one item, as in an C<inline:> table.

=head2 @items = $language->combine($key, @items)

The items that an accumulating directive ends with, after the merge has
dropped the repeats.  C<@items> as they are by default.  A language overrides
this for a parameter whose items are not a plain set, such as C<all> in the
C<inet_interfaces> of postfix.

=head1 METHODS

=head2 $class->new(%opts)

C<root> relocates every path this language touches, so a test -- or a build for
a guest that is not this machine -- works against a directory rather than the
running system's C</etc>.

=head2 $language->name()

What this language is called on the command line: the last component of the
package name.

=head2 $language->root()

The directory every path this language touches is relocated under, or the empty
string for the running system.

=head2 $language->path($path)

C<$path> under this language's C<root>.  Every path in this class goes through
it, so that nothing writes outside the root it was given.

=head2 $language->fragment_dir($file)

The directory a file's fragments live in: the file's own path with C<.d> on the
end.

=head2 $language->fragments($file)

The fragment files for one managed file, in the order they are merged.

Sorted by name, so the numeric prefixes everybody already writes on C<conf.d>
entries do what they look like they do.  Names starting with a dot are skipped,
and so is anything ending in C<~>, C<.disabled>, C<.bak>, or one of the suffixes
dpkg and rpm leave behind -- C<.dpkg-old>, C<.dpkg-new>, C<.dpkg-dist>,
C<.rpmsave>, C<.rpmnew>.  Editors and package managers leave those lying about,
and a stray backup silently taking part in the merge is a bad afternoon.

=head2 $language->merge(@fragment_sets)

One list of directives out of several, applying C<accumulates> to decide which
of two directives for the same key wins and which of them join up.

An accumulating directive joins as a list of items, not as two strings.  Each
value is split into its items with C<items>, an item that the list already
holds is dropped, and C<combine> has the last word.  So a fragment that
repeats what C<00-original> says changes nothing, which is what it meant, and
does not make C<inet_interfaces = all, all>, which postfix refuses.

An accumulating directive with an B<empty value> resets it: whatever earlier
fragments put there is dropped, and anything after this adds to nothing rather
than to that.  It is the one thing accumulation cannot otherwise say, since a
fragment can add to what came before it and never take something out -- and
C<00-original> is sometimes wrong rather than merely incomplete.  A guest whose
hostname is a domain it hosts is the case that keeps coming up: the package's
own C<mydestination> names that domain, the domain has to be a virtual mailbox
domain instead, postfix will not have it in both, and no amount of adding fixes
it.

    mydestination =
    mydestination = $myhostname, localhost

systemd drop-ins spell it the same way, for the same reason.

Order is the order the keys were first seen, so a generated file reads like the
fragments that made it rather than like a hash.

Comments and blank lines are B<not> carried through.  A merged file cannot say
where a comment belongs -- the distribution's paragraph explaining a default sits
above a setting some later fragment has since replaced, and reproducing it there
tells the reader something that is no longer true.  They stay in the fragment
they were written in, which is where somebody editing will be looking, and
C<00-original> keeps every one the file arrived with.

=head2 $language->build($file)

Read every fragment for one file, merge them, and return the text to write.

=head2 $language->header($file)

The comment Configd puts at the top of a file it generates, saying so.

Somebody is going to edit the generated file -- it is where the settings are,
and it is where every piece of documentation on the internet says they live.
This is the one chance to tell them their edit will not survive the next restart
and where to put it instead.

=head2 $language->write($file)

Generate one file and put it in place, returning true if what is on disk
changed.

Written through a temporary file in the same directory and renamed over the
target, so that a service reading it at that moment sees the old file or the
new one and never half of either.

=head2 $language->adopt()

Take over every file this language manages: make each one's fragment directory,
move what is there now into it as C<00-original>, and generate the file.

Does nothing to a file it has already adopted, so running it twice is safe.

=head2 $language->release()

Give a file back: put C<00-original> where it came from and forget about it.

The counterpart to C<adopt>, and the reason C<00-original> is kept rather than
merged away.  Removing the drop-in is L<Configd::Unit>'s half of it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Unit>, L<Configd::Language::postfix>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-configd/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
