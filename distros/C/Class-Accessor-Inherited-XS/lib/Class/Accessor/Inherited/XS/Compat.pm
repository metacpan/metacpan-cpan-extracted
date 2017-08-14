package Class::Accessor::Inherited::XS::Compat;
use 5.010001;
use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw/mk_type_accessors mk_inherited_accessors mk_class_accessors mk_varclass_accessors mk_object_accessors/;

require Class::Accessor::Inherited::XS;

sub mk_type_accessors {
    my ($class, $type) = (shift, shift);

    {
        require mro;
        state $seen = {};
        state $message = <<EOF;
Inheriting from 'Class::Accessor::Inherited::XS' is deprecated, this behavior will be removed in the next version! To use __PACKAGE__->mk_${type}_accessors form inherit from 'Class::Accessor::Inherited::XS::Compat' instead.
EOF
        warn $message if !$seen->{$class}++ && scalar grep { $_ eq 'Class::Accessor::Inherited::XS' } @{ mro::get_linear_isa($class) };
    }

    my ($installer, $clone_arg) = Class::Accessor::Inherited::XS->_type_installer($type);

    for my $entry (@_) {
        if (ref($entry) eq 'ARRAY') {
            $installer->($class, @$entry);

        } else {
            $installer->($class, $entry, $clone_arg && $entry);
        }
    }
}

sub mk_inherited_accessors {
    mk_type_accessors(shift, 'inherited', @_);
}

sub mk_class_accessors {
    mk_type_accessors(shift, 'class', @_);
}

sub mk_varclass_accessors {
    mk_type_accessors(shift, 'varclass', @_);
}

sub mk_object_accessors {
    mk_type_accessors(shift, 'object', @_);
}

1;
