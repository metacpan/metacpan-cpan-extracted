use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Gather::Dino;
use Path::Tiny qw( path );
use lib 'corpus/lib';

$ENV{VERBOSE} = 1;

{
  package Alien::MyDinoBase;
  
  use base qw( Alien::Base );
  use Role::Tiny::With qw( with );
  
  with 'Alien::Role::Dino';
}

foreach my $type (qw( autoheck cmake ))
{
  subtest $type => sub {

    if($type eq 'autoheck')
    {
      skip_all 'test requires Alien::Autotools 0.99'
        unless eval q{ use Alien::Autotools 0.99; 1 };
    }
    elsif($type eq 'cmake')
    {
      skip_all 'test requires Alien::Build::Plugin::Build::CMake and Alien::cmake3'
        unless eval q{ use Alien::Build::Plugin::Build::CMake; use Alien::cmake3; 1 };
    }

    my $build = alienfile_ok filename => "corpus/$type-libpalindrome.alienfile";

    my $alien = alien_build_ok { class => 'Alien::MyDinoBase' };

    note "cflags = ", $alien->cflags;
    note "libs   = ", $alien->libs;

    my $prefix = $alien->runtime_prop->{prefix};

    like( $alien->cflags, qr{-I$prefix/include} );
    like( $alien->libs,   qr{-L$prefix/lib -lpalindrome} );
    is( $alien->runtime_prop->{rpath}, [ $^O =~ /^(MSWin32|cygwin)$/ ? 'bin' : 'lib' ]);

    my @dirs = $alien->rpath;

    foreach my $rpath (@dirs)
    {
      note "  [ $rpath ]  ";
  
      foreach my $child (path($rpath)->children)
      {
        my $name = $child->basename;
        my $type = -d $child ? '/' : -l $child ? '@' : -x $rpath ? '*' : '';
    
        note "    - $name$type  ";
      }
    }
  }
}

done_testing
