package JSON::Dumper::Compact;

use JSON::MaybeXS;
use Mu::Tiny;

our $VERSION = '0.005000';
$VERSION =~ tr/_//d;

extends 'Data::Dumper::Compact';

lazy json_obj => sub {
  JSON->new
      ->allow_nonref(1)
      ->relaxed(1)
      ->filter_json_single_key_object(__bless__ => sub {
          bless($_[0][1], $_[0][0]);
        });
};

sub _json_decode { shift->json_obj->decode(@_) }

sub _build_dumper { my $j = shift->json_obj; sub { $j->encode($_[0]) } }

sub _format_el { shift->_format(@_).',' }

sub _format_hashkey { $_[0]->json_obj->encode($_[1]).':' }

sub _format_string { '"'.$_[1].'"' }

sub _format_thing { $_[1] }

around _expand_blessed => sub {
  my ($orig, $self) = (shift, shift);
  my ($blessed) = @_;
  return $self->expand($blessed->TO_JSON) if $blessed->can('TO_JSON');
  return $self->$orig(@_);
};

sub _format_blessed {
  my ($self, $payload) = @_;
  my ($content, $class) = @$payload;
  $self->_format([ hash => [
    [ '__bless__' ],
    { '__bless__' => [ array => [ [ string => $class ], $content ] ] },
  ] ]);
}

sub encode { shift->dump(@_) }

sub decode {
  my ($self, $data, $opts) = @_;
  $self->_optify($opts, _json_decode => $data);
}

1;

=head1 NAME

JSON::Dumper::Compact - JSON processing with L<Data::Dumper::Compact> aesthetics

=head1 SYNOPSIS

  use JSON::Dumper::Compact 'jdc';
  
  my $json = jdc($data);

=head1 DESCRIPTION

JSON::Dumper::Compact is a subclass of L<Data::Dumper::Compact> that turns
arrayrefs and hashrefs intead into JSON.

Deep data structures are rendered highly compactly:

  [
    "1556933590.65383", "Fri May  3 18:33:10 2019", 26794, "INFO", 3,
    [ "SRV:8FB66F32" ], [ [
        "/opt/voice-srvc-native/bin/async-srvc-att-gateway-poller", 33,
        "NERV::Voice::SRV::Native::AsyncSRVATTGatewayPoller::main",
    ] ],
    "batch_nena_messages returned", "OK", 6, { "FILENAME": "lqxw020323" },
    1556933584, "lqxw020323",
  ]

To ease debugging, blessed references without a C<TO_JSON> method are
rendered as an object with a single two-element arrayref value:

  { "__bless__": [
    "The::Class",
    { "the": "object" },
  ] }

=head1 METHODS

In addition to the L<Data::Dumper::Compact> methods, we provide:

=head2 encode

  JSON::Dumper::Compact->encode($data, \%opts?);
  $jdc->encode($data, \%opts?);

Operates identically to L<Data::Dumper::Compact/dump> but named to be less
confusing to code expecting a JSON object.

=head2 decode

  JSON::Dumper::Compact->decode($string, \%opts?);
  $jdc->decode($string, \%opts);

Runs the supplied string through an L<JSON::MaybeXS> C<decode> with options
set to be able to reliably reparse what we can currently format - notably
setting C<relaxed> to allow for trailing commas and using
C<filter_json_single_key_object> to re-inflate blessed objects.

Note that using this method on untrusted data is a security risk. While
C<encode>/C<dump> should be usable for JSON formatting, in general,
C<decode> fully rehydrates for debugging purposes and as such can e.g.
cause DESTROY methods to be called unexpectedly, which can allow a
malicious user to do things to your perl5 VM. Rather than using
debugging specific code on untrusted data, use L<JSON::MaybeXS> or
L<Mojo::JSON> directly (if the C<encode> output doesn't parse correctly
via other libraries, please report that as a bug)..

DO NOT USE THIS METHOD ON UNTRUSTED DATA IT WAS NOT DESIGNED TO BE SECURE.

=head1 COPYRIGHT

Copyright (c) 2019 the L<Data::Dumper::Compact/AUTHOR> and
L<Data::Dumper::Compact/CONTRIBUTORS> as listed in L<Data::Dumper::Compact>.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
