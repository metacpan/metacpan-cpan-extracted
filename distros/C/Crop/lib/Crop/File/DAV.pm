package Crop::File::DAV;
use base qw/ Crop::File /;

=begin nd
Class: Crop::File::DAV
	File stored by remote DAV server.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util;

use Crop::Debug;

=begin nd
Constructor: new (@attr)
	Set file type.
	
	Specifying explicit type is not allowed.
	
Parameters:
	%attr - class attributes
	
Returns:
	$self - ok
	undef - error
=cut
sub new {
	my ($class, @attr) = @_;
	my $attr = expose_hashes \@attr;
	
	$class->SUPER::new(
		%$attr,
		warehouse => 'DAV',  # parent Constructor replace this attribute to integer value
	);
}

1;
