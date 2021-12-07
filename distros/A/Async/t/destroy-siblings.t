use strict; use warnings;

use Test::More tests => 4;

use Async;

my $elder = Async->new( sub { select undef, undef, undef, 0.2; 'Hello, world!' } );
isa_ok $elder, 'Async';

my $younger = Async->new( sub { 'Goodbye, world' } );
isa_ok $younger, 'Async';

# ensure the younger child process exits normally and does global destruction
is $younger->result(1), 'Goodbye, world', 'forced completion';

is $elder->result(1), 'Hello, world!', 'children do not kill their siblings';
