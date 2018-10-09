use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

# Make sure the prereqs from a previous module don't prevent newer prereqs
my $pwd = cwd;

my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

my $libpath = "$FindBin::Bin/../test_dists/PrereqProgress/";
my $dep     = 'NoDeps';
my $dep1    = "file://$libpath/NoDeps1/NoDeps-1.0.tar.gz";
my $dep2    = "file://$libpath/NoDeps2/NoDeps-2.0.tar.gz";
my $lib     = "$libpath/ReqNoDeps2/ReqNoDeps2-0.1.tar.gz";

my @dep_sources = ( $dep1, $dep2 );
my $options = {};

{
  no strict 'refs';
  no warnings 'redefine';
  my $_search_metacpan = \&App::MechaCPAN::Install::_search_metacpan;
  local *App::MechaCPAN::Install::_search_metacpan = sub
  {
    my $src_name = shift;
    if ( $src_name eq $dep )
    {
      return {
        version      => 3 - scalar(@dep_sources),
        download_url => shift(@dep_sources),
      };
    }
    return $_search_metacpan->( $src_name, @_ );
  };

  is( App::MechaCPAN::Install->go( $options, $dep, $lib ), 0, 'Can run successfully' );
}
is( cwd, $dir, 'Returned to whence it started' );

ok( -e "$dir/local/lib/perl5/$dep.pm",       "Library file $dep exists" );
ok( -e "$dir/local/lib/perl5/ReqNoDeps2.pm", "Library file ReqNoDeps2 exists" );

require_ok("$dir/local/lib/perl5/$dep.pm");
is( $NoDeps::VERSION, '2.0', "The correct version was installed" );

chdir $pwd;
done_testing;
