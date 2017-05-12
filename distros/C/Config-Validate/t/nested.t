#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

BEGIN { use_ok('Config::Validate') };

my $cv = Config::Validate->new;

$cv->schema({nestedtest => { type => 'nested',
                             optional => 1,
                             child => { 
                               test => { type => 'string',
                                         default => 'blah'
                                        },
                               test2 => { type => 'boolean'},
                             },
                           }
            });

{ # Test optional element
  eval { $cv->validate({}); };
  is($@, '', 'nested item is optional');
}

{ # Test child with default
  my $result;
  eval { $result = $cv->validate({nestedtest => {test2 => 0}}); };
  is($@, '', 'nested item succeeded');
  is($result->{nestedtest}{test}, 'blah', "child default successful");
}
