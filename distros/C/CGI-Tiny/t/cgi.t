use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Test::More;
use Encode 'decode', 'encode';
use File::Temp;
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
  my ($response, $nph) = @_;
  my ($headers_str, $body) = split /\r\n\r\n/, $response, 2;
  my (%headers, $start_line, $response_status);
  foreach my $header (split /\r\n/, $headers_str) {
    if ($nph and !defined $start_line) {
      $start_line = $header;
      ($response_status) = $start_line =~ m/^\S+\s+([0-9]+.*)$/;
      next;
    }
    my ($name, $value) = split /:\s*/, $header, 2;
    $response_status = $value if !$nph and lc $name eq 'status';
    push @{$headers{lc $name}}, $value;
  }
  $_ = $_->[0] for grep { @$_ == 1 } values %headers;
  $response_status = '200 OK' if !$nph and !defined $response_status;
  return {start_line => $start_line, headers => \%headers, body => $body, status => $response_status};
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  ok defined($response->{headers}{date}), 'Date set';
  ok defined(CGI::Tiny::date_to_epoch $response->{headers}{date}), 'valid HTTP date';
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

  my ($error, $code);
  cgi {
    $_->set_error_handler(sub { $error = $_[1]; $code = $_[0]->response_status_code });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
  };

  ok defined($error), 'error logged';
  is $code, 500, '500 response status code';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'No render (custom response status)' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($error, $code);
  cgi {
    $_->set_error_handler(sub { $error = $_[1]; $code = $_[0]->response_status_code });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_response_status(403);
  };

  ok defined($error), 'error logged';
  is $code, 403, '403 response status code';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^403\b/, '403 response status';
};

subtest 'No render (object lost)' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  cgi {
    $_->set_error_handler(sub { $error = $_[1] });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    undef $_;
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'No render (object not destroyed)' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  my $persist_cgi;
  cgi {
    $_->set_error_handler(sub { $error = $_[1] });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $persist_cgi = $_;
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'No render (premature exit)' => sub {
  my $outfile = File::Temp->new;
  my $errfile = File::Temp->new;
  my $pid = fork;
  plan skip_all => "fork failed: $!" unless defined $pid;
  unless ($pid) {
    local @ENV{@env_keys} = ('')x@env_keys;
    local $ENV{PATH_INFO} = '/';
    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{SCRIPT_NAME} = '/';
    local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
    open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";

    cgi {
      $_->set_error_handler(sub { print $errfile $_[1] });
      $_->set_input_handle($in_fh);
      $_->set_output_handle($outfile);
      exit;
    };
    exit;
  }
  waitpid $pid, 0;

  seek $errfile, 0, 0;
  my $error = do { local $/; readline $errfile };
  ok length($error), 'error logged';
  seek $outfile, 0, 0;
  my $out_data = do { local $/; readline $outfile };
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^5[0-9]{2}\b/, '500 response status';
};

subtest 'No render (premature exit with persistent object)' => sub {
  my $outfile = File::Temp->new;
  my $errfile = File::Temp->new;
  my $pid = fork;
  plan skip_all => "fork failed: $!" unless defined $pid;
  unless ($pid) {
    local @ENV{@env_keys} = ('')x@env_keys;
    local $ENV{PATH_INFO} = '/';
    local $ENV{REQUEST_METHOD} = 'GET';
    local $ENV{SCRIPT_NAME} = '/';
    local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
    open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";

    my $persist_cgi;
    cgi {
      $_->set_error_handler(sub { print $errfile $_[1] });
      $_->set_input_handle($in_fh);
      $_->set_output_handle($outfile);
      $persist_cgi = $_;
      exit;
    };
    exit;
  }
  waitpid $pid, 0;

  seek $errfile, 0, 0;
  my $error = do { local $/; readline $errfile };
  ok length($error), 'error logged';
  seek $outfile, 0, 0;
  my $out_data = do { local $/; readline $outfile };
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

  my ($error, $headers_rendered, $code);
  cgi {
    $_->set_error_handler(sub { $error = $_[1]; $headers_rendered = $_[0]->headers_rendered; $code = $_[0]->response_status_code });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    die 'Error 42';
  };

  ok defined($error), 'error logged';
  like $error, qr/Error 42/, 'right error';
  ok !$headers_rendered, 'headers were not rendered';
  is $code, 500, '500 response status code';
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
    $_->set_error_handler(sub { $error = $_[1]; $headers_rendered = $_[0]->headers_rendered; });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render;
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

  my ($error, $code);
  cgi {
    $_->set_error_handler(sub { $error = $_[1]; $code = $_[0]->response_status_code });
    $_->set_request_body_limit(100);
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    my $body = $_->body;
    $_->render(data => $body);
  };

  ok defined($error), 'error logged';
  is $code, 413, '413 response status code';
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_response_status(404);
    $_->render(text => '');
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(data => $data);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $response->{body}, $data, 'right response body';
};

subtest 'File response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $data = "\x01\x02\x03\x04\r\n\xFF";
  my $tempdir = File::Temp->newdir;
  my $filepath = "$tempdir/test.dat";
  open my $fh, '>', $filepath or die "Failed to open $filepath for writing: $!";
  binmode $fh;
  print $fh $data;
  close $fh;

  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(file => $filepath);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $response->{body}, $data, 'right response body';
};

subtest 'File response (download)' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $data = "\x01\x02\x03\x04\r\n\xFF";
  my $tempdir = File::Temp->newdir;
  my $filepath = "$tempdir/test.dat";
  open my $fh, '>', $filepath or die "Failed to open $filepath for writing: $!";
  binmode $fh;
  print $fh $data;
  close $fh;

  my $filename = '"test☃".dat';
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_response_download($filename);
    $_->render(file => $filepath);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  is $response->{headers}{'content-disposition'},
    'attachment; filename="\"test?\".dat"; filename*=UTF-8\'\'%22test%E2%98%83%22.dat', 'right content disposition';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $response->{body}, $data, 'right response body';
};

subtest 'Filehandle response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $data = "\x01\x02\x03\x04\r\n\xFF";
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    open my $fh, '<', \$data or die "Failed to open scalar data handle: $!";
    $_->render(handle => $fh);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(text => $text);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_response_charset('UTF-16LE');
    $_->render(text => $text);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(html => $html);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(xml => $xml);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(json => $ref);
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->render(redirect => $url);
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok !defined($response->{headers}{'content-type'}), 'Content-Type not set';
  is $response->{headers}{location}, $url, 'Location set';
  like $response->{status}, qr/^302\b/, '302 response status';
  ok defined($response->{headers}{date}), 'Date set';
  ok defined(CGI::Tiny::date_to_epoch $response->{headers}{date}), 'valid HTTP date';
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
  my @cookies = (
    ['foo', 'bar', Domain => 'example.com', HttpOnly => 1, 'Max-Age' => 3600, Path => '/test', SameSite => 'Strict', Secure => 1],
    ['x', '', Expires => 'Sun, 06 Nov 1994 08:49:37 GMT', HttpOnly => 0, SameSite => 'Lax', Secure => 0],
  );
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    foreach my $header (@headers) { $_->add_response_header(@$header) }
    foreach my $cookie (@cookies) { $_->add_response_cookie(@$cookie) }
    $_->set_response_content_type('image/gif');
    $_->set_response_status(202);
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'image/gif', 'right content type';
  like $response->{status}, qr/^202\b/, '202 response status';
  is_deeply $response->{headers}{'x-test'}, ['some value', 'another value'], 'right custom headers';
  is_deeply $response->{headers}{'set-cookie'},
    ['foo=bar; Domain=example.com; HttpOnly; Max-Age=3600; Path=/test; SameSite=Strict; Secure',
     'x=; Expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Lax'], 'right Set-Cookie headers';
};

subtest 'Query parameters' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  my $query_string = 'c=42&b=1+2%26&%E2%98%83=%25&c=foo';
  my @query_pairs = (['c', 42], ['b', '1 2&'], ['☃', '%'], ['c', 'foo']);
  local $ENV{QUERY_STRING} = $query_string;
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($params, $param_names, $param_snowman, $param_c_array);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $params = $_->query_params;
    $param_names = $_->query_param_names;
    $param_snowman = $_->query_param('☃');
    $param_c_array = $_->query_param_array('c');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $params, \@query_pairs, 'right query pairs';
  is_deeply $param_names, ['c', 'b', '☃'], 'right query param names';
  is $param_snowman, '%', 'right query param value';
  is_deeply $param_c_array, [42, 'foo'], 'right query param values array';
};

subtest 'Body parameters' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_string = 'c=42&b=1+2%26&%E2%98%83=%25&c=foo';
  my @body_pairs = (['c', 42], ['b', '1 2&'], ['☃', '%'], ['c', 'foo']);
  local $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($params, $param_names, $param_snowman, $param_c_array);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $params = $_->body_params;
    $param_names = $_->body_param_names;
    $param_snowman = $_->body_param('☃');
    $param_c_array = $_->body_param_array('c');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $params, \@body_pairs, 'right body pairs';
  is_deeply $param_names, ['c', 'b', '☃'], 'right body param names';
  is $param_snowman, '%', 'right body param value';
  is_deeply $param_c_array, [42, 'foo'], 'right body param values array';
};

subtest 'Multipart body' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $utf8_snowman = encode 'UTF-8', '☃';
  my $utf16le_snowman = encode 'UTF-16LE', "☃...\n";
  my $body_string = <<"EOB";
preamble\r
--delimiter\r
Content-Disposition: form-data; name="snowman"\r
\r
$utf8_snowman!\r
--delimiter\r
Content-Disposition: form-data; name=snowman\r
Content-Type: text/plain;charset=UTF-16LE\r
\r
$utf16le_snowman\r
--delimiter\r
Content-Disposition: form-data; name="newline\\\\\\""\r
\r

\r
--delimiter\r
Content-Disposition: form-data; name="empty"\r
\r
--delimiter\r
Content-Disposition: form-data; name="empty"\r
\r
\r
--delimiter\r
Content-Disposition: form-data; name="file"; filename="test.dat"\r
Content-Type: application/octet-stream\r
\r
00000000
11111111\0\r
--delimiter\r
Content-Disposition: form-data; name="file"; filename="test2.dat"\r
Content-Type: application/json\r
\r
{"test":42}\r
--delimiter\r
Content-Disposition: form-data; name="snowman"; filename="snowman\\\\\\".txt"\r
Content-Type: text/plain;charset=UTF-16LE\r
\r
$utf16le_snowman\r
--delimiter--\r
postamble
EOB
  local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary=delimiter';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $parts;
  my ($params, $param_names, $param_snowman, $param_snowman_array);
  my ($uploads, $upload_names, $upload_file, $upload_file_array);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_multipart_form_charset('UTF-8');
    $parts = $_->body_parts;
    $params = $_->body_params;
    $param_names = $_->body_param_names;
    $param_snowman = $_->body_param('snowman');
    $param_snowman_array = $_->body_param_array('snowman');
    $uploads = $_->uploads;
    $upload_names = $_->upload_names;
    $upload_file = $_->upload('file');
    $upload_file_array = $_->upload_array('file');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman},
  ], 'right multipart body parts';

  is_deeply $params, [['snowman', '☃!'], ['snowman', "☃...\n"], ['newline\"', "\n"], ['empty', ''], ['empty', '']], 'right multipart body params';
  is_deeply $param_names, ['snowman', 'newline\"', 'empty'], 'right multipart body param names';
  is $param_snowman, "☃...\n", 'right multipart body param value';
  is_deeply $param_snowman_array, ['☃!', "☃...\n"], 'right multipart body param values';
  is $uploads->[-1][0], 'snowman', 'right upload name';
  my $upload_snowman = $uploads->[-1][1];
  ok defined $upload_snowman, 'last upload';
  is $upload_snowman->{filename}, 'snowman\".txt', 'right upload filename';
  is $upload_snowman->{size}, length $utf16le_snowman, 'right upload size';
  is $upload_snowman->{content_type}, 'text/plain;charset=UTF-16LE', 'right upload Content-Type';
  is do { local $/; seek $upload_snowman->{file}, 0, 0; scalar readline $upload_snowman->{file} }, $utf16le_snowman, 'right upload contents';
  is_deeply $upload_names, ['file', 'snowman'], 'right upload names';
  is $upload_file->{filename}, 'test2.dat', 'right upload filename';
  is $upload_file->{content_type}, 'application/json', 'right upload Content-Type';
  is $upload_file_array->[0]{filename}, 'test.dat', 'right upload filename';
  is $upload_file_array->[1]{filename}, 'test2.dat', 'right upload filename';
};

subtest 'Multipart body read into memory' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $utf8_snowman = encode 'UTF-8', '☃!';
  my $body_string = <<"EOB";
--fffff\r
Content-Disposition: form-data; name="snowman\\\\"\r
\r
$utf8_snowman\r
--fffff\r
Content-Disposition: form-data; name="file"; filename="test.txt\\\\"\r
Content-Type: text/plain;charset=UTF-8\r
\r
$utf8_snowman
\r
--fffff--\r
EOB
  local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary=fffff';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($body, $parts, $params, $param_names, $param_snowman, $uploads, $upload_names, $upload_snowman);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $body = $_->body;
    $parts = $_->body_parts;
    $params = $_->body_params;
    $param_names = $_->body_param_names;
    $param_snowman = $_->body_param('snowman\\');
    $uploads = $_->uploads;
    $upload_names = $_->upload_names;
    $upload_snowman = $_->upload('file');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is $body, $body_string, 'right body content bytes';

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman\\\\"'},
      name => 'snowman\\', filename => undef, size => length($utf8_snowman), content => $utf8_snowman},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.txt\\\\"', 'content-type' => 'text/plain;charset=UTF-8'},
      name => 'file', filename => 'test.txt\\', size => length($utf8_snowman) + 1, file_contents => "$utf8_snowman\n"},
  ], 'right multipart body parts';

  is_deeply $params, [['snowman\\', '☃!']], 'right multipart body params';
  is_deeply $param_names, ['snowman\\'], 'right multipart body param names';
  is $param_snowman, '☃!', 'right multipart body param value';
  is $uploads->[0][0], 'file', 'right upload name';
  is_deeply $upload_names, ['file'], 'right upload names';
  is $upload_snowman->{filename}, 'test.txt\\', 'right upload filename';
  is $upload_snowman->{content_type}, 'text/plain;charset=UTF-8', 'right upload Content-Type';
};

subtest 'Empty multipart body' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_string = <<"EOB";
preamble\r
\r
-------\r
\r
postamble\r
-----\r
Content-Disposition: should-be-ignored\r
\r
\r
-------\r
EOB
  local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary="---"';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($parts, $params, $param_names, $uploads, $upload_names);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $parts = $_->body_parts;
    $params = $_->body_params;
    $param_names = $_->body_param_names;
    $uploads = $_->uploads;
    $upload_names = $_->upload_names;
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $parts, [], 'no multipart body parts';
  is_deeply $params, [], 'no multipart body params';
  is_deeply $param_names, [], 'no multipart body param names';
  is_deeply $uploads, [], 'no uploads';
  is_deeply $upload_names, [], 'no upload names';
};

subtest 'Malformed multipart body' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_string = <<"EOB";
--fribble\r
not a header\r
\r
--fribble--\r
EOB
  local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary="fribble"';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  cgi {
    $_->set_error_handler(sub { $error = $_[1] });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->body_parts;
    $_->render;
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^400\b/, '400 response status';
};

subtest 'Unterminated multipart body' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  my $body_string = <<"EOB";
--fribble\r
\r
\r
--fribble\r
EOB
  local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary="fribble"';
  local $ENV{CONTENT_LENGTH} = length $body_string;
  open my $in_fh, '<', \$body_string or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my $error;
  cgi {
    $_->set_error_handler(sub { $error = $_[1] });
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->body_parts;
    $_->render;
  };

  ok defined($error), 'error logged';
  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^400\b/, '400 response status';
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $json_data = $_->body_json;
    $_->render;
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
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    foreach my $key ((map { lc } @env_keys), qw(method path query)) { $vars{$key} = $_->$key }
    $headers = $_->headers;
    $auth_header = $_->header('Authorization');
    $content_length_header = $_->header('Content-Length');
    $_->render;
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

subtest 'Cookies' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  local $ENV{HTTP_COOKIE} = 'a=b; c=42; x=; a=c';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  my ($cookies, $cookie_names, $a_cookie, $a_cookies, $b_cookie);
  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $cookies = $_->cookies;
    $cookie_names = $_->cookie_names;
    $a_cookie = $_->cookie('a');
    $a_cookies = $_->cookie_array('a');
    $b_cookie = $_->cookie('b');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data);
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  like $response->{status}, qr/^200\b/, '200 response status';
  is_deeply $cookies, [['a', 'b'], ['c', 42], ['x', ''], ['a', 'c']], 'right cookies';
  is_deeply $cookie_names, ['a', 'c', 'x'], 'right cookie names';
  is $a_cookie, 'c', 'right cookie value';
  is_deeply $a_cookies, ['b', 'c'], 'right cookie values';
  ok !defined $b_cookie, 'no cookie value';
};

subtest 'NPH response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  local $ENV{SERVER_SOFTWARE} = "CGI::Tiny/$CGI::Tiny::VERSION";
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_nph(1);
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data, 1);
  like $response->{start_line}, qr/^HTTP\/1.0\b/, 'right start line';
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'application/octet-stream', 'right content type';
  is $response->{headers}{server}, "CGI::Tiny/$CGI::Tiny::VERSION", 'right Server header';
  like $response->{status}, qr/^200\b/, '200 response status';
  ok defined($response->{headers}{date}), 'Date set';
  ok defined(CGI::Tiny::date_to_epoch $response->{headers}{date}), 'valid HTTP date';
  ok !length($response->{body}), 'empty response body';
};

subtest 'NPH error response' => sub {
  local @ENV{@env_keys} = ('')x@env_keys;
  local $ENV{PATH_INFO} = '/';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{SCRIPT_NAME} = '/';
  local $ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
  open my $in_fh, '<', \(my $in_data = '') or die "failed to open handle for input: $!";
  open my $out_fh, '>', \my $out_data or die "failed to open handle for output: $!";

  cgi {
    $_->set_input_handle($in_fh);
    $_->set_output_handle($out_fh);
    $_->set_nph(1);
    $_->set_response_status(404);
    $_->set_response_content_type('text/plain');
    $_->render;
  };

  ok length($out_data), 'response rendered';
  my $response = _parse_response($out_data, 1);
  like $response->{start_line}, qr/^HTTP\/1.0\b/, 'right start line';
  ok defined($response->{headers}{'content-type'}), 'Content-Type set';
  is $response->{headers}{'content-type'}, 'text/plain', 'right content type';
  like $response->{status}, qr/^404\b/, '404 response status';
  ok !length($response->{body}), 'empty response body';
};

done_testing;
