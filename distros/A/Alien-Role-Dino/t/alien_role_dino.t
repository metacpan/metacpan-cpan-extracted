use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Test::Alien;
use Alien::Role::Dino;
use Test2::Mock;
use Env qw( @PATH );

$ENV{VERBOSE} = 1;

{
  package Alien::MyDinoBase;;
  
  use base qw( Alien::Base );
  use Role::Tiny::With qw( with );
  
  with 'Alien::Role::Dino';
}

my $xs = do { local $/; <DATA> };

foreach my $type (qw( autoheck cmake ))
{
  subtest $type => sub {

    @Test::Alien::aliens = ();

    if($type eq 'autoheck')
    {
      skip_all 'test requires Alien::Autotools 0.99'
        unless eval q{ use Alien::Autotools 0.99; 1 };
    }
    elsif($type eq 'cmake')
    {
      skip_all 'test requires Alien::Build::Plugin::Build::CMake and Alien::cmake3'
        unless eval q{ use Alien::Build::Plugin::Build::CMake; use Alien::cmake3; 1 };
      # cmake-libpalindrome doesn't seem to generate a .a file for the dll
      skip_all 'todo: MSWin32' if $^O eq 'MSWin32';
    }

    my $alien;

    subtest 'build' => sub {

      # on Windows the thing that Dino needs to do is add 'bin'
      # to the PATH, but Test::Alien adds that directory to the
      # path as a matter of course so that run_ok can function.
      # For the XS and FFI tests we don't want Test::Alien to
      # put bin in the PATH (we want Dino to do that), so we
      # temporarily patch Dino's bin_dir to return empty list
      my $mock = Test2::Mock->new(
        class => 'Alien::MyDinoBase',
        override => [
          bin_dir => sub { () }
        ],
      );

      alienfile_ok filename => "corpus/$type-libpalindrome.alienfile";

      $alien = alien_build_ok { class => 'Alien::MyDinoBase' };

      isa_ok $alien, 'Alien::Base';
      isa_ok $alien, 'Alien::MyDinoBase';

      alien_ok $alien;
    };


    subtest 'use xs' => sub {

      xs_ok { xs => $xs, verbose => 1 }, with_subtest {
        my($mod) = @_;
        is($mod->is_palindrome("Something that is not a palindrome"), 0);
        is($mod->is_palindrome("Was it a car or a cat I saw?"), 1);
      };
    };

    subtest 'use ffi' => sub {

      ffi_ok { symbols => ['is_palindrome'] }, with_subtest {
        my ($ffi) = @_;
  
        my $is_palindrome = $ffi->function(is_palindrome => ['string'] => 'int');
  
        is($is_palindrome->("Something that is not a palindrome"), 0);
        is($is_palindrome->("Was it a car or a cat I saw?"), 1);
      };
    };

    subtest 'use exe' => sub {

      local $ENV{PATH} = $ENV{PATH};

      unshift @PATH, $alien->bin_dir;

      run_ok(['palx', 'Something that is not a palindrome'])
        ->note
        ->exit_is(2);

      run_ok(['palx', 'Was it a car or a cat I saw?'])
        ->note
        ->success;

      run_ok(['palx', 'racecar'])
        ->note
        ->success;

    };
  }
}

done_testing

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libpalindrome.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
is_palindrome(klass, word)
    const char *klass
    const char *word
  CODE:
    RETVAL = is_palindrome(word);
  OUTPUT:
    RETVAL
