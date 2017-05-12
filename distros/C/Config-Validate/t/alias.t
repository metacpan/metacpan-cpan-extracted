#!/sw/bin/perl

use strict;
use warnings;
use Test::More tests => 5;
use Data::Dumper;

BEGIN { use_ok('Config::Validate') };

my $cv = Config::Validate->new;

{ # string alias
  $cv->schema({ aliastest => { type => 'boolean',
                               alias => 'alias2',
                             }});
  eval { $cv->validate({alias2 => 0}) };
  is($@, '', 'string alias successful');
}

{ # array ref alias
  $cv->schema({ aliastest => { type => 'boolean',
                               alias => [ qw(alias2 alias3) ],
                             }});
  eval { $cv->validate({alias2 => 0}) };
  is($@, '', 'arrayref 1 alias successful');
  eval { $cv->validate({alias3 => 0}) };
  is($@, '', 'arrayref 2 alias successful');
}

{ # invalid alias
  $cv->schema({ aliastest => { type => 'boolean',
                               alias => {},
                             }});
  eval { $cv->validate({alias2 => 0}) };
  like($@, qr/is type HASH, /, 'invalid alias failed (expected)');
}


