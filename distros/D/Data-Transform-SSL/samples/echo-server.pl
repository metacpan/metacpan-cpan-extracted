use strict;
use warnings;

use lib '../lib';

warn <<EOM;
*** NOTICE ***********************************************************
* This will only work if you applied the patch from RT ticket #38669 *
* (http://rt.cpan.org/Public/Bug/Display.html?id=38669) to POE.      *
**********************************************************************
EOM

use Scalar::Util qw(blessed);
use POE qw(
   Component::Server::TCP
   Wheel::ReadWrite
);
use Data::Transform::SSL;

my $s = POE::Component::Server::TCP->new(
   Port => 12345,
   ClientFilter => Data::Transform::SSL->new(type => 'Server', key => glob('../t/key.pem'), cert => glob('../t/cert.pem')),
   ClientInput => sub {
      my ($heap, $input) = @_[HEAP, ARG0];
      $heap->{client}->put($input);
   },
);

$poe_kernel->run;
