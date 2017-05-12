package App::RepoSync::SystemUtil;
use warnings;
use strict;
use Cwd;
use Exporter::Lite;
our @EXPORT_OK    = qw(system_or_die chdir_qx);
use Term::ANSIColor;

=head1 

App::RepoSync::SystemUtil - system util functions

=head2 system_or_die

@param arrayref|string $command
@param string $description
@param string $chdir

=cut

sub system_or_die {
    my ($command,$description,$chdir) = @_;
    my $cwd = getcwd();
    $description ||= $command;
    chdir $chdir if $chdir;

    my $ret = 0;
    $ret = system( $command );

    my $q = $?;
    my $exit_value = $q >> 8;
    # killing signal is lower 7-bits of top byte, which was shifted to lower byte
    my $signal_num = $q & 127;
    # core-dump flag is top bit
    my $dumped_core = $q & 128;


    if ($q != -1 &&  (($q & 127) == 2) && (!($q & 128))) { 
        # Drop the "$? & 128" if you want to include failures that generated coredump
        die color('yellow') ,"$command: interrupted" , color 'reset';
    } elsif( $q != 0 ) {
        print color 'red';
        print "$description failed: $?\n";
        print color 'reset';
    }
    chdir $cwd if $chdir;
}


=head2 chdir_qx

=cut

sub chdir_qx {
    my ($cmd,$chdir) = @_;
    my $cwd = getcwd();
    chdir $chdir;
    my $ret = qx($cmd);
    chdir $cwd;
    return $ret;
}


1;
