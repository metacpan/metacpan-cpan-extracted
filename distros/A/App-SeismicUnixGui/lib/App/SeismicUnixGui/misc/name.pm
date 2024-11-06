package App::SeismicUnixGui::misc::name;

# NOTE TODO will be deprecated in favor of program_name which self-defines 
# global constants and uses hregex and ashes for quick searbch

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $superflow_names_aref = $get->superflow_names_aref();
my @superflow_names_aref = @$superflow_names_aref;

#my $alias_superflow_names_aref = $get->alias_superflow_names_aref;
#my @alias_superflow_names_aref = @$alias_superflow_names_aref;

my $alias_superflow_config_names_aref = $get->alias_superflow_config_names_aref;
my @alias_superflow_config_names_aref = @$alias_superflow_config_names_aref;

my $superflow_config_names_aref = $get->superflow_config_names_aref;
my @superflow_config_names_aref = @$superflow_config_names_aref;

my $name = {

    _program_name_config => '',
    _program_name        => '',

};

#=head2 sub alias_superflow_names 
#
#=cut
#
#sub get_alias_superflow_names {
#    my ( $self, $name_in ) = @_;
#    my $name_out;
#    my $length = scalar(@alias_superflow_names_aref);
#
#    for ( my $i = 0 ; $i < $length ; $i++ ) {
#
# print("1. name,get_alias_superflow_names,name_in=$$name_in\n");
## print("1. name,get_alias_superflow_names, alias= $alias_superflow_names_aref[$i]\n");
# print("1. name,get_alias_superflow_names, superflow_names= $superflow_names_aref[$i]\n");
#
#        if ( $$name_in eq $superflow_names_aref[$i] ) {
#
#            # print("2. name,get_alias_superflow_names,name_in= $$name_in\n");
#            $name_out = $alias_superflow_names_aref[$i];
#
#            print("2. name,get_alias_superflow_names, alias= $name_out\n");
#        }
#    }
#    return ($name_out);
#}

=head2 sub change_config 

 Modify input names--
 adapt them to infer
 which spec and parameter
 files to read
 CAUSE: aliases in GUI
  Program names in GUI
  and configuration file names
  in the local (!!) directory
  may be different.

=cut

sub change_config {
    my ( $self, $program_name ) = @_;

    if ($program_name) {

        # print("name,change_config,progr name is $program_name\n");
        my $length = scalar @superflow_config_names_aref;

        # print("name,change_config,length	= $length\n");

        for ( my $i = 0 ; $i < $length ; $i++ ) {
        	
        	# print("name,change_config, superflow_config_names_aref[$i]=$superflow_config_names_aref[$i]\n");
            if ( $program_name eq $superflow_config_names_aref[$i] ) {

                $name->{_program_name_config} =
                $alias_superflow_config_names_aref[$i] . '.config';

                # print ("name,change_config,progr name config is $name->{_program_name_config}\n");
            }
        }
        return ( $name->{_program_name_config} );
    }
}

=head2   sub change_pl 

 Modify  names--
 adapt them to infer a ".pl" file

=cut

sub change_pl {
    my ( $self, $program_name ) = @_;
    my $program_name_pl;
    if ($program_name) {

        # print("name,change_pl,progr name is $program_name\n");
        $program_name_pl = $program_name . '.pl';

        # print("name,change_pl,progr name config is
        # $name->{_program_name_pl}\n");
    }
    return ($program_name_pl);
}

=head2  sub perldoc names  IS this used?


=cut

sub help {    #TODO? needed?
    my ( $self, $program_name ) = @_;
    if ( defined($program_name) ) {

        $name->{_program_name} = $program_name . '.pm';

        if ( $program_name eq 'SetProject' ) {
            $name->{_program_name} = 'SetProject';
        }
        elsif ( $program_name eq 'fk' ) {
            $name->{_program_name} = 'Sudipfilt2';
        }
        elsif ( $program_name eq 'iVA2' ) {
            $name->{_program_nameg} = 'iVA2.pm';
        }
    }
    return ( $name->{_program_name} );

}

1;
