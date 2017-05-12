use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP ();

my $url = 'http://search.cpan.org/api/dist/perl';

my $resp = HTTP::Tiny->new( )->get( $url );
die "Oh dear\n" unless $resp->{success};

my $data = eval { JSON::PP::decode_json( $resp->{content} ) };
die "No data\n" unless $data;
{
  use Data::Dumper::Concise;
  print Dumper( $data );
}

for my $release ( @{ $data->{releases} } ) {
}
