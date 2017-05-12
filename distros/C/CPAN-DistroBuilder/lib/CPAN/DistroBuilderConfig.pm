package CPAN::DistroBuilderConfig;
use FindBin qw($Bin);

my $root = $Bin;


# The following are the options that we care to be set for the bundle
# grabber to work. We rely on the fact that user should have a working
# version of CPAN already.
#
our $Config = {
  'build_dir' => qq[$root/distro-build],
  'cpan_home' => qq[$root/.cpan],
  'inactivity_timeout' => q[1],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[1],
  'keep_source_where' => qq[$root/.cpan/sources],
  'make_arg' => qq[| tee -ai $root/make.out],
  'prerequisites_policy' => q[follow],
  'scan_cache' => q[never],
};


1;
__END__
