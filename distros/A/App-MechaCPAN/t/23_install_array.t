use strict;
use FindBin;
use Test::More;
use Config;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

my $pwd  = cwd;
my %pkgs = (
  'Try::Tiny'  => 'Try/Tiny.pm',
  'Test::More' => 'Test/More.pm',
);

chdir $pwd;
my $tmpdir = tempdir( TEMPLATE => File::Spec->tmpdir . "/mechacpan_t_XXXXXXXX", CLEANUP => 1 );
chdir $tmpdir;
my $dir = cwd;

local $Module::CoreList::version{$]}{'Test::More'} = 0
    if $] >= 5.028000;

is(
  App::MechaCPAN::Install->go( {}, keys %pkgs ), 0,
  "Can install from an array"
);
is( cwd, $dir, 'Returned to whence it started' );

foreach my $file ( values %pkgs )
{
  ok( -e "$dir/local/lib/perl5/$file", "Library file $file exists" );
}

chdir $pwd;
done_testing;
