#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Data::Dumper;

BEGIN { use_ok('Config::Validate') };

my $cv = Config::Validate->new;

{ # normal test case
  $cv->schema({ teststring => { type => 'string' }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  is ($@, '', 'normal case succeeded');
}

{ # success w/length limits
  $cv->schema({ teststring => { type => 'string',
                                minlen => 1,
                                maxlen => 50,
                              }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  is ($@, '', 'length limits succeeded');
}

{ # failure for max len
  $cv->schema({teststring => { type => 'string',
                               minlen => 1,
                               maxlen => 1,
                             }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  like($@, qr/length of string is 4, but must be less than 1/, 
       "maxlen failed (expected)");
}

{ # failure for min len
  $cv->schema({ teststring => { type => 'string',
                                minlen => 1000,
                                maxlen => 1000,
                              }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  like($@, qr/length of string is 4, but must be greater than 1000/, 
       "minlen failed (expected)");
}

{ # success w/regex - qr//
  $cv->schema({teststring => { type => 'string',
                               regex => qr/^t/i,
                             }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  is($@, '', 'regex match succeeded - qr//');
}

{ # success w/regex - string
  $cv->schema({ teststring => { type => 'string',
                                regex => '^t',
                              }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  is($@, '', 'regex match succeeded - string');
}

{ # failure w/regex - qr//
  $cv->schema({ teststring => { type => 'string',
                                regex => qr/^y/i,
                              }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  like($@, qr/regex (\S+?) didn't match 'test'/, 'regex match failed (expected) - qr//');
}

{ # failure w/regex - string
  $cv->schema({ teststring => { type => 'string',
                                regex => '^y',
                              }});
  my $value = { teststring => 'test' };
  eval { $cv->validate($value) };
  like($@, qr/regex (\S+?) didn't match 'test'/, 'regex match failed (expected) - string');
}



