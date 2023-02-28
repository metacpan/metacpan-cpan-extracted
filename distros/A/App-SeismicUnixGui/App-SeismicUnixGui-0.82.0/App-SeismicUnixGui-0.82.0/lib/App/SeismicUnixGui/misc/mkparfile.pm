package App::SeismicUnixGui::misc::mkparfile;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: mkparfile 
 AUTHOR: Juan Lorenzo 
 DATE:   Sept. 15 2015 
 DESCRIPTION: 
 Version: 1

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  



=head4 CHANGES and their DATES

=cut

=head2 SEISMIC UNIX NOTES

 MKPARFILE - convert ascii to par file format 				
 									
 mkparfile <stdin >stdout 						
 									
 Optional parameters:							
 	string1="par1"	first par string			
 	string2="par2"	second par string			
 									
 This is a tool to convert values written line by line to parameter 	
 vectors in the form expected by getpar.  For example, if the input	
 file looks like:							
 	t0 v0								
 	t1 v1								
	...								
 then									
	mkparfile <input >output string1=tnmo string2=vnmo		
 yields:								
	tnmo=t0,t1,...							
	vnmo=v0,v1,...							
 			

=head3 STEPS

 1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs 

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

=cut

my $mkparfile = {
    _string1 => '',
    _string2 => '',
    _note    => '',
    _Step    => ''
};

# define a value

my $newline = '';

#sub test {
# my ($test,@value) = @_;
#print("\$test or the first scalar  'holds' a  HASH $test
# that represents the name of the
# subroutine you are trying to use and all its needed components\n");
# print("\@value, the second scalar is something 'real' you put in, i.e., @value\n\n");
# print("new line is $newline\n");
#my ($sugain->{_Step}) = $sugain->{_Step} +1;
#print("Share step is first $sugain->{_Step}\n");

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $mkparfile->{_string1} = '';
    $mkparfile->{_string2} = '';
    $mkparfile->{_note}    = '';
    $mkparfile->{_Step}    = '';
}

=head2 subroutine string1 

  sets first data column  in files

=cut

sub string1 {
    my ( $variable, $string1 ) = @_;
    $mkparfile->{_string1} = $string1 if defined($string1);
    $mkparfile->{_note} =
      $mkparfile->{_note} . ' string1=' . $mkparfile->{_string1};
    $mkparfile->{_Step} =
      $mkparfile->{_Step} . ' string1=' . $mkparfile->{_string1};
}

=head2 subroutine string2 

  sets first data column  in files

=cut

sub string2 {
    my ( $variable, $string2 ) = @_;
    $mkparfile->{_string2} = $string2 if defined($string2);
    $mkparfile->{_note} =
      $mkparfile->{_note} . ' string2=' . $mkparfile->{_string2};
    $mkparfile->{_Step} =
      $mkparfile->{_Step} . ' string2=' . $mkparfile->{_string2};
}

=head2 subroutine Step 

  collects all program switches with the correct
  format 

=cut

sub Step {
    $mkparfile->{_Step} = 'mkparfile' . $mkparfile->{_Step};
    return $mkparfile->{_Step};
}

=head2 subroutine note 

   collects programs and their parameters for later logging

=cut

sub note {
    $mkparfile->{_note} = $mkparfile->{_note};
    return $mkparfile->{_note};
}

=head3 Warnings for programmers

 packages must end with
 1;

=cut

1;
