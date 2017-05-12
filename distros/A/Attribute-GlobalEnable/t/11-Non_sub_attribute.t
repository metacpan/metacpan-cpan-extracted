## test nothing being set ##

use strict;
use warnings;

use Test::More tests => 3;
use lib qw( blib/lib t/lib);
use Attribute::GlobalEnable::TestModule;

## should have stuff loaded at this point ##
#

## will cause errors here ##
eval { my $a : Test = '' };
like( $@, qr/Invalid SCALAR attribute/, 'Test bad Scalar assignment'  );

eval { my @a : Test = () };
like( $@, qr/Invalid ARRAY attribute/, 'Test bad Array assignment'  );

eval { my %a : Test = () };
like( $@, qr/Invalid HASH attribute/, 'Test bad Hash assignment'  );


