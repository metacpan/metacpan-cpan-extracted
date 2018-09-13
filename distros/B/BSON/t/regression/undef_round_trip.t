use strict;
use warnings;

use Test::More;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;
use Tie::IxHash;

my $c = BSON->new;

# PERL-543 deflation to BSON then back (via database?) caused undef to be an empty string

subtest 'tied Tie::IxHash' => sub {
  my %h;
  tie( %h, 'Tie::IxHash', h => undef );

  my $bin = $c->encode_one( \%h );
  my $doc = $c->decode_one( $bin );

  is $doc->{h}, undef, 'round trip undef';
};

subtest 'OO Tie::IxHash' => sub {
  my $h = Tie::IxHash->new( h => undef );

  my $bin = $c->encode_one( $h );
  my $doc = $c->decode_one( $bin );

  is $doc->{h}, undef, 'round trip undef';
};

subtest 'standard hash' => sub {
  my %doc = ( h => undef );

  my $bin = $c->encode_one( \%doc );
  my $doc = $c->decode_one( $bin );

  is $doc->{h}, undef, 'round trip undef';
};

done_testing;
