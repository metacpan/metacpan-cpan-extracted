package App::SeismicUnixGui::sunix::header::suchw;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUCHW - Change Header Word using one or two header word fields	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION: Nov 3 2013,
 Version: 0.1

=head2 USE
  suchw->clear();
  suchw->();
  $suchw[1] = suchw->Step();

=head3 NOTES

  This program derives from suchw in Seismic Unix
  "notes" keeps track of actions for possible use in graphics
  "steps" keeps track of actions for execution in the system

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUCHW - Change Header Word using one or two header word fields	

  suchw <stdin >stdout [optional parameters]				

 Required parameters:							
 none									

 Optional parameters:							
 key1=cdp,...	output key(s) 						
 key2=cdp,...	input key(s) 						
 key3=cdp,...	input key(s)  						
 a=0,...		overall shift(s)				
 b=1,...		scale(s) on first input key(s) 			
 c=0,...		scale on second input key(s) 			
 d=1,...		overall scale(s)				
 e=1,...		exponent on first input key(s)
 f=1,...		exponent on second input key(s)

 The value of header word key1 is computed from the values of		
 key2 and key3 by:							

	val(key1) = (a + b * val(key2)^e + c * val(key3)^f) / d		

 Examples:								
 Shift cdp numbers by -1:						
	suchw <data >outdata a=-1					

 Add 1000 to tracr value:						
 	suchw key1=tracr key2=tracr a=1000 <infile >outfile		

 We set the receiver point (gx) field by summing the offset		
 and shot point (sx) fields and then we set the cdp field by		
 averaging the sx and gx fields (we choose to use the actual		
 locations for the cdp fields instead of the conventional		
 1, 2, 3, ... enumeration):						

   suchw <indata key1=gx key2=offset key3=sx b=1 c=1 |			
   suchw key1=cdp key2=gx key3=sx b=1 c=1 d=2 >outdata			

 Do both operations in one call:					

 suchw<indata key1=gx,cdp key2=offset,gx key3=sx,sx b=1,1 c=1,1 d=1,2 >outdata


 Credits:
	SEP: Einar Kjartansson
	CWP: Jack K. Cohen
      CWP: John Stockwell, 7 July 1995, added array of keys feature
      Delphi: Alexander Koek, 6 November 1995, changed calculation so
              headers of different types can be expressed in each other

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suchw = {
    _a    => '',
    _b    => '',
    _c    => '',
    _d    => '',
    _e    => '',
    _f    => '',
    _key1 => '',
    _key2 => '',
    _key3 => '',
    _Step => '',
    _note => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suchw->{_Step} = 'suchw' . $suchw->{_Step};
    return ( $suchw->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suchw->{_note} = 'suchw' . $suchw->{_note};
    return ( $suchw->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suchw->{_a}    = '';
    $suchw->{_b}    = '';
    $suchw->{_c}    = '';
    $suchw->{_d}    = '';
    $suchw->{_e}    = '';
    $suchw->{_f}    = '';
    $suchw->{_key1} = '';
    $suchw->{_key2} = '';
    $suchw->{_key3} = '';
    $suchw->{_Step} = '';
    $suchw->{_note} = '';
}

# define a value
my $newline = '
';

=head2 sub a 


 subs a, add_to_all 
 add the following
 value after 
 all other operations
 are complete

=cut

sub a {

    my ( $self, $a ) = @_;
    if ($a) {

        $suchw->{_a}    = $a;
        $suchw->{_note} = $suchw->{_note} . ' a=' . $suchw->{_a};
        $suchw->{_Step} = $suchw->{_Step} . ' a=' . $suchw->{_a};

    }
    else {
        print("suchw, a, missing a,\n");
    }
}

=head2 sub add_to_all 


 subs a, add_to_all 
 add the following
 value after 
 all other operations
 are complete

=cut

sub add_to_all {

    my ( $self, $a ) = @_;
    if ( $a ne $empty_string ) {

        $suchw->{_a}    = $a;
        $suchw->{_note} = $suchw->{_note} . ' a=' . $suchw->{_a};
        $suchw->{_Step} = $suchw->{_Step} . ' a=' . $suchw->{_a};

    }
    else {
        print("suchw, add_to_all, missing add_to_all,\n");
    }
}

=head2 sub b 

 Multiply first header values by
 this constant

=cut

sub b {

    my ( $self, $b ) = @_;
    if ( $b ne $empty_string ) {

        $suchw->{_b}    = $b;
        $suchw->{_note} = $suchw->{_note} . ' b=' . $suchw->{_b};
        $suchw->{_Step} = $suchw->{_Step} . ' b=' . $suchw->{_b};

    }
    else {
        print("suchw, b, missing b,\n");
    }
}

=head2 sub c 

 Multiply second header values by
 this constant

=cut

sub c {

    my ( $self, $c ) = @_;
    if ( $c ne $empty_string ) {

        $suchw->{_c}    = $c;
        $suchw->{_note} = $suchw->{_note} . ' c=' . $suchw->{_c};
        $suchw->{_Step} = $suchw->{_Step} . ' c=' . $suchw->{_c};

    }
    else {
        print("suchw, c, missing c,\n");
    }
}

=head2 sub d

 After all calculations are complete
 divide the result by

=cut

sub d {

    my ( $self, $d ) = @_;
    if ( $d ne $empty_string ) {

        $suchw->{_d}    = $d;
        $suchw->{_note} = $suchw->{_note} . ' d=' . $suchw->{_d};
        $suchw->{_Step} = $suchw->{_Step} . ' d=' . $suchw->{_d};

    }
    else {
        print("suchw, d, missing d,\n");
    }
}

=head2 sub divide_all_by

 After all calculations are complete
 divide the result by

=cut

sub divide_all_by {

    my ( $self, $d ) = @_;
    if ( $d ne $empty_string ) {

        $suchw->{_d}    = $d;
        $suchw->{_note} = $suchw->{_note} . ' d=' . $suchw->{_d};
        $suchw->{_Step} = $suchw->{_Step} . ' d=' . $suchw->{_d};

    }
    else {
        print("suchw, divide_all_by, missing divide_all_by,\n");
    }
}

=head2 sub e 

 Raise the first header values to
 a given power

=cut

sub e {

    my ( $self, $e ) = @_;
    if ( $e ne $empty_string ) {

        $suchw->{_e}    = $e;
        $suchw->{_note} = $suchw->{_note} . ' e=' . $suchw->{_e};
        $suchw->{_Step} = $suchw->{_Step} . ' e=' . $suchw->{_e};

    }
    else {
        print("suchw, e, missing e,\n");
    }
}

=head2 sub f 

 Raise the second header values to
 a given power

=cut

sub f {

    my ( $self, $f ) = @_;
    if ( $f ne $empty_string ) {

        $suchw->{_f}    = $f;
        $suchw->{_note} = $suchw->{_note} . ' f=' . $suchw->{_f};
        $suchw->{_Step} = $suchw->{_Step} . ' f=' . $suchw->{_f};

    }
    else {
        print("suchw, f, missing f,\n");
    }
}

=head2 sub first_header 

 select the first header value to use

=cut

sub first_header {

    my ( $self, $key2 ) = @_;
    if ( $key2 ne $empty_string ) {

        $suchw->{_key2} = $key2;
        $suchw->{_note} = $suchw->{_note} . ' key2=' . $suchw->{_key2};
        $suchw->{_Step} = $suchw->{_Step} . ' key2=' . $suchw->{_key2};

    }
    else {
        print("suchw, first_header, missing first_header,\n");
    }
}

=head2 sub hdr1_exponent 

 Raise the first header values to
 a given power

=cut

sub hdr1_exponent {

    my ( $self, $e ) = @_;
    if ( $e ne $empty_string ) {

        $suchw->{_e}    = $e;
        $suchw->{_note} = $suchw->{_note} . ' e=' . $suchw->{_e};
        $suchw->{_Step} = $suchw->{_Step} . ' e=' . $suchw->{_e};

    }
    else {
        print("suchw, hdr1_exponent, missing hdr1_exponent,\n");
    }
}

=head2 sub hdr2_exponent 

 Raise the second header values to
 a given power

=cut

sub hdr2_exponent {

    my ( $self, $f ) = @_;
    if ( $f ne $empty_string ) {

        $suchw->{_f}    = $f;
        $suchw->{_note} = $suchw->{_note} . ' f=' . $suchw->{_f};
        $suchw->{_Step} = $suchw->{_Step} . ' f=' . $suchw->{_f};

    }
    else {
        print("suchw, hdr2_exponent, missing hdr2_exponent,\n");
    }
}

=head2 sub key1 

 select the result header value to use

=cut

sub key1 {

    my ( $self, $key1 ) = @_;
    if ( $key1 ne $empty_string ) {

        $suchw->{_key1} = $key1;
        $suchw->{_note} = $suchw->{_note} . ' key1=' . $suchw->{_key1};
        $suchw->{_Step} = $suchw->{_Step} . ' key1=' . $suchw->{_key1};

    }
    else {
        print("suchw, key1, missing key1,\n");
    }
}

=head2 sub key2 

 select the first header value to use

=cut

sub key2 {

    my ( $self, $key2 ) = @_;
    if ( $key2 ne $empty_string ) {

        $suchw->{_key2} = $key2;
        $suchw->{_note} = $suchw->{_note} . ' key2=' . $suchw->{_key2};
        $suchw->{_Step} = $suchw->{_Step} . ' key2=' . $suchw->{_key2};

    }
    else {
        print("suchw, key2, missing key2,\n");
    }
}

=head2 sub key3 

 select the second header value to use 

=cut

sub key3 {

    my ( $self, $key3 ) = @_;
    if ( $key3 ne $empty_string ) {

        $suchw->{_key3} = $key3;
        $suchw->{_note} = $suchw->{_note} . ' key3=' . $suchw->{_key3};
        $suchw->{_Step} = $suchw->{_Step} . ' key3=' . $suchw->{_key3};

    }
    else {
        print("suchw, key3, missing key3,\n");
    }
}

=head2 sub multiply_hdr1_by 

 Multiply first header values by
 this constant

=cut

sub multiply_hdr1_by {

    my ( $self, $b ) = @_;
    if ( $b ne $empty_string ) {

        $suchw->{_b}    = $b;
        $suchw->{_note} = $suchw->{_note} . ' b=' . $suchw->{_b};
        $suchw->{_Step} = $suchw->{_Step} . ' b=' . $suchw->{_b};

    }
    else {
        print("suchw, multiply_hdr1_by, missing multiply_hdr1_by,\n");
    }
}

=head2 sub multiply_hdr2_by 

 Multiply second header values by
 this constant

=cut

sub multiply_hdr2_by {

    my ( $self, $c ) = @_;
    if ( $c ne $empty_string ) {

        $suchw->{_c}    = $c;
        $suchw->{_note} = $suchw->{_note} . ' c=' . $suchw->{_c};
        $suchw->{_Step} = $suchw->{_Step} . ' c=' . $suchw->{_c};

    }
    else {
        print("suchw, multiply_hdr2_by, missing multiply_hdr2_by,\n");
    }
}

=head2 sub result_header 

 select the result header value to use

=cut

sub result_header {

    my ( $self, $key1 ) = @_;
    if ( $key1 ne $empty_string ) {

        $suchw->{_key1} = $key1;
        $suchw->{_note} = $suchw->{_note} . ' key1=' . $suchw->{_key1};
        $suchw->{_Step} = $suchw->{_Step} . ' key1=' . $suchw->{_key1};

    }
    else {
        print("suchw, result_header, missing result_header,\n");
    }
}

=head2 sub second_header 

 select the second header value to use 

=cut

sub second_header {

    my ( $self, $key3 ) = @_;
    if ( $key3 ne $empty_string ) {

        $suchw->{_key3} = $key3;
        $suchw->{_note} = $suchw->{_note} . ' key3=' . $suchw->{_key3};
        $suchw->{_Step} = $suchw->{_Step} . ' key3=' . $suchw->{_key3};

    }
    else {
        print("suchw, second_header, missing second_header,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 8;

    return ($max_index);
}

1;
