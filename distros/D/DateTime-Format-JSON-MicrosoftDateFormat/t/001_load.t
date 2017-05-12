# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'DateTime::Format::JSON::MicrosoftDateFormat' ); }

my $formatter = DateTime::Format::JSON::MicrosoftDateFormat->new;
isa_ok ($formatter, 'DateTime::Format::JSON::MicrosoftDateFormat');
