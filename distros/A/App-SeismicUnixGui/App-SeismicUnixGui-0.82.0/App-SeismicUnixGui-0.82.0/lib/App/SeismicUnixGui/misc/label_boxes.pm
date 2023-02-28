package App::SeismicUnixGui::misc::label_boxes;

use Moose;
our $VERSION = '0.0.1';
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();
my $var = $get->var();

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: label_boxes.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 23 2017 

 DESCRIPTION: 
 Create
 many empty labels 
     
 USED FOR: 

 BASED ON:

 NEEDS:

=cut

=head2 private hash references

=cut

my $label_boxes = {

    _first         => '',
    _length        => '',
    _frame         => '',
    _labels_w_aref => '',

};

=head2  sub texts 
 
 populate Label widget box with new text

=cut

sub texts {
    my ( $self, $label_array_ref ) = @_;

    my (@labels_w);
    my ( $first, $last, $frame_ref );

    $first     = $label_boxes->{_first_entry_idx};
    $last      = $label_boxes->{_length};
    $frame_ref = $label_boxes->{_frame};

    for ( my $i = $first ; $i < $last ; $i++ ) {
        $labels_w[$i] = $$frame_ref->Label(
            -height      => $var->{_one_character},
            -width       => $var->{_thirty_five_characters},
            -text        => @$label_array_ref[$i],
            -borderwidth => $var->{_one_pixel_borderwidth},
            -background  => $var->{_light_gray},
        );
    }
    $label_boxes->{_labels_w_aref} = \@labels_w;
}

=head2 get_aref 
 in future
 use the get_w_aref version instead 
=cut

sub get_aref {

    my ($self) = @_;

    return ( $label_boxes->{_labels_w_aref} );

}

=head2 get_w_aref

=cut

sub get_w_aref {

    my ($self) = @_;

    return ( $label_boxes->{_labels_w_aref} );

}

=head2  sub  specs 
 
  dimensions of the array  

=cut

sub specs {

    my ( $self, $specs_hash_ref ) = @_;

    $label_boxes->{_first_entry_idx} = $specs_hash_ref->{_first_entry_idx};
    $label_boxes->{_length}          = $specs_hash_ref->{_length};

}

=head2  sub  frame 

 reference of holding widget frame for labels 

=cut

sub frame {
    my ( $self, $frame_ref ) = @_;
    $label_boxes->{_frame} = $frame_ref;

}

1;
