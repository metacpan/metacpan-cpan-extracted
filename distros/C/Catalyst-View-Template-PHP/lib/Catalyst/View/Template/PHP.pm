package Catalyst::View::Template::PHP;

use 5.012;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use PHP 0.14;
use Scalar::Util 'reftype';

extends 'Catalyst::View';

our $VERSION = '0.04';
our $PROCESSED = 0;

sub new {
    my $pkg = shift;
    my $self = bless { @_ }, $pkg;
    $self->{php_version} = PHP::options('version');
    return $self;
}

sub process {
    my ( $self, $c ) = @_;
    my $orig_cwd = Cwd::getcwd();
    my $template = $c->stash->{template} || $c->request->match;
    my $DEBUG = $c->config->{'Template::PHP'}{debug};
    if (!$template) {
	$c->log->warn("No template specified for processing in "
		      . "Catalyst::View::Template::PHP");
	return 0;
    }
    PHP::__reset() if $PROCESSED++;
    if ($c->stash->{template_dir}) {
	# chdir $c->stash->{template_dir};
	# let's just chdir inside the PHP interpreter ?
	PHP::call('chdir', $c->stash->{template_dir});
	$c->log->debug("chdir template dir " . $c->stash->{template_dir}) if $DEBUG;
    }
    $c->log->debug("Rendering template '$template'") if $DEBUG;




    # prepare global variables for the PHP interpreter
    my $variables_order = PHP::eval_return( "ini_get('variables_order')" );
    my $cookie_params = { };
    my $params = {
	%{ $c->stash },
	c => $c
    };

    if ($variables_order =~ /S/) {
	$params->{_SERVER} = $self->_server_params( $c );
	$params->{_ENV} = { %ENV };
    } elsif ($variables_order =~ /E/) {
	$params->{_ENV} = { %ENV };
    }
    if ($variables_order =~ /C/) {
	$cookie_params = $self->_cookie_params( $c );
	$params->{_COOKIE} = $cookie_params;
    }

    $params->{_FILES} = $self->_process_uploads( $c );

    $self->_set_method_params( $c, $params, $variables_order );

    if (ref($c->req->body) eq 'File::Temp') {
	my $input = join q//, readline($c->req->body);
	if (length($input)) {
	    my $len = length($input);
	    PHP::set_php_input($input);
	    $params->{HTTP_RAW_POST_DATA} = $input;
	    if ($DEBUG) {
		if ($len < 500) {
		    $c->log->debug( "Set \$HTTP_RAW_POST_DATA:", $input );
		} else {
		    $c->log->debug( "Set \$HTTP_RAW_POST_DATA, $len bytes" );
		}
	    }
	}
    }

    $params = $self->preprocess( $c, $params );



    while (my ($param_key, $param_value) = each %$params) {
	PHP::assign_global( $param_key, $param_value );
    }
    if ($DEBUG) {
	use Data::Dumper;
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Sortkeys = 1;
	$c->log->debug("Parameters to make into global PHP variables:",
		       Data::Dumper::Dumper($params));
    }
    $c->stash->{php_params} = $params;




    # include path
    my @include_path;
    if ($c->stash->{php_include_path}) {
	@include_path = ($c->stash->{include_path});
    } elsif ($c->config->{'Template::PHP'}{include_path}) {
	@include_path = split /\s+/, 
			    $c->config->{'Template::PHP'}{include_path};
    }
    if (!@include_path) {
	@include_path = ($c->config->{root},
			 $c->config->{root} . '/templates',
			 $c->config->{root} . '/php',
			 # . included by default sometime after v5.1.6?
			 '.');
    }
    PHP::call( 'set_include_path', join (':', @include_path) );
    if ($DEBUG) {
	$c->log->debug("include path for PHP: "
		       . join ' : ', @include_path );
    }




    # set up PHP module callbacks
    my $OUTPUT = '';
    PHP::options( stdout => sub { $OUTPUT .= $_[0] } );
    PHP::options( stderr => sub { $self->handle_warning($c, $_[0]) } );
    PHP::options( header => sub { $self->header_callback($c, $_[0], $_[1]) } );
    $self->{_headers} = [];
    if ($DEBUG) {
	$c->log->debug(scalar localtime . " ... processing '$template' ...");
    }




    # invoke PHP
    eval { PHP::include( $template ) };
    chdir $orig_cwd;
    $self->{_status} = 200;
    if ($@) {
	$self->handle_error( $c, $template, $@ );
    }




    $OUTPUT = $self->postprocess( $c, $OUTPUT );
    if ($DEBUG) {
	$c->log->debug("Output from PHP processing of '$template':",
		       $OUTPUT);
    }



    # handle redirect?
    my @redirect = grep { /^Location:\s/ } map { $_->[0] } @{$self->{_headers}};
    if (@redirect) {
	$c->log->debug("Redirect header(s) received: @redirect") if $DEBUG;
	if ($self->{_status} < 300 || $self->{_status} >= 400) {
	    $self->{_status} = 302;
	}
	my $location = $redirect[0];
	$location =~ s/^\S+:\s+//;
	if ($self->on_redirect($c, $location, $self->{_status})) {

	    foreach my $headerref ( @{$self->{_headers}} ) {
		my ($header, $replace) = @$headerref;
		next if $header =~ /^Location:\s/;
		if ($replace) {
		    $c->response->headers->header(split /:\s+/, $header, 2);
		} else {
		    $c->response->headers->push_header(split(/:\s+/, $header, 2));
		}
	    }


	    if ($DEBUG) {
		$c->log->debug("View::Template::PHP: redirecting to $location");
		use Data::Dumper;
		local $Data::Dumper::Indent = 1;
		local $Data::Dumper::Sortkeys = 1;
		$c->log->debug("RESPONSE HEADERS: " .
			       Data::Dumper::Dumper($c->response->headers));
	    }

	    $c->response->redirect( $location, $self->{_status} );
	    $c->detach;
	    return;
	}
    }
    return $self->finalize( $c, $OUTPUT );
}

sub handle_warning {
    my ($self, $c, $message) = @_;
    $c->log->warn("PHP warning: $message");
}

sub handle_error {
    my ($self, $c, $template, $eval_error) = @_;
    $c->log->warn("error processing '$template': $@");
    # $self->{_status} = 500 ??
    return;
}

sub _cookie_params {
    my ( $self, $c ) = @_;
    my $p = { map { ($_ => $c->req->cookies->{$_}{value}[0]) 
	      } keys  %{ $c->req->cookies } };
    return $p;
}

sub _server_params {
    my ( $self, $c ) = @_;
    my $p = $c->engine->{env} // $c->request->{env};
    return $p;
}

sub _php_method_params {
    my ($existing_params, @order) = @_;

    # The conventional ways to parse input parameters with Perl (CGI/Catalyst)
    # are different from the way that PHP parses the input. Some examples:
    #
    # 1. foo=first&foo=second&foo=lats
    #
    #    In Perl, value for the parameter 'foo' is an array ref with 3 values
    #    In PHP, value for param 'foo' is 'last', whatever the last value was
    #    See also example #5
    #
    # 2. foo[bar]=value1&foo[baz]=value2
    #
    #    In Perl, this creates scalar parameters 'foo[bar]' and 'foo[baz]'
    #    In PHP, this creates the parameter 'foo' with an associative array
    #            value ('bar'=>'value1', 'baz'=>'value2')
    #
    # 3. foo[bar]=value1&foo=value2&foo[baz]=value3
    #
    #    In Perl, this creates parameters 'foo[bar]', 'foo', and 'foo[baz]'
    #    In PHP, this create the parameter 'foo' with an associative array
    #            with value ('baz'=>'value3'). The values associated with
    #            'foo[bar]' and 'foo' are lost.
    #
    # 4. foo[2][bar]=value1&foo[2][baz]=value2
    #
    #    In Perl, this creates parameters 'foo[2][bar]' and 'foo[2][baz]'
    #    In PHP, this creates a 2-level hash 'foo'
    #
    # 5. foo[]=123&foo[]=234&foo[]=345
    #    In Perl, parameter 'foo[]' assigned to array ref [123,234,345]
    #    In PHP, parameter 'foo' is an array with elem (123,234,345)
    #
    # For a given set of Perl-parsed parameter input, this function returns
    # a hashref that resembles what the same parameters would look like
    # to PHP.

    my $new_params = {};
    foreach my $pp (@order) {
	my $p = $pp;
	if ($p =~ s/\[(.+)\]$//) {
	    my $key = $1;
	    s/%(..)/chr hex $1/ge for $p, $pp, $key;

	    if ($key ne '' && $new_params->{$p}
		    && ref($new_params->{$p} ne 'HASH')) {
		$new_params->{$p} = {};
	    }

	    # XXX - how to generalize this from 2 to n level deep hash?
	    if ($key =~ /\]\[/) {
		my ($key1, $key2) = split /\]\[/, $key;
		$new_params->{$p}{$key1}{$key2} = $existing_params->{$pp};
	    } else {
		$new_params->{$p}{$key} = $existing_params->{$pp};
	    }
	} elsif ($p =~ s/\[\]$//) {
	    # expect $existing_params->{$pp} to already be an array ref
	    $p =~ s/%(..)/chr hex $1/ge;
	    $new_params->{$p} = $existing_params->{$pp};
	} else {
	    $p =~ s/%(..)/chr hex $1/ge;
	    $new_params->{$p} = $existing_params->{$p};
	    if ('ARRAY' eq ref $new_params->{$p}) {
		$new_params->{$p} = $new_params->{$p}[-1];
	    }
	}
    }
    return $new_params;
}

sub _set_method_params {
    my ( $self, $c, $params, $var_order ) = @_;
    my $order = PHP::eval_return( 'ini_get("request_order")' ) || $var_order;
    $params->{$_} = {} for qw(_GET _POST _REQUEST);

    if ($var_order =~ /G/) {
	my $query = $c->request->{uri} &&  $c->request->{uri}->query;
	if ($query) {
	    $query =~ s/%(5[BD])/chr hex $1/gie;
	    my @order = map { s/=.*//; $_ } split /&/, $query;
	    $params->{_GET} = _php_method_params(
		 $c->request->query_parameters, @order );
	}
    }
    if ($var_order =~ /P/ && $c->request->method eq 'POST') {
	my $order = eval {
	    $c->req->body->{param_order} // []
	} // [ keys %{$c->req->body_parameters} ];
	$params->{_POST} = _php_method_params(
		$c->request->body_parameters, @$order );
    }

    $params->{_REQUEST} = {};
    foreach my $reqvar (split //, uc $order) {
	if ($reqvar eq 'C') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_COOKIE}} };
	} elsif ($reqvar eq 'G') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_GET}} };
	} elsif ($reqvar eq 'P') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_POST}} };
	}
    }
    return;
}

sub _process_uploads {
    my ( $self, $c ) = @_;
    my $uploads = $c->request->uploads // '';
    my $_files = { };
    if (ref($uploads) eq 'HASH') {
	foreach my $key (keys %$uploads) {
	    if ($key =~ s/\[\]$//) {
		# PHP array format for multiple uploads
		for my $files_param (qw(name type tmp_name size error)) {
		    $_files->{$key}{$files_param} //= [];
		}
		my $upload = $c->request->uploads->{$key . '[]'};
		if (ref($upload) ne 'ARRAY') {
		    $upload = [ $upload ];
		}
		foreach my $up (@$upload) {
		    push @{$_files->{$key}{name}}, $up->filename;
		    push @{$_files->{$key}{type}}, $up->type;
		    push @{$_files->{$key}{tmp_name}}, $up->tempname;
		    PHP::_spoof_rfc1867( $up->tempname || "" );
		    push @{$_files->{$key}{size}}, $up->size;
		    push @{$_files->{$key}{error}}, 0;
		}

	    } else {
		my $upload = $c->request->uploads->{$key};
		$_files->{$key} = {
		    name => $upload->filename,
		    type => $upload->type,
		    tmp_name => $upload->tempname,
		    size => $upload->size,
		    error => 0
		};
		PHP::_spoof_rfc1867( $upload->tempname || "" );
	    }
	}
    }
    return $_files;
}

sub preprocess {
    my ( $self, $c, $params ) = @_;
    return $params;
}

sub postprocess {
    my ( $self, $c, $output ) = @_;
    return $output;
}

sub header_callback {
    my ($self, $c, $header, $replace) = @_;
    push @{$self->{_headers}}, [ $header, $replace || 0 ];	   
}

sub on_redirect {
    my ($self, $c, $location, $status) = @_;
    return 1;
}

sub _set_response_headers {
    my ($self, $c) = @_;

    foreach my $headerref (@{$self->{_headers}}) {
	my ($header, $replace) = @$headerref;
	my ($key, $value) = split /:\s+/, $header, 2;

	next if lc $key eq 'content-length';
	if (lc $key eq 'content-type') {
	    $c->response->content_type($value);
	} elsif (lc $key eq 'content-encoding') {
	    $c->response->content_encoding($value);
	} else {
	    if ($replace) {
		$c->response->headers->header($key => $value);
	    } else {
		$c->response->headers->push_header($key => $value);
	    }
	}
    }
}

sub finalize {
    my ($self, $c, $output) = @_;

    $self->_set_response_headers($c);

    $c->response->body($output);
    $c->response->status( $self->{_status} || 200 );

    return 1;
}

1;

=head1 NAME

Catalyst::View::Template::PHP - Use PHP as a templating system within Catalyst

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    # create a PHP view in your class with the helper
    $ myapp_create.pl view PHP Template::PHP

    # in myapp.conf
    <Template::PHP>
        include_path  ...
        ...           ...
    </Template::PHP>

    # lib/MyApp/View/PHP.pm
    package MyApp::View::PHP;
    extends 'Catalyst::View::Template::PHP';

    __PACKAGE__->config->{...some php option...} = ... option value ...;

    sub preprocess {
        my ($self,$c,$params) = @_;
        # adjust params as needed to set global PHP variables
        return $params;
    }

    sub postprocess {
        my ($self,$c,$output) = @_;
        # post process the PHP output
        return $output;
    }

    # and somewhere else, maybe a controller
    $c->stash->{template} = '/path/to/some/script.php';
    $c->forward( 'MyApp::View::PHP' );

=head1 DESCRIPTION

This is a Catalyst view class for the L<PHP> module (a Perl
module for embedding PHP into Perl programs). It is 
similar to and inspired by the L<Catalyst::View::PHP>
view class, but that class is written for the
L<PHP::Interpreter> module. 

The PHP file to be interpreted is specified in
C<< $c->stash->{template} >>. The view class helps
set up the appropriate C<$_SERVER>, C<$_ENV>,
C<$_COOKIE>, C<$_FILES>, and C<$_GET/$_POST/$_REQUEST> variables
in the PHP interpreter. In addition, the contents of 
C<< $c->stash >> are exported as global variables (as in 
L<Template Toolkit|Catalyst::View::TT>), and the current
context will be available in the global variable C<$c>.

The workflow for this class looks like:

=over 4

=item 0. set C<< $c->stash->{template} >> to the PHP script to execute.
Invoke L<< Catalyst::View::Template::PHP->process/"process" >>.

=item 1. C<<process> initializes the global variables in PHP, including

=over 4

=item C<< $_ENV >>

This is the server environment (the environment you're
running Catalyst in)

=item C<< $_COOKIE >>

=item C<< $_SERVER >>

=item C<$_GET>/C<$_POST>/C<$_REQUEST>

PHP observes slightly different rules for parsing form input into
an associative array of parameters than Perl does, so setting these
are not quite as simple as copying the relevant Catalyst request
components over to PHP.

=item stash

As with L<Catalyst::View::TT>, the contents of the stash (C<< $c->stash >>)
will be accessible in PHP as global variables.

=item C<< $HTTP_RAW_POST_DATA >>, C<< php://input >>

On POST requests where the content-type is not C<multipart/form-data>
or C<application/x-www-url-form-encoded>, the global PHP variable
C<$HTTP_RAW_POST_DATA> and the PHP input stream C<< php://input >>
will be set to contain the content of the request.

C<Catalyst::View::Template::PHP> cannot currently set up PHP's
C<< php://input >> stream, so C<$HTTP_RAW_POST_DATA> is the only
way to access the raw request content.

=back

=item 2. Invokes the L<"preprocess"> method. Subclasses may override this
method and make adjustments to the global variables before they are
initialized in the PHP interpreter.

=item 3. The PHP script is loaded and evaluated (using L<PHP/"include">).
If the PHP interpreter calls the PHP C<header()> function, then this
class's L<"header_callback"> method will be called with the header data.
Subclasses can override the L<"header_callback"> method to provide
custom handling of headers.

=item 4. The L<"postprocess"> method is called with the output from
PHP. Subclasses may override this method and modify the output or
the headers.

=item 5. If PHP produced a C<Location: ...> header, this class's
L<"on_redirect"> method is called. If this method returns a true
value, the C<process> method redirects to the specified location
and detaches.

=item 6. Otherwise, the L<"finalize"> method is called. The
default behavior of this method is to set the response headers
with the PHP headers and the response body with the PHP output,
but this method may be overridden in a subclass to provide
different behavior.

=back

=head1 METHODS

Most of these methods are hooks into the L<"process"> method
that allow subclasses to intercept and customize the interaction
between Perl and PHP. 

=over 4

=item new

View constructor

=item process

=item $self->process( $c )

Sets up the PHP interpreter instance, intializes some
global variables, and invokes the interpeter on the
script named in C<< $c->stash->{template} >>. Output
from the PHP interpreter is put into
C<< $c->response->{output} >>.

=item preprocess

=item $params = $self->preprocess($c, $params)

Callback just before global variables are initialized
in the new PHP interpreter instance. Subclasses may
override this method and make adjustments to C<$params>,
a hash reference containing the set of global variables
that will be set in PHP.

=item postprocess

=item $new_output = $self->postprocess($c, $output)

Callback after the PHP interpreter has finished processing
the template script. Subclasses may override this method
to perform further processing on the output, before the
output is passed to C<< $c->response->output >>. 
This method MUST RETURN THE OUTPUT, or else all the output
will be erased.

The C<postprocess> method is also a good place to
manipulate the headers produced by PHP 
(see L<"header_callback">), 
if such manipulation is desired.

=item handle_warning

=item $self->handle_warning($c, $message)

Handles a run-time warning message from the PHP interpreter.
By default, this message logs a warning to Catalyst with the
text C<"PHP warning:"> prepended to the message. A subclass
may override this method and do anything they wish with
the warning messages.

=item handle_error

=item $self->handle_error($c, $template, $error_msg)

If the PHP interpreter encounters a run-time or compile-time
error, this method will be called with the error message.
The default behavior is to log a warning message, but this
method can be overridden in the subclass.



=item header_callback

=item $self->header_callback($c, $header_msg, $replace)

Invoked whenever the PHP interpreter calls the PHP
C<header(STRING)> function. The default behavior of
this callback is to accumulate the list of headers
produced by PHP into the list reference C<< $self->{_headers} >>.
Subclasses may override this behavior and handle the
headers from PHP anyway they like.

The C<$replace> argument corresponds to the second argument
of PHP's C<header()> function, indicating whether a duplicate
header key should replace an earlier header, or whether there
should be multiple headers of the same type.

=item on_redirect

=item $proceed = $self->on_redirect($c, $location, $status [=302] )

Called if PHP produced a C<Location: ...> header. Subclasses
should override this method and return a false value if they
do B<not> want to redirect to the new location.

=item finalize

=item $self->finalize($c, $output)

The default behavior of this method is to copy the
PHP response headers to the Catalyst response headers,
and set the PHP output to the Catalyst response output.
Subclasses may override this method to do something else.

=back

=head1 CONFIG

=head2 include_path

a whitespace-separated list of paths where the PHP interpreter can look for
scripts that were referenced in calls to the PHP C<include>, C<require>,
C<include_once>, or C<require_once> functions.

=head2 debug

If non-zero, sends verbose information about the inputs and outputs of
this view class to the Catalyst log (as C<< $c->log->debug(...) >>
messages).

=head1 WHY

If you need to ask, you probably don't need to use this module.

Some people will not need to ask.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-catalyst-view-template-php at rt.cpan.org>,
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Template-PHP>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::Template::PHP

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Template-PHP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Template-PHP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Template-PHP>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Template-PHP/>

=back

=head1 SEE ALSO

L<PHP|http://www.php.net/> (the programming language),
L<PHP> (a Perl module to provide a Perl/PHP interface),
L<PHP::Interpreter> (another fine Perl/PHP interface, but
one that unfortunately doesn't [as of this release]
support php v>=5.2), L<Catalyst::View::PHP> (similar to this
Catalyst view but uses L<PHP::Interpreter> instead of L<PHP>).

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__END__

=begin TODO

=over 21

=item * C<< $c->stash->{php_include_path} >>

scalar or list reference. Sets include path, overrides include_path in 
application config.

=end TODO

=cut
