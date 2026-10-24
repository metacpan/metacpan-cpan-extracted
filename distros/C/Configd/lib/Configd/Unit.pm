package Configd::Unit;
$Configd::Unit::VERSION = '0.005';
#ABSTRACT: The systemd drop-in that rebuilds a language's files before the daemon reads them.

use 5.034;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use File::Path qw{make_path};

use Configd::Language();


our $DROPIN = '10-configd.conf';


sub new {
    my ( $class, %opts ) = @_;

    die "A Configd::Unit needs a language\n" unless $opts{language};

    $opts{configd} //= '/usr/bin/configd';
    $opts{root}    //= $opts{language}->root() // q{};
    $opts{root} =~ s{/\z}{};

    return bless {%opts}, $class;
}


sub dropin_dir {
    my ( $self, $name ) = @_;
    return "$self->{root}/etc/systemd/system/$name.d";
}


sub render {
    my ($self) = @_;

    my $language = $self->{language}->name();
    my $configd  = $self->{configd};
    my @files    = map { $_->{path} } $self->{language}->files();
    my $list     = join( "\n", map { "#   $_" } @files );

    # A daemon with no reload of its own gets ExecStartPre only: see
    # Configd::Language::reloads.
    my @exec = ("ExecStartPre=+$configd build $language");
    push @exec, "ExecReload=+$configd build $language" if $self->{language}->reloads();

    my $preamble = <<"UNIT";
# Installed by configd.  Removing this file and running `systemctl daemon-reload`
# is all it takes to stop configd having anything to do with this service; the
# files below stay exactly as they were last generated.
#
$list
#
# Each of those is built from the directory of the same name with .d on the end.
# Edit the fragments, not the file: this rebuilds it on every start and reload.

[Service]
UNIT

    return $preamble . join( "\n", @exec ) . "\n";
}


sub install {
    my ($self) = @_;

    my $wanted = $self->render();

    my @written;
    foreach my $name ( $self->{language}->units() ) {
        my $dir  = $self->dropin_dir($name);
        my $path = "$dir/$DROPIN";

        make_path($dir) unless -d $dir;

        my $current = -f $path ? Configd::Language::slurp($path) : undef;    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
        next if defined $current && $current eq $wanted;

        Configd::Language::spew( $path, $wanted );
        push @written, $path;
    }

    return @written;
}


sub uninstall {
    my ($self) = @_;

    my @removed;
    foreach my $name ( $self->{language}->units() ) {
        my $dir  = $self->dropin_dir($name);
        my $path = "$dir/$DROPIN";
        next unless -f $path;    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)

        unlink $path or die "Could not remove $path: $!\n";
        push @removed, $path;

        # An empty .d directory is litter, but one holding somebody else's
        # drop-in is theirs.
        rmdir $dir;
    }

    return @removed;
}


sub installed {
    my ($self) = @_;

    my @units = $self->{language}->units();
    return 0 unless @units;

    foreach my $name (@units) {
        return 0 unless -f $self->dropin_dir($name) . "/$DROPIN";    ## no critic (ValuesAndExpressions::ProhibitFiletest_f)
    }

    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Configd::Unit - The systemd drop-in that rebuilds a language's files before the daemon reads them.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Configd();
    use Configd::Unit();

    my $postfix = Configd->language('postfix');
    my $unit    = Configd::Unit->new( language => $postfix, configd => '/usr/bin/configd' );

    my @written = $unit->install();
    my $wrapped = $unit->installed();

=head1 DESCRIPTION

A generated file is only true until somebody edits it, and the file Configd
generates is the one every piece of documentation on the internet tells people
to edit.  Rather than trying to stop that, Configd regenerates the file at the
moment it matters: a systemd drop-in on the units the language names, running
C<configd build> before the daemon starts and again before it is told to reload.

The daemon therefore always reads what the fragments say, and an edit to the
generated file survives exactly until the next restart -- which is long enough
to test something and short enough that nobody comes to rely on it.

=head2 Why a drop-in rather than a unit of our own

Replacing the packaged unit means owning it: every upgrade that changes it is a
conflict to resolve, and a distribution that reworks how the service starts
breaks a copy that was accurate when it was made.  A drop-in in
C</etc/systemd/system/E<lt>unitE<gt>.d/> adds to whatever the package ships and
keeps working across an upgrade that rewrites it.

=head2 Ordering

C<ExecStartPre> lines in a drop-in are B<appended> to the ones the packaged unit
already has, so ours runs after the package's own pre-start work and still
before C<ExecStart>.  That is the order we want: the package's script sets an
instance up, and we write the config the daemon is about to read.

Prepending would mean clearing the list with an empty C<ExecStartPre=> and
restating every line the package shipped, which is precisely the copy that goes
stale on upgrade.

=head2 Why the commands begin with C<+>

A hardened unit runs C<ExecStartPre> under everything it applies to the daemon
itself, and a modern packaged unit applies a great deal.  Ubuntu 24.04's
C<redis-server.service> is the example that taught us:

    User=redis
    NoExecPaths=/
    ExecPaths=/usr/bin/redis-server /usr/lib /lib
    SystemCallFilter=~@privileged

Under that, C</usr/bin/configd> is not an executable path at all -- systemd
answers C<status=203/EXEC> and, after five tries, leaves redis B<failed>.  Get
past that and the process is the C<redis> user with C<@privileged> syscalls
filtered, so writing into F</etc> and putting the file's ownership back are
C<SIGSYS> rather than C<EPERM>: the helper is killed and core-dumped mid-write.

The C<+> prefix runs the command with full privileges, outside C<User=>, the
namespace restrictions and the seccomp filter.  Regenerating a config file is
exactly the kind of setup step it exists for, and without it adopting a hardened
service takes that service down.

=head1 NAME

Configd::Unit - the systemd drop-in that rebuilds a language's files before the
daemon reads them.

=head1 METHODS

=head2 $class->new(%opts)

=over 4

=item * C<language> -- the L<Configd::Language> whose units these are.  Required.

=item * C<configd> -- the path to the C<configd> executable as the unit will
invoke it.  Defaults to C</usr/bin/configd>; systemd needs it absolute.

=item * C<root> -- write under here rather than C</>, for tests.  Taken from the
language when not given.

=back

=head2 $unit->dropin_dir($unit_name)

Where a unit's drop-ins live.

=head2 $unit->render()

The drop-in's text.

=head2 $unit->install()

Write the drop-in for every unit the language names, returning the paths
written.

=head2 $unit->uninstall()

Take the drop-in back off every unit, returning the paths removed.

The generated files are left where they are, because the service is running on
them.  C<Configd::Language::release> is what puts the originals back.

=head2 $unit->installed()

Whether every unit this language names currently has the drop-in.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Configd|Configd>

=item *

L<Configd::Language>

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
