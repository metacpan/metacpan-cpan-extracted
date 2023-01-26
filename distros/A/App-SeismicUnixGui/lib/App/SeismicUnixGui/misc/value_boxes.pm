package App::SeismicUnixGui::misc::value_boxes;

use Moose;
our $VERSION = '0.0.1';
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $get = L_SU_global_constants->new();
my $var = $get->var();

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: value_boxes.pm 
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

my $value_boxes = {

    _first         => '',
    _length        => '',
    _frame         => '',
    _values_w_aref => '',

};

=head2  sub texts 
 
 populate Label widget box with new text

=cut

sub texts {
    my ( $self, $value_aref ) = @_;

    my (@values_w);
    my ( $first, $last, $frame_ref );
    my @value;

    @value = @$value_aref;

    $first     = $value_boxes->{_first};
    $last      = $value_boxes->{_length};
    $frame_ref = $value_boxes->{_frame};

    for ( my $i = $first ; $i < $last ; $i++ ) {

        my $value = $value[$i];

        $values_w[$i] = $$frame_ref->Entry(
            -width        => $var->{_40_characters},
            -background   => $var->{_my_light_grey},
            -foreground   => $var->{_my_black},
            -borderwidth  => $var->{_no_borderwidth},
        );
        
        $values_w[$i]->delete(0,'end');
        $values_w[$i]->insert(0,$value);
        
    }

    $value_boxes->{_values_w_aref} = \@values_w;
}

=head2 get_aref
 in future
 use the get_w_aref version instead
=cut

sub get_aref {

    my ($self) = @_;

    return ( $value_boxes->{_values_w_aref} );

}

=head2 get_w_aref

=cut

sub get_w_aref {

    my ($self) = @_;

    return ( $value_boxes->{_values_w_aref} );

}

=head2  sub specs 
 
  dimensions of the array  

=cut

sub specs {

    my ( $self, $specs_href ) = @_;

    $value_boxes->{_first}  = $specs_href->{_first_entry_idx};
    $value_boxes->{_length} = $specs_href->{_length};

}

=head2  sub  frame 

 reference of holding widget frame for values 

=cut

sub frame {
    my ( $self, $frame_ref ) = @_;
    $value_boxes->{_frame} = $frame_ref;

}

1;
