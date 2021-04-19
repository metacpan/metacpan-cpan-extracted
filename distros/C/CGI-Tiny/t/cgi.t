use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Test::More;
use Encode 'decode';
use JSON::PP 'decode_json', 'encode_json';
use MIME::Base64 'encode_base64';

my @env_keys = qw(
  AUTH_TYPE CONTENT_LENGTH CONTENT_TYPE GATEWAY_INTERFACE
  PATH_INFO PATH_TRANSLATED QUERY_STRING
  REMOTE_ADDR REMOTE_HOST REMOTE_IDENT REMOTE_USER
  REQUEST_METHOD SCRIPT_NAME
  SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE
);

sub _parse_response {
  my ($response) = @_;
  my ($headers_str, $body) = split /\r\n\r\n/, $response, 2;
  my %headers;
  foreach my $header (split /\r\n/, $headers_str) {
    my ($name, $value) = split /:\s*/, $header;
    push @{$headers{lc $name}}, $value;
  }
  $_ = $_->[0] for grep { @$_ == 1 } values %headers;
  my $response_status = defined $headers{status} ? $headers{status} : '200 OK';
  return {headers => \%headers, body => $body, status => $response_status};
}

subtest 'Empty response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  ok !length($response->{body}), 'empty response body';
};

subtest 'No render' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  cgi {
    my ($cgi) = @_;
    $cgi->set_error_handler(sub { $error = $_[1] });
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'Exception before render' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($error, $headers_rendered);
  cgi {
    my ($cgi) = @_;
    $cgi->set_error_handler(sub { $error = $_[1]; $headers_rendered = $_[0]->headers_rendered; });
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    die 'Error 42';
  };

  ok defined($error), 'error logged';
  like $error, qr/Error 42/, 'right error';
  ok !$headers_rendered, 'headers were not rendered';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'Exception after render' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($error, $headers_rendered);
  cgi {
    my ($cgi) = @_;
    $cgi->set_error_handler(sub { $error = $_[1]; $headers_rendered = $_[0]->headers_rendered; });
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render;
    die 'Error 42';
  };

  ok defined($error), 'error logged';
  like $error, qr/Error 42/, 'right error';
  ok $headers_rendered, 'headers were rendered';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
};

subtest 'Excessive request body' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $in_data = "\x01"x1000;
  local $ENV{CONTENT_LENGTH} = length $in_data;
  open my $in_fh, '<', \$in_data or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  cgi {
    my ($cgi) = @_;
    $cgi->set_error_handler(sub { $error = $_[1] });
    $cgi->set_request_body_limit(100);
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    my $body = $cgi->body;
    $cgi->render(data => $body);
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^413\b/, '413 response status';
};

subtest 'Not found' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->set_response_status(404);
    $cgi->render(text => '');
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^text\/plain/i, 'right content type';
  like $response->{status}, qr/^404\b/, '404 response status';
  ok !length($response->{body}), 'empty response body';
};

subtest 'Data response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $data = "\x01\x02\x03\x04\r\n\xFF";
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(data => $data);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $response->{body}, $data, 'right response body';
};

subtest 'Text response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $text = "♥☃";
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(text => $text);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^text\/plain.*UTF-8/i, 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is decode('UTF-8', $response->{body}), $text, 'right response body';
};

subtest 'Text response (UTF-16LE)' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $text = "♥☃";
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->set_response_charset('UTF-16LE');
    $cgi->render(text => $text);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^text\/plain.*UTF-16LE/i, 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is decode('UTF-16LE', $response->{body}), $text, 'right response body';
};

subtest 'HTML response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $html = "<html><head><title>♥</title></head><body><p>☃&nbsp;&amp;</p></body></html>";
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(html => $html);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^text\/html.*UTF-8/i, 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is decode('UTF-8', $response->{body}), $html, 'right response body';
};

subtest 'XML response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $xml = "<items><item>♥</item><item>☃&nbsp;&amp;</item></items>";
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(xml => $xml);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^application\/xml.*UTF-8/i, 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is decode('UTF-8', $response->{body}), $xml, 'right response body';
};

subtest 'JSON response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $ref = {stuff => ['and', '♥']};
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(json => $ref);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{headers}{'content-type'}, qr/^application\/json/i, 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply decode_json($response->{body}), $ref, 'right response body';
};

subtest 'Redirect response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $url = '/foo';
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->render(redirect => $url);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok !defined($response->{headers}{'content-type'}), 'Content-Type not set';
  is $response->{headers}{location}, $url, 'Location set';
  like $response->{status}, qr/^302\b/, '302 response status';
  ok !length($response->{body}), 'empty response body';
};

subtest 'Response headers' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my @headers = (
    ['X-Test', 'some value'],
    ['X-test', 'another value'],
  );
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $cgi->add_response_header(@$_) for @headers;
    $cgi->set_response_content_type('image/gif');
    $cgi->set_response_status(202);
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'image/gif', 'right content type';
  like $response->{status}, qr/^202\b/, '202 response status';
  is_deeply $response->{headers}{'x-test'}, ['some value', 'another value'], 'right custom headers';
};

subtest 'Query parameters' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  my $query_string = 'c=42&b=1+2%26&%E2%98%83=%25&c=foo';
  my @query_pairs = (['c', 42], ['b', '1 2&'], ['☃', '%'], ['c', 'foo']);
  my $query_hash = {c => [42, 'foo'], b => '1 2&', '☃' => '%'};
  local $ENV{QUERY_STRING} = $query_string;
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($params, $pairs, $param_snowman, $param_c_array);
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $params = $cgi->query_params;
    $pairs = $cgi->query_pairs;
    $param_snowman = $cgi->query_param('☃');
    $param_c_array = $cgi->query_param_array('c');
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $params, $query_hash, 'right query params';
  is_deeply $pairs, \@query_pairs, 'right query pairs';
  is $param_snowman, '%', 'right query param value';
  is_deeply $param_c_array, $query_hash->{c}, 'right query param values array';
};

subtest 'Body parameters' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_string = 'c=42&b=1+2%26&%E2%98%83=%25&c=foo';
  my $body_hash = {c => [42, 'foo'], b => '1 2&', '☃' => '%'};
  my @body_pairs = (['c', 42], ['b', '1 2&'], ['☃', '%'], ['c', 'foo']);
  local $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($params, $pairs, $param_snowman, $param_c_array);
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $params = $cgi->body_params;
    $pairs = $cgi->body_pairs;
    $param_snowman = $cgi->body_param('☃');
    $param_c_array = $cgi->body_param_array('c');
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $params, $body_hash, 'right body params';
  is_deeply $pairs, \@body_pairs, 'right body pairs';
  is $param_snowman, '%', 'right body param value';
  is_deeply $param_c_array, $body_hash->{c}, 'right body param values array';
};

subtest 'Body JSON' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_hash = {c => [42, 'foo'], b => '1 2&', '☃' => '%'};
  my $body_string = encode_json $body_hash;
  local $ENV{CONTENT_TYPE} = 'application/json;charset=UTF-8';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($json_data);
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $json_data = $cgi->body_json;
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $json_data, $body_hash, 'right body JSON';
};

subtest 'Request meta-variables and headers' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{AUTH_TYPE} = 'Basic';
  my $text = 'abcde';
  local $ENV{CONTENT_LENGTH} = length $text;
  local $ENV{CONTENT_TYPE} = 'text/plain;charset=UTF-8';
  local $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
  local $ENV{PATH_INFO} = '/foo';
  local $ENV{PATH_TRANSLATED} = '/path/to/foo';
  local $ENV{QUERY_STRING} = 'foo=bar';
  local $ENV{REMOTE_ADDR} = '127.0.0.1';
  local $ENV{REMOTE_HOST} = 'localhost';
  local $ENV{REMOTE_IDENT} = 'somebody';
  local $ENV{REMOTE_USER} = 'user';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/test.cgi';
  local $ENV{SERVER_NAME} = 'localhost';
  local $ENV{SERVER_PORT} = '80';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  local $ENV{SERVER_SOFTWARE} = "CGI::Tiny/$CGI::Tiny::VERSION";
  my $auth_str = encode_base64 'user:password', '';
  local $ENV{HTTP_AUTHORIZATION} = "Basic $auth_str";
  local $ENV{HTTP_CONTENT_LENGTH} = length $text;
  local $ENV{HTTP_CONTENT_TYPE} = 'text/plain;charset=UTF-8';
  open my $in_fh, '<', \$text or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($headers, $auth_header, $content_length_header, %vars);
  cgi {
    my ($cgi) = @_;
    $cgi->set_input_handle($in_fh);
    $cgi->set_output_handle($out_fh);
    $vars{$_} = $cgi->$_ for (map { lc } @env_keys), qw(method path query);
    $headers = $cgi->headers;
    $auth_header = $cgi->header('Authorization');
    $content_length_header = $cgi->header('Content-Length');
    $cgi->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $vars{auth_type}, 'Basic', 'right AUTH_TYPE';
  is $vars{content_length}, length($text), 'right CONTENT_LENGTH';
  is $vars{content_type}, 'text/plain;charset=UTF-8', 'right CONTENT_TYPE';
  is $vars{gateway_interface}, 'CGI/1.1', 'right GATEWAY_INTERFACE';
  is $vars{path_info}, '/foo', 'right PATH_INFO';
  is $vars{path_translated}, '/path/to/foo', 'right PATH_TRANSLATED';
  is $vars{query_string}, 'foo=bar', 'right QUERY_STRING';
  is $vars{remote_addr}, '127.0.0.1', 'right REMOTE_ADDR';
  is $vars{remote_host}, 'localhost', 'right REMOTE_HOST';
  is $vars{remote_ident}, 'somebody', 'right REMOTE_IDENT';
  is $vars{remote_user}, 'user', 'right REMOTE_USER';
  is $vars{request_method}, 'GET', 'right REQUEST_METHOD';
  is $vars{script_name}, '/test.cgi', 'right SCRIPT_NAME';
  is $vars{server_name}, 'localhost', 'right SERVER_NAME';
  is $vars{server_port}, '80', 'right SERVER_PORT';
  is $vars{server_protocol}, 'HTTP/1.0', 'right SERVER_PROTOCOL';
  is $vars{server_software}, "CGI::Tiny/$CGI::Tiny::VERSION", 'right SERVER_SOFTWARE';
  is $vars{method}, 'GET', 'right method';
  is $vars{path}, '/foo', 'right path';
  is $vars{query}, 'foo=bar', 'right query';
  is $headers->{authorization}, "Basic $auth_str", 'right Authorization header';
  is $headers->{'content-length'}, length($text), 'right Content-Length header';
  is $headers->{'content-type'}, 'text/plain;charset=UTF-8', 'right Content-Type header';
  is $auth_header, "Basic $auth_str", 'right Authorization header';
  is $content_length_header, length($text), 'right Content-Length header';
};

done_testing;
