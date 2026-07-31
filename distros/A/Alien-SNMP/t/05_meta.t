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

# --- Tracked META.* must match the module $VERSION ---
# MakeMaker regenerates these only inside the dist directory, so a stale copy in
# the repository never shows up in `git status`.  It is not harmless: MYMETA is
# built from META when META is present, so the old version reaches anything
# installing straight from the repository rather than from a release tarball.
SKIP: {
    eval { require CPAN::Meta; 1 }
      or skip 'CPAN::Meta required to read the tracked META files', 2;

    my $distdir = "Alien-SNMP-$Alien::SNMP::VERSION";

    for my $meta_file (qw( META.json META.yml )) {
        # Assigned first: a bare `is CPAN::Meta->...` parses as an indirect
        # object call, CPAN::Meta->is(...).
        my $meta_version = CPAN::Meta->load_file($meta_file)->version;

        is $meta_version, $Alien::SNMP::VERSION,
          "meta__tracked_${meta_file}__matches_module_version"
          or diag "refresh with: make distdir && cp $distdir/META.* . "
                . "&& rm -rf $distdir";
    }
}

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
