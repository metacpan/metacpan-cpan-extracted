package App::SeismicUnixGui::misc::PID;

use Moose;
our $VERSION = '0.0.1';

=head2 sub PID
 
  collects PIDs associated with running program

=cut

=pod

B<
 track processes by PID
 Debug with:
 print("ref_PID in PID.pm s: @out \n\n");
>
=cut

sub suxgraph {

    my @out = `ps -ef | grep 48/bin/xgraph | awk '{print \$2}'`;

    return ( \@out );
}

sub suximage {

    my @out = `ps -ef | grep 48/bin/ximage | awk '{print \$2}'`;

    return ( \@out );
}

sub xgraph {

    my @out = `ps -ef | grep 48/bin/xgraph | awk '{print \$2}'`;

    return ( \@out );
}

sub ximage {

    my @out = `ps -ef | grep 48/bin/ximage | awk '{print \$2}'`;

    return ( \@out );
}

=head2 sub any

  any other program

  Debug with:
  print("inputs are $self,$program  \n\n");
  print("this is $this  \n\n");

=cut

sub any {
    my ( $self, $program ) = @_;

    if ( defined($program) ) {
        my $this = $program;
        my @out  = `ps -ef | grep 48/bin/$this | awk '{print \$2}'`;

        return ( \@out );
    }
}

1;
