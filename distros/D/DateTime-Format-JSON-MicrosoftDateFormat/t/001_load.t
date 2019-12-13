# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok( 'DateTime::Format::JSON::MicrosoftDateFormat' ); }

my $formatter = DateTime::Format::JSON::MicrosoftDateFormat->new;
isa_ok ($formatter, 'DateTime::Format::JSON::MicrosoftDateFormat');

{
  local $@;
  eval 'use DateTime::Format::JSON::MicrosoftDateFormat qw{bad}';
  my $error = $@;
  like($error, qr/Expecting parameters to be hash/, 'import odd 1');
}

{
  local $@;
  eval 'use DateTime::Format::JSON::MicrosoftDateFormat qw{bad import option}';
  my $error = $@;
  like($error, qr/Expecting parameters to be hash/, 'import odd 3');
}
