package Data::Random::String;

use strict;
use warnings;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&create_random_string);
%EXPORT_TAGS = ( DEFAULT => [qw(&create_random_string)]);

$VERSION = '0.03';


sub create_random_string
{
  	my $self = shift;

	my %args = (@_);
	my $length = $args{length} || '32';
	my $contains = $args{contains} || 'alphanumeric';

	my $rstring  ="";
			
	for(my $i=0 ; $i< $length ;)
	{   
		my $j = chr(int(rand(127)));
	
		if(($j =~ /[0-9]/) and (lc($contains) eq 'numeric'))
		{   
			$rstring .=$j;
			$i++;
		}

		if(($j =~ /[a-zA-Z]/) and (lc($contains) eq 'alpha'))
		{   
			$rstring .=$j;
			$i++;
		}

		if(($j =~ /[a-zA-Z0-9]/) and (lc($contains) eq 'alphanumeric'))
		{   
			$rstring .=$j;
			$i++;
		}
	}
	return $rstring;
}

1;


__END__


=head1 NAME

Data::Random::String - Perl extension for creating random strings

=head1 SYNOPSIS

  use Data::Random::String;

  # Create a new random string for use in your application
  my $random_string = Data::Random::String->create_random_string(length=>'32', contains=>'alpha');

  if ($random_string)
  {
  	print "The random string created is $random_string";
  } else {
	print "Unable to create random string";
  }

=head1 DESCRIPTION

Data::Random::String provides a simple interface for generating random
strings that contain numeric, alpha or alphanumeric characters.

=head1 CREATING A RANDOM STRING

=head2 C< create_random_string >

  my $random_string = Data::Random::String->create_random_string(length=>'$length', contains=>'$character_group');

This method returns a new random string that abides by the parameters specified
when calling it.

There are two optional parameters as follows:

=over

=item C<< legth >> 
Used to specify the exact length of the generated string in characters. The default length is 32 characters if no other value is given.

=item C<< contains >> 
Identifies the class of characters that can be used to populate this random
string. 

The choices are alpha ([a-z,A-Z]), numeric ([0-9]) and alphanumeric ([a-z,A-Z,0-9]).

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-random-string@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Ioakim (Makis) Marmaridis, E<lt>makis.marmaridis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ioakim (Makis) Marmaridis, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


