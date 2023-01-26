package App::SeismicUnixGui::misc::oop_instantiation_defaults;

use Moose;
our $VERSION = '0.0.2';

=head2 Default perl lines for oop_instantiation_defaults
       of imported packages V 0.0.1
       ew 
	V 0.0.2 July 24 2018 include data_in, include data_out
	V 0.0.3 4-5-19 remove duplicate program names

=cut

=head2 program parameters
	 
  private hash
  
=cut

my $oop_instantiation_defaults = { _prog_names_aref => '', };
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';

sub section {
    my ($self) = @_;

    my $ref_instantiation_lines = _get_instantiation();
    return ($ref_instantiation_lines);
}

=head2 sub _get_instantiation

		filter duplicates 4-5-2019

=cut

sub _get_instantiation {

    my ($self) = @_;

    if ( $oop_instantiation_defaults->{_prog_names_aref} ) {

        my @unique_progs;
        my $unique_progs_ref;
        my $num_unique_progs;
        my @prog_name = @{ $oop_instantiation_defaults->{_prog_names_aref} };
        my $length    = scalar @prog_name;
        my @oop_instantiation_defaults;
        my $filter = manage_files_by2->new();

        # default programs
        $oop_instantiation_defaults[0] =
          "\n\t" . 'my $log' . "\t\t\t\t\t" . '= message->new();';

        $oop_instantiation_defaults[1] =
          "\t" . 'my $run' . "\t\t\t\t\t" . '= flow->new();';
        print("\n");

        # user-defined programs
        # remove repeated programs from the list
        $unique_progs_ref = $filter->unique_elements( \@prog_name );
        @unique_progs     = @{$unique_progs_ref};
        $num_unique_progs = scalar @unique_progs;

        for ( my $i = 0, my $j = 2 ; $i < $num_unique_progs ; $i++ ) {

# if(($prog_name[$i] ne 'data_out') )  {  # exclude data_out module removed in V 0.0.2
# print("2. instantiation,set_prog_names_aref, prog_name=$prog_name[$i]\n");
            $oop_instantiation_defaults[$j] =
                "\t" . 'my $'
              . $unique_progs[$i]
              . "\t\t\t\t"
              .'= '
              . $unique_progs[$i] . '->new();';

            # print 	$oop_instantiation_defaults[$j];
            $j++;

            #}
        }
        return ( \@oop_instantiation_defaults );

    }
    else {
        print(
"instantiation,_get_instantiation, missing instantiation->{_prog_names_aref} \n"
        );
    }

}

=head2 sub set_prog_names_aref

=cut

sub set_prog_names_aref {
    my ( $self, $hash_aref ) = @_;

    if ($hash_aref) {
        $oop_instantiation_defaults->{_prog_names_aref} =
          $hash_aref->{_prog_names_aref};

    }
    else {
        print("instantiation, set_prog_names_aref, missing hash_aref\n");
    }

    return ();
}

1;
