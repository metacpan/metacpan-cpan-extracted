package App::SeismicUnixGui::misc::check_buttons;

use Moose;
our $VERSION = '0.0.1';
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $get = L_SU_global_constants->new();
my $var = $get->var();
my $on  = $var->{_on};
my $off = $var->{_off};

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: check_buttons.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 23 2017 

 DESCRIPTION: 
 Create
 many empty values 
 and empty value-entry spaces
     
 USED FOR: 

 BASED ON:

 NEEDS:

=cut

=head2 private hash references

=cut

my $check_buttons = {

    _first_idx      => '',
    _index          => '',
    _length         => '',
    _frame_href     => '',
    _buttons_w_aref => '',

};

=head2  sub make 
 
  make generic switches  
  print("check_buttons, make, frame widget hash: $$frame_aref\n");

=cut

sub make {

    my ( $self, $switch_aref ) = @_;
    my @button_w = ();
    my ( $first, $last, $frame_aref );
    my @variable;

    $first      = $check_buttons->{_first_idx};
    $last       = $check_buttons->{_length};
    $frame_aref = $check_buttons->{_frame_href};
    @variable   = @$switch_aref;

    for ( my $i = $first ; $i < $last ; $i++ ) {

        # print("check_buttons,make, variable is $variable[$i]\n");
        $button_w[$i] = $$frame_aref->Checkbutton(
            -onvalue          => $on,
            -offvalue         => $off,
            -command          => [ \&private_test, $i, \$variable[$i] ],
            -variable         => \$variable[$i],
            -borderwidth      => $var->{_no_borderwidth},
            -text             => '',
            -selectcolor      => 'green',
            -activebackground => 'red',
            -background       => 'red',
            -relief           => 'flat',
        );
    }
    $check_buttons->{_buttons_w_aref} = \@button_w;
}

# -command			=> [\&private_error_check_labelsNparams],
sub private_error_check_labelsNparams {

# print("check_buttons,private_error_check_labelsNparams, check button changed\n")

}

=head2
TODO
=cut

sub private_test {
    my ( $check_button_index, $on_or_off_ref ) = @_;

    # print("check_buttons,test selected a checkbutton\n");
    # print("the current value of the button is $$on_or_off_ref -- weird\n");
    # print("the current checkbutton index = $check_button_index\n");
    return ();
}

=head2 sub set_index

  which parameter is chosen for a program

=cut 

sub set_index {

    my ( $self, $index ) = @_;
    $check_buttons->{_index} = $index;

    # print("check_buttons,set_index:$check_buttons->{_index} \n");

    return ();

}

sub set_switch {

    my ( $self, $on_off_aref ) = @_;
    my $variable;
    my @button_w = @{ $check_buttons->{_buttons_w_aref} };

    my $index = $check_buttons->{_index};

    #for (my $i = $first; $i<$last; $i++) {
    $variable = @$on_off_aref[$index];

    # print("check_buttons,switches_on_off,variable $variable\n");
    $button_w[$index]->configure( -variable => \$variable, );

    #}
}

=head2 get_aref
 in future
 use the get_w_aref version instead
=cut

sub get_aref {

    my ($self) = @_;

    return ( $check_buttons->{_buttons_w_aref} );

}

=head2 get_w_aref

=cut

sub get_w_aref {

    my ($self) = @_;

    return ( $check_buttons->{_buttons_w_aref} );

}

=head2 sub specs 
 
  dimensions of the array  

=cut

sub specs {

    my ( $self, $specs_href ) = @_;

    $check_buttons->{_first_idx} = $specs_href->{_first_entry_idx};
    $check_buttons->{_length}    = $specs_href->{_length};

}

=head2  sub  frame 

 reference of holding widget frame for values 

=cut

sub frame {
    my ( $self, $frame_href ) = @_;
    $check_buttons->{_frame_href} = $frame_href;

}

1;
