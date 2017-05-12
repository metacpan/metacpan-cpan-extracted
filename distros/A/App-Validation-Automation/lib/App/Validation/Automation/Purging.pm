package App::Validation::Automation::Purging;

use Carp;
use English qw(-no_match_vars);
use Moose::Role;

=head1 NAME

App::Validation::Automation::Purging - Role App::Validation::Automation

Delete old log files as per retention period

=head1 Attributes 

=cut

requires qw( config );

has 'purge_msg' => (
    is       => 'rw',
    isa      => 'Str',
    clearer  => 'clear_purge_msg',
);

=head1 METHODS

=head2 purge

Delete log files(log file extention can be changed from config) older than retention period

=cut

sub purge {
    my $self = shift;
    my ($msg, @log_files, @log_files_purge , $count, $log_dir, $log_extn,
         $log_ret_period);
    $log_dir        = shift || $self->config->{'COMMON.LOG_DIR'};
    $log_extn       = shift || $self->config->{'COMMON.LOG_EXTN'};
    $log_ret_period = shift || $self->config->{'COMMON.RET_PERIOD'};

    chdir $log_dir 
        || confess "Couldn't Change to $log_dir to remove old logs : $OS_ERROR";
    @log_files = <*.$log_extn>;
    @log_files_purge
      = grep {
          (time - (stat($_))[9])/(24 * 3600) > $log_ret_period
    } @log_files;
    
    if ( @log_files_purge ) {
        $msg  = "Log files in $log_dir older than $log_ret_period days:\n";
        $msg .= join "\n", @log_files_purge;
       
        $count = unlink @log_files_purge
                     || confess "Couldn't delete Log Files : $OS_ERROR";
        $self->purge_msg( $msg ) if($count);
        return 1;
    }
    
    return 0;
    
}

1;
