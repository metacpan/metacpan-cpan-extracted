package Cikl::Models::Address::url;
use strict;
use warnings;
use Mouse;
use Cikl::Models::AddressRole;
use Cikl::DataTypes::Url;
use namespace::autoclean;
with 'Cikl::Models::AddressRole';

use constant RE_URL_SCHEME => qr/^[-+.a-zA-Z0-9]+:\/\//;

sub type { 'url' }

has '+value' => (
  isa => 'Cikl::DataTypes::Url',
);


sub normalize_value {
  my $class = shift;
  my $url = shift;
  return $url unless ($url && ref($url) eq '');
  $url =~ s/^\s+//;
  $url =~ s/\s+$//;
  if ($url !~ RE_URL_SCHEME) {
    # Default to 'http' if a scheme has not been specified. 
    $url= "http://$url";
  }
  my $uri_obj = URI->new($url)->canonical();
  $url = $uri_obj->as_string();
  return $url;
}

__PACKAGE__->meta->make_immutable;
1;



