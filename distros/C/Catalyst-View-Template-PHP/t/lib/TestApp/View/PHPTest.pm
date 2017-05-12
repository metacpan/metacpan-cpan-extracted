package TestApp::View::PHPTest;
use Moose;
use namespace::autoclean;
extends 'Catalyst::View::Template::PHP';

# used in preprocess 
our %phptest_globals;

# used in header_callback
our @headers;
our $capture_all_headers;
our $first_header;
our $last_header;

# used in postprocess
our $postprocessor;

sub header_callback {
    my ($self, $c, $header, $replace) = @_;
    $self->SUPER::header_callback( $c, $header, $replace );
    if ($header =~ /^X-compute:/) {
	$self->process_compute_header($c,$header);
    } elsif ($header =~ /^X-/ || $capture_all_headers) {
	unshift @headers, $header;
	$last_header = $header;
	$first_header ||= $header;
    }
}

# Normal operation is to start request in Catalyst (Perl),
# invoke a script to do some work in PHP, and then finalize the
# request in Catalyst (Perl) again.
#
# But what if you want to use Perl in the middle of your PHP processing?
# This class and method suggest a way to do it: pass data from PHP to
# Perl using PHP's  header()  function and  Catalyst::View::Template::PHP's
# header_callback()  method, process the request in Perl, and call
# PHP::assign_global(...)  to pass the result back to PHP.
#
sub process_compute_header {
    use JSON;
    my ($self, $c, $payload) = @_;
    $payload =~ s/.*?://;

    print STDERR "process_compute requested; JSON=$payload\n";

    $payload = eval { decode_json($payload) };
    if ($@) {
	PHP::assign_global("Perl_compute_result", $@);
	return;
    }
    my $expr = $payload->{expr};
    my $output = $payload->{output} // 'Perl_compute_result';

    print STDERR "expr is $expr, output to \$$output\n";

    my $result = eval $expr;
    if ($@) {
	PHP::assign_global($output, $@);
	return;
    }
    PHP::assign_global($output, $result);
}

sub preprocess {
    my ($self, $c, $params) = @_;

    if (%phptest_globals) {
	while (my ($k,$v) = each %phptest_globals) {
	    $params->{$k} = $v;
	}
	%phptest_globals = ();
    }
    return $params;
}

sub postprocess {
    my ($self, $c, $output) = @_;
    if ($postprocessor) {
	$output = $postprocessor->($output);
    }
    return $output;
}

sub set_callback {
    my ($hook, $function) = @_;
    PHP::options( $hook, $function );
}


1;

__END__

stuff that Catalyst::View::Template::PHP is supposed to do
that we ought to test:

    call __PACKAGE__->config->{...} = ...
    to set a PHP option

_X_ override preprocess

_X_ override postprocess

_X_ set $c->stash->{template}, $c->forward( 'TestApp::View::PHP' )
    to get some script to do something

_X_ make requests that we expect to set $_GET

_X_ make requests that we expect to set $_POST

_X_ make requests that we expect to set $_REQUEST

_X_ make requests that we expect to set $_SERVER

_X_ make requests that we expect to set $_ENV

    make requests that we expect to set $_COOKIE

_X_ make requests that we expect to set $_FILES

_X_ call move_uploaded_file or read_uploaded_file

_X_ header callbacks

_X_ redirect

    override finalize

    handle_warnings

    handle_error

    include_path  config

    debug  config

    different PHP directives -- request_order, variables_order,
        file_uploads, upload_max_filesize, upload_tmp_dir,
        post_max_size, max_input_time





