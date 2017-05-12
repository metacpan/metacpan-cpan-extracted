#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::DataPath;

use base qw(Test::Class);
use Test::More;
use Config::Validate;
use Data::Dumper;

sub not_found :Test(1) {
  local @INC = ();

  eval {
    my $cv = Config::Validate->new(schema => {test => { type => 'boolean' } },
                                   data_path => 1);
  };
  like($@, qr/Data::Path requested, but cannot/, 
       "fails if Data::Path requested but not found");

  return;
}
