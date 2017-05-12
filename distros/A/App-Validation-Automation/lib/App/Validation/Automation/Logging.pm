package App::Validation::Automation::Logging;

use Moose::Role;
use English qw( -no_match_vars );

=head1 NAME

App::Validation::Automation::Logging - Role App::Validation::Automation

Logs message in the log file.The log filename is base script name followed by datestamp and log file extension.Logs for the same day get appened in the same log file.

=cut

requires qw( log_file_handle );

=head2 log

Logs messages with timestamp and caller info.

=cut

sub log {

    my $self = shift;
    my $msg  = shift;    
    local $OUTPUT_AUTOFLUSH  = 1;

    print { $self->log_file_handle } 
        scalar(localtime(time)).caller()." $msg"."\n" if( $msg );

    return 1;

}

1;
