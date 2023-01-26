package App::SeismicUnixGui::misc::error;
use Moose;
our $VERSION = '0.0.1';

=head2 sub run_flow 

 Deals with GUI-made flows
 Running *.pl file

=cut

sub run_flow {
    my ( $self, $hash_ref ) = @_;
    if ( $hash_ref->{_flow_name} ) {
        $hash_ref->{_error} = 0;
    }
    else {
        my $message = ("Save flow first. Then run.\n");
        print $message;

        #$hash_ref->{_message}->insert('end', "Thi is some normal text\n");
        return (0);
    }
    return ();
}

=head2 sub save_superflow 

 i/p: hash_ref 

 Deal with macros
 - error to superflow file:
 - error to a *.config file 

 DB:
   print("error_button,error,superflow, current widget is $name->{_current_widget}\n");
   print("2. current program name is $name->{_prog_name}\n");

=cut

sub save_superflow {
    my ( $self, $hash_ref ) = @_;
    if ( $hash_ref->{_superflow_name} ) {
        $hash_ref->{_error} = 0;
    }
    else {
        print("error,nameless superflow\n");
        return (0);
    }
    return ();
}

=head2 sub save_flow 

 Deals with GUI-made flows
 Save to a *.pl file

=cut

sub save_flow {
    my ( $self, $hash_ref ) = @_;
    if ( $hash_ref->{_flow_name} ) {
        $hash_ref->{_error} = 0;
    }
    else {
        print("error,nameless flow,TODO\n");
        return (0);
    }
    return ();
}
1;
