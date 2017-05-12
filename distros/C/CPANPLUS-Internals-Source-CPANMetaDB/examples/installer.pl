use strict;
use warnings;
use Module::Load::Conditional qw[check_install];
use CPANPLUS::Configure;
use CPANPLUS::Backend;

$ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

exit 0 unless @ARGV;

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( no_update => '1' );
$conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANMetaDB' );
$conf->set_conf( prereqs => 1 );
$conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' )
  if check_install( module => 'CPANPLUS::Dist::YACSmoke' );
my $cb = CPANPLUS::Backend->new($conf);
foreach my $mod ( @ARGV ) {
  my $module = $cb->parse_module( module => $mod );
  next unless $module;
  $module->install();
}
exit 0;
