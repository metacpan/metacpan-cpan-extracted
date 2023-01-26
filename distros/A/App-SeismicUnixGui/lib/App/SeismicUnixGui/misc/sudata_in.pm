package App::SeismicUnixGui::misc::sudata_in;

use Moose;
our $VERSION = '0.0.1';

my $sudata_in = {
    _file_name  => '',
    _type       => '',
    _Step       => '',
    _notes_aref => '',
};

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $sudata_in->{_file_name}  = '';
    $sudata_in->{_type}       = '';
    $sudata_in->{_Step}       = '';
    $sudata_in->{_note}       = '';
    $sudata_in->{_notes_aref} = '';
}

my @notes;

# define a value
my $newline = '
';

=head2 sub  file_name  you need to know how many numbers per line
  will be in the output file 

=cut

sub file_name {
    my ( $variable, $file_name ) = @_;
    if ($file_name) {
        $sudata_in->{_file_name} = $file_name;
        $sudata_in->{_note} =
          $sudata_in->{_note} . ' sudata_in=' . $sudata_in->{_file_name};
        $sudata_in->{_Step} =
          $sudata_in->{_Step} . ' sudata_in=' . $sudata_in->{_file_name};
    }
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=0
    my $max_index = 0;

    return ($max_index);
}

=pod

=head2 subroutine note 
 adds the program name

=cut

sub notes_aref {
    my ($self) = @_;

    $notes[1] = "\t" . '$sudata_in[1] 	= ' . $sudata_in->{_note};

    $sudata_in->{_notes_aref} = \@notes;

    return $sudata_in->{_notes_aref};
}

1;
