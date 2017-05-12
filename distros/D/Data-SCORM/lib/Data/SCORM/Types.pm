package Data::SCORM::Types;

use Any::Moose;
use Any::Moose qw/ X::AttributeHelpers /;
use Any::Moose qw/ ::Util::TypeConstraints /;

coerce 'Bool'
	=> from 'Str'
		=> via {
			{ false => undef,
			  true  => 1, }->{$_}
		       };


no Any::Moose;

1;
