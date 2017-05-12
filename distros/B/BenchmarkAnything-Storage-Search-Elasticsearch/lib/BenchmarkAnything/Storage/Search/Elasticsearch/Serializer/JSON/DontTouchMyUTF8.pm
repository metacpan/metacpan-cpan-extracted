package BenchmarkAnything::Storage::Search::Elasticsearch::Serializer::JSON::DontTouchMyUTF8;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Pass through known-utf8 data untouched to Elasticsearch.
$BenchmarkAnything::Storage::Search::Elasticsearch::Serializer::JSON::DontTouchMyUTF8::VERSION = '0.002';
# As seen in
#   https://github.com/elastic/elasticsearch-perl/issues/57
# (Kudos to Celogeek - you are not alone!)


use Moo;
use JSON::MaybeXS 1.002002 ();

has 'JSON' => ( is => 'ro', default => sub { JSON::MaybeXS->new } );

with 'Search::Elasticsearch::Role::Serializer::JSON';
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BenchmarkAnything::Storage::Search::Elasticsearch::Serializer::JSON::DontTouchMyUTF8 - Pass through known-utf8 data untouched to Elasticsearch.

=head2 JSON

The JSON instance which does not contain special utf-8 fiddling.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
