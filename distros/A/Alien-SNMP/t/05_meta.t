use strict;
use warnings;
use Test::More;

# Author/release consistency checks for the hand-synced pairs the packaging
# convention depends on.  Not run for installers.
unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author tests not required for installation';
}

use Alien::SNMP;

# --- Changes top entry version must match the module $VERSION ---
my ($changes_version) = _slurp('Changes') =~ /\A(\S+)/;
is $changes_version, $Alien::SNMP::VERSION,
  'changes__top_entry__matches_module_version';

# --- POD --configure list must match the alienfile's configure flags ---
my %pod_flags       = map { $_ => 1 } _pod_configure_flags('lib/Alien/SNMP.pm');
my %alienfile_flags = map { $_ => 1 } _alienfile_configure_flags('alienfile');

is_deeply \%pod_flags, \%alienfile_flags,
  'configure_flags__pod_and_alienfile__are_in_sync'
  or diag "POD:       @{[ sort keys %pod_flags ]}\n"
        . "alienfile: @{[ sort keys %alienfile_flags ]}";

done_testing;

sub _pod_configure_flags {
    my ($file) = @_;
    return _slurp($file) =~ /^=item C<(--[^>]+)>/mg;
}

sub _alienfile_configure_flags {
    my ($file) = @_;
    # Isolate the quoted configure command element ('%{configure}' ... '%{make}')
    # so prose in comments mentioning %{configure}/--prefix/--with-pic is ignored.
    my ($configure) = _slurp($file) =~ /'%\{configure\}'(.*?)'%\{make\}'/s;
    return () unless defined $configure;
    return $configure =~ /(--[\w-]+(?:="[^"]*")?)/g;
}

sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "can't read $file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}
