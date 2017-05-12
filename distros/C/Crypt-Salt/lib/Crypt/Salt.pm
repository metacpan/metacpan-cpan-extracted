
package Crypt::Salt;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.01;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw (salt);
	@EXPORT_OK   = qw (salt);
	%EXPORT_TAGS = ();
}


=head1 NAME

Crypt::Salt - Module for generating a salt to be fed into crypt.

=head1 SYNOPSIS

  use Crypt::Salt;
  
  print crypt( "secret", salt() );


=head1 DESCRIPTION

The single exported subroutine in this module is for generating a salt suitable for being fed to crypt() and other similar functions.

=head1 BUGS

Please let the author know if any are caught

=head1 AUTHOR

	Jonathan Steinert
	hachi@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 salt

 Argument  : The first argument as passed will be used in numeric context as a count of how many characters you want returned in the salt, the default is 2. All other arguments are ignored.
 Returns   : A string of random characters suitable for use when being passed to the crypt() function

=cut

################################################## subroutine header end ##


sub salt
{
        my $length = 2;
	$length = $_[0] if exists $_[0];

	return join "", ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[map {rand 64} (1..$length)];
}


1;
