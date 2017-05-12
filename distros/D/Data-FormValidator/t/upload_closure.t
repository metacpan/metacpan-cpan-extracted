#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN
{
  eval { require CGI;CGI->VERSION(4.35); };
  plan skip_all => 'CGI 4.35 or higher not found' if $@;
  use_ok('CGI');
  use_ok('Data::FormValidator::Constraints::Upload');
}

#########################

%ENV = (
  %ENV,
  'SCRIPT_NAME'       => '/test.cgi',
  'SERVER_NAME'       => 'perl.org',
  'HTTP_CONNECTION'   => 'TE, close',
  'REQUEST_METHOD'    => 'POST',
  'SCRIPT_URI'        => 'http://www.perl.org/test.cgi',
  'CONTENT_LENGTH'    => 3129,
  'SCRIPT_FILENAME'   => '/home/usr/test.cgi',
  'SERVER_SOFTWARE'   => 'Apache/1.3.27 (Unix) ',
  'HTTP_TE'           => 'deflate,gzip;q=0.3',
  'QUERY_STRING'      => '',
  'REMOTE_PORT'       => '1855',
  'HTTP_USER_AGENT'   => 'Mozilla/5.0 (compatible; Konqueror/2.1.1; X11)',
  'SERVER_PORT'       => '80',
  'REMOTE_ADDR'       => '127.0.0.1',
  'CONTENT_TYPE'      => 'multipart/form-data; boundary=xYzZY',
  'SERVER_PROTOCOL'   => 'HTTP/1.1',
  'PATH'              => '/usr/local/bin:/usr/bin:/bin',
  'REQUEST_URI'       => '/test.cgi',
  'GATEWAY_INTERFACE' => 'CGI/1.1',
  'SCRIPT_URL'        => '/test.cgi',
  'SERVER_ADDR'       => '127.0.0.1',
  'DOCUMENT_ROOT'     => '/home/develop',
  'HTTP_HOST'         => 'www.perl.org'
);

diag "testing with CGI.pm version: $CGI::VERSION";

open( IN, '<t/upload_post_text.txt' ) || die 'missing test file';
binmode(IN);

*STDIN = *IN;
my $q = CGI->new;

use Data::FormValidator;
use Data::FormValidator::Constraints::Upload qw(
  &file_format
  &file_max_bytes
  &image_max_dimensions
);

my $default = {
  required => [qw/hello_world does_not_exist_gif 100x100_gif 300x300_gif/],
  validator_packages => 'Data::FormValidator::Constraints::Upload',
  constraint_methods => {
    'hello_world'        => file_format(),
    'does_not_exist_gif' => file_format(),
    '100x100_gif'        => [ file_format(), file_max_bytes(), ],
    '300x300_gif'        => file_max_bytes(100),
  },
};

my $dfv = Data::FormValidator->new( { default => $default } );
my ($results);
eval { $results = $dfv->check( $q, 'default' ); };
is( $@, '', 'survived eval' );

my $valid    = $results->valid;
my $invalid  = $results->invalid;    # as hash ref
my @invalids = $results->invalid;
my $missing  = $results->missing;

# Test to make sure hello world fails because it is the wrong type
ok( ( grep { m/hello_world/ } @invalids ), 'expect format failure' );

# should fail on empty/missing source file data
ok( ( grep { m/does_not_exist_gif/ } @invalids ),
  'expect non-existent failure' );

# Make sure 100x100 passes because it is the right type and size
ok( exists $valid->{'100x100_gif'} );

my $meta = $results->meta('100x100_gif');
is( ref $meta, 'HASH', 'meta() returns hash ref' );

ok( $meta->{extension}, 'setting extension meta data' );
ok( $meta->{mime_type}, 'setting mime_type meta data' );

# 300x300 should fail because it is too big
ok( ( grep { m/300x300/ } @invalids ), 'max_bytes' );

ok( $results->meta('100x100_gif')->{bytes} > 0, 'setting bytes meta data' );

# Revalidate to usefully re-use the same fields
my $profile_2 = {
  required           => [qw/hello_world 100x100_gif 300x300_gif/],
  validator_packages => 'Data::FormValidator::Constraints::Upload',
  constraint_methods => {
    '100x100_gif' => image_max_dimensions( 200, 200 ),
    '300x300_gif' => image_max_dimensions( 200, 200 ),
  },
};

$dfv = Data::FormValidator->new( { profile_2 => $profile_2 } );
eval { $results = $dfv->check( $q, 'profile_2' ); };
is( $@, '', 'survived eval' );

$valid    = $results->valid;
$invalid  = $results->invalid;    # as hash ref
@invalids = $results->invalid;
$missing  = $results->missing;

ok( exists $valid->{'100x100_gif'}, 'expecting success with max_dimensions' );
ok( ( grep /300x300/, @invalids ), 'expecting failure with max_dimensions' );

ok( $results->meta('100x100_gif')->{width} > 0, 'setting width as meta data' );
ok( $results->meta('100x100_gif')->{width} > 0, 'setting height as meta data' );

# Now test trying constraint_regxep_map
my $profile_3 = {
  required                     => [qw/hello_world 100x100_gif 300x300_gif/],
  validator_packages           => 'Data::FormValidator::Constraints::Upload',
  constraint_method_regexp_map => {
    '/[13]00x[13]00_gif/' => image_max_dimensions( 200, 200 ),
  } };

$dfv = Data::FormValidator->new( { profile_3 => $profile_3 } );
( $valid, $missing, $invalid ) = $dfv->validate( $q, 'profile_3' );

ok( exists $valid->{'100x100_gif'},
  'expecting success with max_dimensions using constraint_regexp_map' );
ok( ( grep { m/300x300/ } @$invalid ),
  'expecting failure with max_dimensions using constraint_regexp_map' );

done_testing;
