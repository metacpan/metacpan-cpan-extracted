=head1 NAME

Data::Quantity - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Data::Quantity;
  blah blah blah

=head1 DESCRIPTION

Data::Quantity is a framework for blessed scalar values that can have appropriate parsing and printing methods called on them.

=cut

########################################################################

package Data::Quantity;

require 5;
use strict;
use warnings;

use vars qw( $VERSION @ISA @EXPORT_OK );
$VERSION = 0.001;

push @ISA, qw( Exporter );
push @EXPORT_OK, qw( formatted_quantity );

use Class::MakeMethods;
use Class::MakeMethods::Template::ClassName;

# formatted_quantity($q_type, $value)
# formatted_quantity($q_type, $value, $style_or_scale)
sub formatted_quantity {
  named_subclass( shift )->readable_value( @_ );
}

# $subclass = named_subclass( $packagename );
sub named_subclass {
  my $q_type = shift or croak "Must specify quantity type.";
  
  my $subclass = Class::MakeMethods::Template::ClassName::_unpack_subclass( 
				'Data::Quantity', $q_type );
  my $class = Class::MakeMethods::Template::ClassName::_require_class( $class );
}

########################################################################

=head1 SEE ALSO

See L<Data::Quantity::ReadMe> for distribution and license information.

=cut

########################################################################

1;
