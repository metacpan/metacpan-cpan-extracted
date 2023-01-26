package App::SeismicUnixGui::misc::save;
use Moose;
our $VERSION = '0.0.1';

=head2 sub superflow 

 i/p: hash_ref 

 Deal with macros
 - save to superflow file:
 - save to a *.config file 

 DB:
   print("save_button,save,superflow, current widget is $name->{_current_widget}\n");
   print("2. current program name is $name->{_prog_name}\n");

=cut

   use aliased 'App::SeismicUnixGui::misc::files_LSU';

sub superflow {
    my ( $self, $hash_ref ) = @_;
    
    my $files_LSU = files_LSU->new();
    $files_LSU->tool_specs($hash_ref);
    
    return ();
}

=head2 sub flow 

 Deals with GUI-made flows
 Save to a *.pl file

=cut

sub flow {
    print("save,flow,TODO\n");

    #$writeLSU->sunix_specs($LSU->{_prog_name});
    return ();
}
1;
