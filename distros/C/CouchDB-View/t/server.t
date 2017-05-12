use strict;
use warnings;
use Test::More 'no_plan';
use Test::Deep;

use CouchDB::View::Server;
use JSON::XS;

my $j = JSON::XS->new;

my $out = IO::Array->new;

my $server = CouchDB::View::Server->new({
  out => $out,
});

$server->process($j->encode([
  add_fun => 'sub { dmap(undef, shift) }',
]) . "\n");

is($out->getline, "true\n", "add_fun with valid code");

$server->process($j->encode([
  add_fun => 'invalid perl code!!!',
]) . "\n");

cmp_deeply(
  eval { $j->decode($out->getline) },
  {
    error => {
      id => 'map_compilation_error',
      reason => re(qr/syntax error/),
    },
  },
  "error in invalid code",
);

$server->process(<<"");
["map_doc", {"_id":"8877AFF9789988EE","_rev":46874684684,"field":"value","otherfield":"othervalue"}]\n


is_deeply(
  $j->decode($out->getline),
  $j->decode(<<""), "correct map");
[[[null,{"_id":"8877AFF9789988EE","_rev":46874684684,"field":"value","otherfield":"othervalue"}]]]\n


package IO::Array;

sub new { bless [] => shift }

sub print {
  my $self = shift;
  my @new = split /(?<=\n)/, join "", @_;
  if (@$self) {
    $self->[-1] .= shift @new while $self->[-1] !~ /\n$/;
  }
  push @$self, @new;
}

sub getline { shift @{+shift} }
