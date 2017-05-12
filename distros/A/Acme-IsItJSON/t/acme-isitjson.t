# This is a test for module Acme::IsItJSON.

use warnings;
use strict;
use Test::More;
use Acme::IsItJSON 'is_it_json';

my $perl = { this => 'is', Not => 'json' };
my $json = '{"but":"this","IS":"json"}';

open my $out, ">", \my $output or die $!;
select $out;
is_it_json ($perl);
like ($output, qr/a perl data structure/i);
note ($output);

$output = '';

is_it_json ($json);
like ($output, qr/JSON/);
note ($output);
done_testing ();

# Local variables:
# mode: perl
# End:
