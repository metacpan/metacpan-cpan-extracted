use strict;
use FindBin;
use Test::More;
use Cwd qw/cwd/;
use File::Temp qw/tempdir/;

require q[./t/helper.pm];

if ( !&App::MechaCPAN::has_git )
{
  # This is more of a test to make sure has_git stays sane than anything
  # A lot of this is belt-and-suspenders. Not sure how much value this has
  plan skip_all => 'Cannot test has_git without git';
}

my $above_git = &App::MechaCPAN::_git_str + 1;
my $below_git = &App::MechaCPAN::_git_str - 1;

{
  no strict 'refs';
  no warnings 'redefine';
  local *App::MechaCPAN::_git_str = sub {$above_git};

  is( &App::MechaCPAN::has_git, 1, 'A newer git is allowed' );

  is( &App::MechaCPAN::has_updated_git, 1, 'has_updated_git reports correctly' );
}

{
  no strict 'refs';
  no warnings 'redefine';
  local *App::MechaCPAN::_git_str = sub {$below_git};

  is( &App::MechaCPAN::has_git, undef, 'A older git is not allowed' );

  is( &App::MechaCPAN::has_updated_git, undef, 'has_updated_git prevents an older version' );
}

{
  no strict 'refs';
  no warnings 'redefine';
  local *App::MechaCPAN::min_git_ver = sub {$above_git};

  is( &App::MechaCPAN::has_git, undef, 'Can make it look like git is not new enough' );

  is( &App::MechaCPAN::has_updated_git, undef, 'has_updated_git reports the version outdatedness' );
}

is( &App::MechaCPAN::has_git, 1, 'Can go back to the built in min_git_ver without any caching' );

done_testing;
