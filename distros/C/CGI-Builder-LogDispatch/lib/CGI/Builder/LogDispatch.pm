package CGI::Builder::LogDispatch;

$VERSION = 0.1;

use strict;
use Log::Dispatch 2.0 ();
use Date::Format ();

$Carp::Internal{ 'Log::Dispatch' }++;
$Carp::Internal{+__PACKAGE__}++;

use Class::groups(
    { name    => 'logger_config',
      default => {  }
    } ,
);

use Class::props(
    { name    => 'logger',
      default => sub { shift()->logger_new( @_ ) }
    } ,
);

# Note name and min_level are required params to new(), so we hard-code them
# but allow overrides from the user configuration
sub logger_new { 
    my ($self) = @_;
    my %defaults;
    my $logger = Log::Dispatch->new();
    if ( $self->can('r') and $self->r->can('log') ) {
        require Log::Dispatch::ApacheLog;
        %defaults = (name=>'default', min_level=>'warning',apache=>$self->r);
        $logger->add(
            Log::Dispatch::ApacheLog->new( %defaults, %{$self->logger_config} )
        );
    } else {
        require Log::Dispatch::Screen;
        %defaults = ( name=>'default'
                    , min_level=>'warning'
                    , callbacks => sub { sprintf "[%s] %s\n", Date::Format::time2str('%Y-%m-%d %H:%M:%S',time), $_[1] }
                    );
        $logger->add(
            Log::Dispatch::Screen->new( %defaults, %{$self->logger_config} )
        );
    }
    return $logger;
}


1;

__END__

=head1 NAME

CGI::Builder::LogDispatch - integrated logging system for CGI::Builder

=head1 VERSION 0.01

=head1 INSTALLATION

=over

=item Prerequisites

    CGI::Builder    >= 1.12
    Log::Dispatch   >= 2.0

=back

=head1 SYNOPSIS

    # just include it in your build
    use CGI::Builder
    qw| CGI::Builder::LogDispatch
      |;
    
    # Logger can write to different "Log Levels". The default level is 
    # "warning". Messages of lesser importance will not be written. When
    # developing, you probably want this cranked to "debug":
    sub OH_init {
        my ($webapp) = @_;
        # This MUST be done before calling $webapp->logger or it will have no effect!
        $webapp->logger_config('min_level' => 'debug');
    }
    
    # Then use it to write nicely formatted messages to your web server log
    sub PH_AUTOLOAD {
        my ($webapp) = @_;
        # The default min_level
        $webapp->logger->debug("This message only gets logged if you set min_level=>debug.");
        if ( $webapp->page_error ) {
            $webapp->logger->error("Oh no! There is a problem!");
        }
    }

=head1 DESCRIPTION

The module should do what you want with no prodding. Just include it and start 
using the logger property to log things. If you are using Apache::CGI::Builder
and Apache::Log, it will automatically use Apache's native log mechanism. 
Otherwise it prints log messages to STDERR (which goes to the web server error 
log), prepending them with a timestamp.

If you want to do anything fancier than this you can override the logger_new 
method in your build to construct the object any way you like. See 
L<Log::Dispatch> for details.

=head1 SUPPORT

Support is provided via the CGI::Builder Users mailing list. You can join the CBF
mailing list at this url:

    http://lists.sourceforge.net/lists/listinfo/cgi-builder-users

=head1 ACKNOWLEDGMENTS

Many thanks to Domizio Demichelis, author of the CGI::Builder framework,
and Dave Rolsky, author of Log::Dispatch.

=head1 AUTHORS

Vince Veselosky (L<http://control-escape.com>)

=head1 COPYRIGHT

(c) 2005 by Vincent Veselosky

This module is free software. It may be used,
redistributed and/or modified under the same terms as perl itself.
