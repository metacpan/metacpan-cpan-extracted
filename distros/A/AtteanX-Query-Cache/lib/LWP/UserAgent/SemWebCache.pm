package LWP::UserAgent::SemWebCache;

use 5.006000;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

use Moo;
use Digest::MD4 qw(md4_base64);
use Types::Standard qw(Str);

extends 'LWP::UserAgent';

has key => (
				is => 'rw',
				isa => Str,
				lazy => 1,
				clearer => 1,
				builder => '_build_key'
			  );

sub _build_key { return md4_base64(shift->request_uri->canonical->as_string) }


with 'LWP::UserAgent::Role::CHICaching',
     'LWP::UserAgent::Role::CHICaching::VaryNotAsterisk',
     'LWP::UserAgent::Role::CHICaching::SimpleMungeResponse';

1;


=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::SemWebCache - LWP::UserAgent for caching SPARQL Queries

=head1 SYNOPSIS

This is a slight modification of L<LWP::UserAgent::CHICaching>, and
can be used much like it:

  my $cache = CHI->new( driver => 'Memory', global => 1 );
  my $ua = LWP::UserAgent::SemWebCache->new(cache => $cache);
  my $res1 = $ua->get("http://localhost:3000/?query=DAHUT");

=head1 DESCRIPTION

This class composes the two roles L<LWP::UserAgent::Role::CHICaching>
and L<LWP::UserAgent::Role::CHICaching::VaryNotAsterisk> and
reimplements the C<key> attribute.

For now, it makes a relatively uncertain assumption that could in some
cases violate L<Section 4.1 of
RFC7234|http://tools.ietf.org/html/rfc7234#section-4.1> and cause
unpredictable results: Since SPARQL results come in different
serializations, the C<Vary> header will be present in most cases, and
therefore, different caches would usually have been required. However,
if we assume that no variations that are semantically significant
could occur, then we should be OK. Unless, of course, the server
declared that anything goes, which amount to setting C<Vary: *>, in
that case, we don't cache.

Additionally, since the URI resulting from a SPARQL protocol query
might be long, and long keys are often difficult for backend caches,
so the reimplementation of C<key> will create a digest.

=head2 Attributes and Methods

=over

=item C<< key >>, C<< clear_key >>

The key to use for a response. This role will return the canonical URI of the
request as a string, which is a reasonable default.

=back

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
