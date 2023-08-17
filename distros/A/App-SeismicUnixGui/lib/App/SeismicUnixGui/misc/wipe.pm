package App::SeismicUnixGui::misc::wipe;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: wipe 
 AUTHOR: Juan Lorenzo
 DATE:  July 3 2017 

 DESCRIPTION: 
 Version:0.1 
 Package used for scrubbing gui
=head2 USE

=head3 NOTES 

=head4 

 Examples

=head4 CHANGES and their DATES


=cut

use Moose;
our $VERSION = '0.0.1';
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $get   = L_SU_global_constants->new();
my $var   = $get->var();
my $param = $get->param();


# TODO mystery memory leak between check_buttons_settings_aref and values_w[$i]

=head2 anonymous reference to common variable

In $param->{_length},
length = max_index + 1 (see L_SU_global constants)

=cut

my $entries = {
    _last                 => '',
    _length				  => '',
    _first_idx            => '',
    _labels_w_aref        => '',
    _values_w_aref        => '',
    _check_buttons_w_aref => '',
    # _check_buttons_settings_aref => '',
    _max_index			  => $param->{_length},

};



=head2 sub full_range 


=cut 

sub full_range {
    my ( $self, $ref_hash ) = @_;
    $entries->{_first_idx}            = $ref_hash->{_first_idx};  
    $entries->{_length}               = $entries->{_max_index};
    $entries->{_labels_w_aref}        = $ref_hash->{_labels_w_aref};
    $entries->{_values_w_aref}        = $ref_hash->{_values_w_aref};
    $entries->{_check_buttons_w_aref} = $ref_hash->{_check_buttons_w_aref};
    # $temp							  = $ref_hash->{_check_buttons_settings_aref};
    # $entries->{_check_buttons_settings_aref} = $ref_hash->{_check_buttons_settings_aref};
	# print("wipe,full_range,length of previous selected sueprflow = $entries->{_length}\n");
	# print("wipe,full_range,check_buttons_settings_aref=--@{$entries->{_check_buttons_settings_aref}}--\n");	
	# @{$entries->{_check_buttons_settings_aref}}[0]='aaa';
}

=head2 sub range 


=cut 

sub range {
    my ( $self, $ref_hash ) = @_;
    $entries->{_first_idx}            = $ref_hash->{_first_idx};
    $entries->{_length}               = $ref_hash->{_length};
    $entries->{_labels_w_aref}        = $ref_hash->{_labels_w_aref};
    $entries->{_values_w_aref}        = $ref_hash->{_values_w_aref};
    $entries->{_check_buttons_w_aref} = $ref_hash->{_check_buttons_w_aref};

	# print("wipe,range,length of previous selected sueprflow = $entries->{_length}\n");
}

=head2 sub labels 

  print("self is $self labels are $ref_labels_w\n\n");
   print("delete labels $i ");

=cut 

sub labels {
    my ($self) = @_;
    my ( $first_idx, $length, $i );
    my (@labels_w);

    $first_idx = $entries->{_first_idx};
    $length    = $entries->{_length};

    if ( $entries->{_labels_w_aref} ) {

        @labels_w = @{ $entries->{_labels_w_aref} };

        for ( $i = $first_idx ; $i < $length ; $i++ ) {

            $labels_w[$i]->configure( -text => '', );
        }

    }
    else {
        # print("wipe,values, missing entries->{_labels_w_aref}\n");
    }

    return ();
}

=head2 sub

   print("self is $self values are $ref_values_w\n\n");
   print("wipe  final: $entries->{_final_entry_num}\n");
   print("  prev final: $entries->{_prev_final_entry_num}\n");
   print("  first: $entries->{_first_entry_num}\n");
   print("wipe   max $entries->{_max_entry_num}\n");
   print("max final entry num $all\n\n");
    $LSU->{_ref_labels_w} = $create->labelsc(\@blank_choices,
	\$parameter_names_frame);
     print("wipe i $i\n");
     
	solve mystery memory leak
    $entries->{_check_buttons_settings_aref} = $temp;
	print("wipe,full_range,length of previous selected sueprflow = $entries->{_length}\n");
	print("wipe,full_range,check_buttons_settings_aref=--@{$entries->{_check_buttons_settings_aref}}--\n");

	print("wipe,values, _values_w_aref: @{$entries->{_values_w_aref}} \n");
	print("wipe,values, first_idx: $first_idx, length: $length, _values_w_aref: @{$entries->{_values_w_aref}} \n");	
	
=cut 

sub values {
    my ($self) = @_;
    my ( $first_idx, $length, $i );
    my (@values_w);
    $first_idx = $entries->{_first_idx};
    $length    = $entries->{_length};

#    my $clear_text = '';

    if ( $entries->{_values_w_aref} ) {

        @values_w = @{ $entries->{_values_w_aref} };
        
        for ( $i = $first_idx ; $i < $length ; $i++ ) {
        	
            $values_w[$i]->delete(0,'end');
  	        # print("wipe,values,length=$length}--\n");	          
        }
    }
    else {
    	# print("warning: wipe,values, missing entries->{_values_w_aref}\n");
    	# print("wipe,values, first_idx: $first_idx, length: $length, _values_w_aref: $entries->{_values_w_aref} \n");
    }
    return ();
}

=head2 sub check_buttons 

   print("self is $self\n");
   print("\nprevious final entry $entries->{_prev_final_entry_num}\n");
        print("$i on or off: red \n");
   print("wipe: ref butt are @$ref_button refvar is @$ref_variable\n\n");
   print("\nmax entry $all\n");
   print(" 1. count is $i\n");
   print(" 2. count is $i\n");
   print("all is $all\n");
   print("wipe: ref butt are @$ref_button[$i]\n
                refvar is @$ref_variable[$i]\n\n");
   print(" 1. count is $i\n");
   
=cut

sub check_buttons {

    my ($self) = @_;
    my ( $first_idx, $length, $i );
    my (@check_buttons_w);
    $first_idx = $entries->{_first_idx};
    $length    = $entries->{_length};

    if ( $entries->{_check_buttons_w_aref} ) {
    	# print("wipe, check_buttons, cleaning up to index:$length \n");
        @check_buttons_w = @{ $entries->{_check_buttons_w_aref} };

        for ( $i = $first_idx ; $i < $length ; $i++ ) {

            $check_buttons_w[$i]->configure(
                -background       => $var->{_white},
                -activebackground => $var->{_white},
                -variable         => \$var->{_off},
            );
        }
    }
    else {
        # print("wipe, check_buttons, missing parameters \n");
    }

}
1;
