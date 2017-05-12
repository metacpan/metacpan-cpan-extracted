use strict;
use warnings;
use Scalar::Util qw(blessed);
use POE qw(
	Wheel::ReadWrite
	Component::Client::TCP
);

warn <<EOM;
*** NOTICE ***********************************************************
* This will only work if you applied the patch from RT ticket #38669 *
* (http://rt.cpan.org/Public/Bug/Display.html?id=38669) to POE.      *
**********************************************************************
EOM

use Data::Transform::SSL;
use Data::Transform::Identity;

POE::Component::Client::TCP->new (
   RemoteAddress => "localhost",
   RemotePort    => "12345",
   Filter => Data::Transform::SSL->new(),
   #Filter => Data::Transform::Identity->new(),

   Connected => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      my @lines = ("foo\n", "bar", "baz\n");
      foreach my $line (@lines) {
        $heap->{server}->put ($line);
      }
      $kernel->delay('shutdown' => 3);
   },
   ServerInput => sub {
      my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

      print $input;
   },
);

$poe_kernel->run;
exit 0;
