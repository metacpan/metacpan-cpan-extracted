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

my $cgi_simple_test = 0;

eval { require CGI::Simple; };

if ($@)
{
  diag "Skipping CGI::Simple Tests";
}
else
{
  diag "Adding CGI::Simple tests";
  $cgi_simple_test = 1;
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
diag "testing with CGI::Simple version: $CGI::Simple::VERSION"
  if $cgi_simple_test;

## testing vars
my $cgi_pm_q;
my $cgi_simple_q;

## setup input (need cleaner way)
open( IN, '<t/upload_post_text.txt' ) || die 'missing test file';
binmode(IN);

*STDIN    = *IN;
$cgi_pm_q = CGI->new;
close(IN);

## setup CGI::Simple testing
if ($cgi_simple_test)
{
  open( IN, '<t/upload_post_text.txt' ) || die 'missing test file';
  binmode(IN);
  *STDIN = *IN;
  ## annoying context
  $CGI::Simple::DISABLE_UPLOADS = 0;

  # Repeat to avoid warning..
  $CGI::Simple::DISABLE_UPLOADS = 0;
  $cgi_simple_q                 = CGI::Simple->new();
  close(IN);
}

use Data::FormValidator;
my $default = {
  required => [qw/hello_world does_not_exist_gif 100x100_gif 300x300_gif/],
  validator_packages => 'Data::FormValidator::Constraints::Upload',
  constraints        => {
    'hello_world' => {
      constraint_method => 'file_format',
      params            => [],
    },
    'does_not_exist_gif' => {
      constraint_method => 'file_format',
      params            => [],
    },
    '100x100_gif' => [ {
        constraint_method => 'file_format',
        params            => [],
      },
      {
        constraint_method => 'file_max_bytes',
        params            => [],
      }
    ],
    '300x300_gif' => {
      constraint_method => 'file_max_bytes',
      params            => [ \100 ],
    },
  },
};

## same set of tests with each one (does this work?)
for my $q ( $cgi_pm_q, $cgi_simple_q )
{
  next unless $q;
  diag "Running tests with ", ref $q;

  my $dfv = Data::FormValidator->new( { default => $default } );
  my $results;
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

  ok( ( exists $valid->{'100x100_gif'}, "valid" ),
    'Make sure 100x100 passes because it is the right type and size' );

  my $meta = $results->meta('100x100_gif');
  is( ref $meta, 'HASH', 'meta() returns hash ref' );

  ok( $meta->{extension}, 'setting extension meta data' );
  ok( $meta->{mime_type}, 'setting mime_type meta data' );

  ok( ( grep { m/300x300/ } @invalids ),
    '300x300 should fail because it exceeds max_bytes' );

  ok(
    ( $results->meta('100x100_gif')->{bytes} > 0 ),
    ( ref $q ) . ': setting bytes meta data'
  );

  # Revalidate to usefully re-use the same fields
  my $profile_2 = {
    required           => [qw/hello_world 100x100_gif 300x300_gif/],
    validator_packages => 'Data::FormValidator::Constraints::Upload',
    constraints        => {
      '100x100_gif' => {
        constraint_method => 'image_max_dimensions',
        params            => [ \200, \200 ],
      },
      '300x300_gif' => {
        constraint_method => 'image_max_dimensions',
        params            => [ \200, \200 ],
      },
    },
  };

  $dfv = Data::FormValidator->new( { profile_2 => $profile_2 } );
  eval { $results = $dfv->check( $q, 'profile_2' ); };
  ok( not $@ ) or diag $@;

  $valid    = $results->valid;
  $invalid  = $results->invalid;    # as hash ref
  @invalids = $results->invalid;
  $missing  = $results->missing;

  ok( exists $valid->{'100x100_gif'}, 'expecting success with max_dimensions' );
  ok( ( grep /300x300/, @invalids ), 'expecting failure with max_dimensions' );

  ok( $results->meta('100x100_gif')->{width} > 0,
    'setting width as meta data' );
  ok( $results->meta('100x100_gif')->{width} > 0,
    'setting height as meta data' );

  # Now test trying constraint_regxep_map
  my $profile_3 = {
    required              => [qw/hello_world 100x100_gif 300x300_gif/],
    validator_packages    => 'Data::FormValidator::Constraints::Upload',
    constraint_regexp_map => {
      '/[13]00x[13]00_gif/' => {
        constraint_method => 'image_max_dimensions',
        params            => [ \200, \200 ],
      } } };

  $dfv = Data::FormValidator->new( { profile_3 => $profile_3 } );
  ( $valid, $missing, $invalid ) = $dfv->validate( $q, 'profile_3' );

  ok( exists $valid->{'100x100_gif'},
    'expecting success with max_dimensions using constraint_regexp_map' );
  ok( ( grep { m/300x300/ } @$invalid ),
    'expecting failure with max_dimensions using constraint_regexp_map' );

  ## min test
  my $profile_4 = {
    required           => [qw/hello_world 100x100_gif 300x300_gif/],
    validator_packages => 'Data::FormValidator::Constraints::Upload',
    constraints        => {
      '100x100_gif' => {
        constraint_method => 'image_min_dimensions',
        params            => [ \200, \200 ],
      },
      '300x300_gif' => {
        constraint_method => 'image_min_dimensions',
        params            => [ \200, \200 ],
      },
    },
  };

  $dfv = Data::FormValidator->new( { profile_4 => $profile_4 } );
  eval { $results = $dfv->check( $q, 'profile_4' ); };
  ok( not $@ ) or diag $@;

  $valid    = $results->valid;
  $invalid  = $results->invalid;    # as hash ref
  @invalids = $results->invalid;
  $missing  = $results->missing;

  ok( exists $valid->{'300x300_gif'}, 'expecting success with min_dimensions' );
  ok( ( grep /100x100/, @invalids ), 'expecting failure with min_dimensions' );

  ## file type tests
  ## with new interface
  {
    use Data::FormValidator::Constraints::Upload qw(file_format);

    my $profile_5 = {
      required           => [qw/hello_world 100x100_gif 300x300_gif/],
      constraint_methods => {
        '100x100_gif' => [ file_format( mime_types => [qw(image/gif)] ) ],
        '300x300_gif' => [ file_format( mime_types => [qw(image/png)] ) ] } };

    $dfv = Data::FormValidator->new( { profile_5 => $profile_5 } );
    eval { $results = $dfv->check( $q, 'profile_5' ); };

    ok( not $@ ) or diag $@;

    $valid    = $results->valid;
    $invalid  = $results->invalid;    # as hash ref
    @invalids = $results->invalid;
    $missing  = $results->missing;

    ok( exists $valid->{'100x100_gif'}, 'expecting success with mime_type' );
    ok( ( grep /300x300/, @invalids ), 'expecting failure with mime_type' );
  }

  ## range checks with new format
  {
    use Data::FormValidator::Constraints::Upload
      qw(image_max_dimensions image_min_dimensions);
    my $profile_6 = {
      required           => [qw/hello_world 100x100_gif 300x300_gif/],
      constraint_methods => {
        '100x100_gif' => [
          image_max_dimensions( 200, 200 ), image_min_dimensions( 110, 100 )
        ],
        '300x300_gif' => [
          image_max_dimensions( 400, 400 ), image_min_dimensions( 245, 100 ) ] }
    };

    $dfv = Data::FormValidator->new( { profile_6 => $profile_6 } );
    eval { $results = $dfv->check( $q, 'profile_6' ); };
    is( $@, '', 'survived eval' );

    $valid    = $results->valid;
    $invalid  = $results->invalid;    # as hash ref
    @invalids = $results->invalid;
    $missing  = $results->missing;

    ok( ( grep /100x100/, @invalids ), 'expecting failure with size range' );
    ok( exists $valid->{'300x300_gif'}, 'expecting success with size range' );

  }

} ## end of for loop

done_testing;
