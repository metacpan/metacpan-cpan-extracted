package App::SeismicUnixGui::misc::redisplay;

use Moose;
our $VERSION = '0.0.1';

my ( $first, $last, $all );
my $true  = 1;
my $false = 0;

=head2 anonymous hashes to common variables

=cut

my $entries = {
    _max_entry_num        => '',
    _first_entry_num      => '',
    _final_entry_num      => '',
    _prev_final_entry_num => '',
    _changed_index        => '',
};

my $LSU = {
    _ref_labels_w                    => '',
    _ref_values_w                    => '',
    _ref_param_value_button_variable => '',
    _ref_param_value_button          => '',
    _entry_array_ref                 => '',
    _file                            => '',
};

=head2 sub file 

  $LSU->{_file}= $hash_ref;
  print("redisp my name is $LSU->{_file} in\n");


=cut

sub file {
    my ( $self, $hash_ref ) = @_;
}

=head2 sub range

  #foreach  my $key(sort keys %$entries){ 
   #       my $values  		= $entries->{$key}; 
   #       print("parameter $key has value of $entries->{$key} \n\n");  
   #       }
 #print("redisp self is $self hash ref is $ref_hash\n\n");
  #print("redisp  final: $entries->{_final_entry_num}\n");
  #print("redisp  prev final: $entries->{_prev_final_entry_num}\n");
  #print("redisp  max $entries->{_max_entry_num}\n");

=cut

sub range {
    my ( $self, $ref_hash ) = @_;
    $entries = $ref_hash;
    $first   = ( $entries->{_first_entry_num} ) - 1;
    $last    = $entries->{_final_entry_num};
    $all     = $entries->{_max_entry_num};
}

=head2 sub

   print("ref label redisplay @$ref_label_array, refframe2 $ref_frame\n");
   note this is an LABEL widget
 DB
  print("1. redisplay, labels, text is @{$label_array_ref}[$i]\n");
  print("redisplay, labels, i is $i\n");
  print("2. redisplay, labels, text is @{$LSU->{_label_array_ref}}[$i]\n");

=cut

sub labels {
    my ( $self, $label_array_ref, $ref_label_w ) = @_;

    if ($label_array_ref) {
        $LSU->{_label_array_ref} = $label_array_ref;
        for ( my $i = $first ; $i < $last ; $i++ ) {
            @$ref_label_w[$i]->configure( -text => @$label_array_ref[$i], );
        }
        return ();
    }
}

=head2 sub values 

  i/p: 2 array references
  o/p: array reference

  N.B. This is an ENTRY widget
  textvariables must be a reference in order
  for -validatecommand to work. BEWARE!

  DB
  print("redisplay, values, i is $i\n");
  print("redisplay, values, entry is @{$LSU->{_entry_array_ref}}[$i]\n");

=cut 

sub values {
    my ( $self, $entry_array_ref, $ref_entry_w ) = @_;
    if ($entry_array_ref) {
        $LSU->{_entry_array_ref} = $entry_array_ref;

        for ( my $i = $first ; $i < $last ; $i++ ) {
            @$ref_entry_w[$i]->configure(
                -textvariable    => \@{ $LSU->{_entry_array_ref} }[$i],
                -validate        => 'focusout',
                -validatecommand => [ \&new_entry, $i ],
                -invalidcommand  => \&error_check,
            );
        }
    }
}

=head2 sub collect_new_values


=cut

sub collect_new_entry_values {

    return ( \@{ $LSU->{_entry_array_ref} } );

}

=head2 sub new_entry 

 When original value of Entry widget (package create, sub valuesc) 
 is modified, test the new value
 Now can test for integers or decimal values as follows:

  if (($test =~ /^-?\d+/) || ($test =~ /^-?\d+\.\d+/)) {
  print ("Error: Entered an integer (First check)\n");
  print ("or a decimal (2nd check)\n");

 TODO multiple values

 NB.
  Dereference one scalar reference 
  within an array of references 
  First ascertain values are not blank
  as during initialization of GUI. 

 DB
 print("redisplay,new_entry,new_entry_index is  $index\n");
 print("redisplay,new_entry,new_entry is @{$LSU->{_entry_array_ref}}[$index]\n");


=cut

sub new_entry {
    my ($index) = @_;
    $entries->{_index} = $index;

#print("redisplay,new_entry,new_entry_index is  $index\n");
#print("redisplay,new_entry,new_entry is @{$LSU->{_entry_array_ref}}[$index]\n");
    return ($true);
}

=head2 sub error_check

 When entry values are not 
 decimals or numbers 
 used if new_entry returns a "$false" = 0
 must return 1

=cut

sub error_check {
    my $entry_value_ref = $entries->{_index};

    #print("Index is  $$entry_value_ref\n");
    return ($true);
}

=head2 sub

    my $on  = 'on';

    redisplay will require another input array of
    on and off buttons

=cut

sub checkbuttons {
    my ( $self, $ref_button, $ref_variable ) = @_;
    my $i;

    if ( defined($ref_button) ) {
        for ( $i = $first ; $i < $last ; $i++ ) {
            @$ref_button[$i]->configure(
                -background       => 'red',
                -activebackground => 'red',
                -variable         => \@$ref_variable[$i],
            );
        }
        return ();
    }
}
1;
