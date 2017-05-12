#!perl -w

use strict;
use warnings;

use Test::More qw(no_plan);

=head1 NAME

B<learning-JSONRPC.t> - Send a JSON-RPC request using Catalyst::Test
(ie this is actually not an RPC)

=cut

BEGIN {
    use_ok 'Catalyst::Test', 'App::CamelPKI';
    use_ok 'Test::Group';
    use_ok 'Catalyst::Utils';
    use_ok 'JSON';
    use_ok 'Crypt::OpenSSL::CA';
    use_ok 'App::CamelPKI::Test';
}

my $bonjourstruct =
  jsoncall_local("http://localhost:3000/test/json_helloworld",
          {"nom" => "Klein", "prenom" => "Jeremie"});

my $salutation = $bonjourstruct->{"salutation"};
utf8::decode($salutation) or die;

is($bonjourstruct->{"salutation"}, "Hello, Jeremie Klein !");
