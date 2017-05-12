package Apache::Recorder;

=pod

=head1 NAME

Apache::Recorder - mod_perl handler to record HTTP sessions

=head1 DESCRIPTION

The Apache::Recorder module is an implementation of a session recorder,
much like a macro recorder that you might use with a GUI application.
It allows you to "record" each of the clicks that you make during an
http session for later playback.  However, Apache::Recorder does not
provide capabilities to "play-back" a recorded session.  To "play-back"
a session, you need two additional modules: (1) HTTP::RecordedSession
to "thaw" the session, and format it appropriately; and (2) A module
(such as HTTP::Monkeywrench or HTTP::WebTest) which wraps testing
logic around the "thawed" session.

Apache::Recorder listens for a cookie which indicates that it should record
the current session.  If the cookie is not present, it immediately declines
to handle the request.  If the cookie is present, it acquires 
information about the current request, and writes that information to the
file system using Storable.

After the user has finished recording their session, they may access the 
recorded session using HTTP::RecordedSession.  HTTP::RecordedSession
can format the session for use with HTTP::Monkeywrench or HTTP::WebTest.
This makes the module very useful when creating regression tests.

=cut

use strict;
use vars qw( $VERSION );
$VERSION = '0.07';


use Apache::Constants qw(:common);
#use Apache::File;
use CGI::Cookie;
use Apache::URI;

sub handler {
    my $r = shift;
    my $id = get_id( $r );
    return DECLINED unless $id;

    #This should stop all but the most aggressive proxy server and browser cache settings.
    $r->no_cache(1);

    $r->warn( "Apache::Recorder is running." );

    my $parsed_uri = $r->parsed_uri;
    my $host = $parsed_uri->hostname() || $r->subprocess_env( "SERVER_NAME" ) || 'localhost';
    my $uri = "http://" . $host . $parsed_uri->path();
    my $file_name = $r->filename;
    $r->warn( "Apache::Recorder: ", $file_name );

    #Process CGI GET / POST Parameters
    my %params = $r->method eq 'POST' ? $r->content : $r->args; 
    
    my $request_type = $r->method;
    use constant WORLD_WRITEABLE_DIR => "/usr/tmp/";
    #die "Cannot write to WORLD_WRITEABLE_DIR: $!" unless ( -w WORLD_WRITEABLE_DIR );
    
    my $config_file = WORLD_WRITEABLE_DIR . "recorder_conf_".$id;
    unless ( write_config_file( $config_file, $uri, $request_type, \%params ) ) {
        warn "ERROR: Apache::Recorder could not write successfully to $config_file";
    }
    return DECLINED;
}

sub get_id {
    my $r = shift;

    my %cookies = CGI::Cookie->parse( $r->header_in( 'Cookie' ) );
    if (exists( $cookies{ 'HTTPRecorderID' } ) ) {
	return $cookies{ 'HTTPRecorderID' }->value;
    }
}

=pod

=head1 DETAILS

Apache::Recorder is intended to work as a stand-alone mod_perl handler.  As such,
it does not export any functions.  However, if you _really_ want to use its 
internal functions, here is the API:

write_config_file() calls Storable::lock_store() to serialize the most recent click.

It accepts four parameters, (1) the full path to the file where the "clicks" are going
to be saved; (2) the URI that should be saved; (3) the request type; (4) any
parameters that should be saved for the request;

=cut

sub write_config_file {
    my $config_file = shift;
    my $uri = shift;
    my $request_type = shift;
    my $params = shift;

    use Storable qw( lock_store lock_retrieve );
    #maintain insert order in hash
    $Storable::canonical = 1;
    my $click = {
	url => $uri, 
	method => $request_type,
	params => $params, 
        acceptcookie => '1',
        sendcookie => '1',
        print_results => '1',
    };

    #If the config file already exists, append to it
    my $history;
    if ( -e $config_file ) { 
        $history = lock_retrieve( $config_file ) || undef;
	my $count = keys %$history;
        $count++;
	$history->{ $count } = $click;
    }
    #Otherwise, this is the first entry in the config file
    else { 
        $history->{ '1' } = $click;
    }

    my $rc = lock_store $history, $config_file; 
    return $rc;
}

1;
__END__

=pod

=head1 AUTHOR

Chris Brooks <cbrooks@organiccodefarm.com>

=head1 SEE ALSO

HTTP::RecordedSession

=cut
