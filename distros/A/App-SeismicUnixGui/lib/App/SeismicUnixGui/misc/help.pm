package App::SeismicUnixGui::misc::help;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 Perl package: help.pm 
 AUTHOR: Juan Lorenzo
 DATE: July 30 2017 

 DESCRIPTION: 
 V 0.1 
   user help      

 USED FOR: 

 BASED ON: 

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $set   = L_SU_global_constants->new();
my $alias = $set->alias_superflow_names_h;

my $get             = L_SU_global_constants->new();
my $var             = $get->var();
my $superflow_names = $get->superflow_names_h();

my $true  = $var->{_true};
my $false = $var->{_false};

=pod

 private hash_ref
 w  for widgets

=cut

my $help = {
    _all_href          => '',
    _program_name_sref => '',
    _is_flow           => $false,
    _is_superflow      => $false,
};

=head2 TODO

 determine whether it is a flow or a superflow

=cut

sub is_superflow {

}

sub is_flow {

}

=head2 sub set_name 

 read in initial program name

=cut

sub set_name {
    my ( $self, $name_sref ) = @_;

    if ($name_sref) {
        $help->{_program_name_sref} = $name_sref;

#        print("help, set_name, ${$help->{_program_name_sref}}\n");

    }
    else {
        print("help, set_name, missing name\n");
    }
    return ();

}

=head2 sub _program_name

 i/p is scalar ref
 o/p is scalar ref
 print("help, program_name,:$alias->{ProjectVariables}\n"); 
 print("help, program_name,is $$program_name_sref\n");
 print("help, program_name,is ${$help->{_program_name_sref}}\n");


=cut 

sub _program_name {
    my ($program_name_sref) = @_;
    if ($program_name_sref) {
        my $name_sref;

        #print("1. help, program_name, $$program_name_sref\n");

        if ( $$program_name_sref eq $superflow_names->{_fk} ) {
            $name_sref = \$alias->{fk};
        }

        if ( $$program_name_sref eq $superflow_names->{_iBottomMute} ) {
            $name_sref = \$alias->{iBottomMute};
        }

        if ( $$program_name_sref eq $superflow_names->{_iSpectralAnalysis} ) {
            $name_sref = \$alias->{iSpectralAnalysis};
        }

        if ( $$program_name_sref eq $superflow_names->{_iTopMute} ) {
            $name_sref = \$alias->{iTopMute};
        }

        if ( $$program_name_sref eq $superflow_names->{_iVelAnalysis} ) {
            $name_sref = \$alias->{iVelAnalysis};
        }

        if ( $$program_name_sref eq $superflow_names->{_ProjectVariables} ) {
            $name_sref = \$alias->{SetProject};
        }

        $help->{_program_name_sref} = $name_sref;

        #print("2. help, program_name, ${$help->{_program_name_sref}}\n");
    }
    return ();
}

=head2 sub _sunix 

 check if a pure sunix program

=cut

sub _sunix {

    my ( $self, $hash_ref ) = @_;

    if ($hash_ref) {
        if ( $hash_ref == $true ) {
        	
            $help->{_program_name_sref} = $help->{_program_name_sref};

            # print("help, sunix, ${$help->{_program_name_sref}}\n");
        }
        return ();
    }

}

=head2 sub tkpod 

 read perldoc of each program

=cut

sub tkpod {

    my ($self) = @_;

    if ( ${ $help->{_program_name_sref} } ) {

#        print("help, tkpod, ${$help->{_program_name_sref}}\n");
        system("tkpod ${$help->{_program_name_sref}} &\n\n");

    }
    else {
        print("help, tkpod, missing program name\n");
    }
    return ();

}

=head2 sub _superflows 

 check if a superflows program

=cut

sub _superflows {

    my ( $self, $hash_ref ) = @_;

    if ($hash_ref) {
        if ( $hash_ref == $true ) {
        	
            program_name( $help->{_program_name_sref} );

            # print("help, superflows, ${$help->{_program_name_sref}}\n");
        }
        return ();
    }

}

1;
