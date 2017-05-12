
package
AWS::CloudFront::Signer;

use VSO;
use HTTP::Request::Common;
use HTTP::Date 'time2str';
use MIME::Base64 qw(encode_base64);
use URI::Escape qw(uri_escape_utf8);
use URI::QueryParam;
use URI::Escape;
use URI;
use Digest::HMAC_SHA1 'hmac_sha1';
use Digest::MD5 'md5';
use Encode;

my $METADATA_PREFIX      = 'x-amz-meta-';
my $AMAZON_HEADER_PREFIX = 'x-amz-';

enum 'AWS::CloudFront::HTTPMethod' => [qw( HEAD GET PUT POST DELETE )];

has 'cf' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront',
  required  => 1,
);

has 'date' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  default   => sub {
    time2str(time)
  }
);

has 'signature' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  lazy      => 1,
  default   => sub {
    my $s = shift;
    encode_base64(hmac_sha1($s->date, $s->cf->secret_access_key));
  }
);


sub auth_header
{
  my $s = shift;
  
  return 'AWS ' . $s->cf->access_key_id . ':' . $s->signature;
}# end auth_header()


sub _urlencode
{
  my ($unencoded ) = @_;
  return uri_escape_utf8( $unencoded, '^A-Za-z0-9_-' );
}# end _urlencode()

1;# return true:

