package Crop::Unit;

=pod

=head1 NAME

Crop::Unit - Unit utilities for the Crop framework

=head1 SYNOPSIS

    use Crop::Unit;
    # ...usage...

=head1 DESCRIPTION

Crop::Unit provides unit-related utilities for the Crop framework.

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

=cut

use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Unit
	Units of phisical params.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	name  - name for use as the code of unit
	value - output format; enum (asis,int)
=cut
our %Attributes = (
	name  => {mode => 'read'},
	value => {mode => 'read'},
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'unit' string
=cut
sub Table { 'unit' }

1;
