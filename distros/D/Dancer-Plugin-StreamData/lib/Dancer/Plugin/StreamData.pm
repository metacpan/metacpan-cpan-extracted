package Dancer::Plugin::StreamData;

use strict;
use warnings;
use Carp;

use Dancer ':syntax';
use Dancer::Plugin;

our $VERSION = '0.9';

=head1 NAME

Dancer::Plugin::StreamData - stream long responses instead of sending them in one piece

=head1 SYNOPSIS

    package MyWebApp;
    
    use Dancer;
    use Dancer::Plugin::StreamData;
    
    get '/some_route' => sub {

        # ...
        
        return stream_data($data_obj, \&stream_my_data);
    };
    
    sub stream_my_data {
    
        my ($data_obj, $writer) = @_;
        
        while ( $output = $data_obj->get_some_data() )
        {
	    $writer->write($output);
        }
        
        $writer->close();
    }

=head1 DESCRIPTION

This plugin is useful for situations in which a L<Dancer> application wants to
return a large set of data such as the results from a database query.  This is
especially important where the result set might total tens or hundreds of
megabytes, which would be awkward to marshall within the memory of a single
server process and could lead to a long delay before the start of data
delivery.

The C<stream_data> function allows the application to stream a response one
chunk at a time.  For example, the data could be fetched row by row from a
database server, with each row processed and then dispatched to the client via
the write() method.

The reason for this plugin is that the interface defined by PSGI for data
streaming is annoyingly complex and difficult to work with.  By hiding the
complexity, this plugin makes it simple to set up an application which streams
long responses instead of marshalling them into a single response message.

This plugin can be used with any L<PSGI> compatible web server, and includes a
method by which you can check whether the server supports streaming.

=head1 USAGE

=cut

# Between the PSGI interface standard and the way Dancer does things,
# streaming a response involves a callback that returns a callback that is
# passed a callback, none of which are called with the necessary parameters.
# So the easiest way to get the necessary information to the routines that
# need it is to store this information in private variables.  Not the most
# elegant solution, but it works.  In fact, Dancer itself stores a lot of
# things in private variables.

my $stream_object;
my $stream_call;
my $stream_status;
my @stream_headers;


=head2 stream_data

This function takes two parameters: a data object, and a stream callback.  The
data object need not contain the data itself; it may be a database handle or
other reference by means of which the data will be obtained.  The callback
can be specified either as a code reference, or as a string.  In the latter
case, it will be invoked as a method call on the data object.

Before calling C<stream_data>, the HTTP status and response headers may be set
by the usual mechanisms of Dancer.  A call to C<stream_data> will terminate
route processing, analagous to C<send_file>.  Any further code in the route
handler will be ignored.  If an 'after' hook is defined in this app, it will
be called as usual after route processing and may modify the response status
and/or headers.

The callback is invoked after the response headers have been sent.  Its job is
to stream the body of the response.  The callback is passed two parameters:
the data object, and a 'writer' object.

=cut

# This is the main symbol that we export using the 'register' mechanism of
# Dancer::Plugin.pm.  It takes two parameters: an arbitrary Perl reference
# (the "data"), and a routine to be called in order to stream it.  The latter
# can be specified either as a string value, in which case it is taken to be a
# method name and invoked on the data reference, or it can be a code
# reference.  The data reference might contain, e.g. a database handle from
# which data is to be read and the results streamed to the client.

register 'stream_data' => sub {
    
    my ($data, $call) = @_;
    
    # First make sure that the server supports streaming
    
    my $env = Dancer::SharedData->request->env;
    unless ( $env->{'psgi.streaming'} ) {
	croak 'Sorry, this server does not support PSGI streaming.';
    }
    
    # Store the parameters for later use by stream_callback()
    
    $stream_object = $data;
    $stream_call = $call;
    
    # Clear the global variables that we used to preserve the status code
    # and content type.
    
    $stream_status = undef;
    @stream_headers = ();
    
    # Indicate to Dancer that the response will be streamed, and specify a
    # callback to set up the streaming.
    
    my $resp = Dancer::SharedData::response;
    $resp->streamed(\&prepare_stream);
    
    my $c = Dancer::Continuation::Route::FileSent->new(return_value => $resp);
    $c->throw;
};


# This routine will be called by Dancer, and will be passed the status code
# and headers that have been determined for the response being assembled.  Its
# job is to return a callback that will in turn be called at the proper time
# to begin streaming the data.  Unfortunately, it will be called *twice*, the
# second time with an improper status code and headers.  Consequently, we must
# ignore the second invocation.

sub prepare_stream {

    my ($status, $headers) = @_;
    
    # Store the status and headers we were given, because the callback that
    # does the actual streaming will have to present them directly to the PSGI
    # interface.  We have no way of actually getting that information to it
    # other than a private variable (declared above).
    
    # The variable $stream_status is made undefined by the stream_data()
    # function (see above) and so we only set it if it has not been set
    # since. This gets around the problem of this routine (prepare_stream())
    # being called twice.
    
    if ( !defined $stream_status )
    {
	$stream_status = $status;
	@stream_headers = ();
	
	# We filter the headers to remove content-length, since we don't
	# necessarily know what the content length is going to be (that's one
	# of the advantages of using this module).
	
	for ( my $i = 0; $i < @$headers; $i = $i + 2 )
	{
	    if ( $headers->[$i] !~ /content-length/i )
	    {
		push @stream_headers, $headers->[$i];
		push @stream_headers, $headers->[$i+1];
	    }
	}
    }
    
    # Tell Dancer that it should call the function stream_callback() when
    # ready for streaming to begin.
    
    return \&stream_callback;
}

=pod

The writer object, as specified by L<PSGI>, implements two methods:

=head3 write

Sends its argument immediately to the client as the next piece of the response.
You can call this method as many times as necessary to send all of the data.

=head3 close

Closes the connection to the client, terminating the response.  It is
important to call C<close> at the end of processing, otherwise the client will
erroneously report that the connection was closed prematurely before all of
the data was sent.

=cut

# This subroutine is called at the proper time for data streaming to begin.
# It is passed a callback according to the PSGI standard that can be called to
# procure a writer object to which we can actually write the data a chunk at a
# time.  As each chunk is written, it is sent off to the client as part of the
# response body.

sub stream_callback {
    
    # Grab the callback, which is the first parameter.
    
    my $psgi_callback = shift;
    
    # Use the callback we were given to procure a writer object, and in the
    # process pass the status and headers stored by prepare_stream() above.
    # This will cause the HTTP response to be emitted, with a keep-alive
    # header so that the client will know to wait for more data to come.
    
    my $writer = $psgi_callback->( [ $stream_status, \@stream_headers ] );
    
    # Now we call the routine specified in the original call to stream_data.
    # If it was given as a code reference, we call it and pass in the "data"
    # object as the first parameter.  Otherwise, we use it as a method name
    # and invoke it on the "data" object.  In either case, we pass the writer
    # object as a parameter.
    
    if ( ref $stream_call eq 'CODE' )
    {
	$stream_call->($stream_object, $writer);
    }
    
    else
    {
	$stream_object->$stream_call($writer);
    }
}


=head2 server_supports_streaming

This function returns true if the server you are working with supports
PSGI-style streaming, false otherwise.

Here is an example of how you might use it:

    if ( server_supports_streaming ) {
	stream_data($query, 'streamResult');
    } else {
	return $query->generateResult();
    }

=cut

register 'server_supports_streaming' => sub {
    
    my $env = Dancer::SharedData->request->env;
    return 1 if $env->{'psgi.streaming'};
    return undef; # otherwise
};


register_plugin;
1;

__END__

=head1 AUTHOR

Michael McClennen, mmcclenn 'at' cpan.org

=head1 SEE ALSO

L<Dancer>

L<PSGI>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-streamdata at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-StreamData>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Michael McClennen

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
