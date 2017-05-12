#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;

BEGIN { use_ok('Config::Validate', 'validate') };

{ # Test success
  my $define = { type => 'boolean' };
  
  my $callback = sub {
    my ($self, $value, $def, $path) = @_;
    
    ok(1, "callback ran");
    isa_ok($self, 'Config::Validate');
    is($value, 'yes', "value argument correct");
    is_deeply($def, $define, 'define argument correct');
    is_deeply($path, [ 'booleantest' ], 'path argument correct');
  };
  
  $define->{callback} = $callback;
  
  my $schema = { booleantest => $define };
  my $data = { booleantest => 'yes' };
  eval { validate($data, $schema) };
  is($@, '', "validated correctly");
}

{ # bad callback
  my $schema = { booleantest => { type => 'boolean',
                                  callback => [],
                                } };
  my $data = { booleantest => 'yes' };
  eval { validate($data, $schema) };

  like($@, qr/callback specified is not a code reference/, 
       "bad callback didn't validate (expected)");
}
