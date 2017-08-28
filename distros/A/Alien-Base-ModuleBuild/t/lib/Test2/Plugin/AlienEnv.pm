package Test2::Plugin::AlienEnv;

use strict;
use warnings;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );

sub import
{
  delete $ENV{ACTIVESTATE_PPM_BUILD};
  delete $ENV{ALIEN_INSTALL_TYPE};
  delete $ENV{ALIEN_FORCE};
  $ENV{PERL_INLINE_DIRECTORY} = tempdir( DIR => path('.')->absolute->stringify, CLEANUP => 1, TEMPLATE => 'inlineXXXXX');
}

1;
