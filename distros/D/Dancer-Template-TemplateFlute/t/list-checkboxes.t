#! perl

use strict;
use warnings;
use Test::More tests => 1;
use Dancer ":tests";

set template => 'template_flute';

set views => 't/views';

set logger => 'console';
set layout => undef;

my $iter = [{ code => "first", received_check => '1', },
            { code => "second", received_check => '1' }];

my $out = template(checkbox => { items => $iter });


my $expected =<<'OUT';
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="first" />
</span>
</li>
<li class="list">
<span class="received-check">
<input class="received" name="received" type="checkbox" value="second" />
</span>
</li>
OUT
$expected =~ s/\n//g;

like $out, qr/\Q$expected\E/;


