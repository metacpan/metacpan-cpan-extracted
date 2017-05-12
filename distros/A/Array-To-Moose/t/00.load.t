use Test::More tests => 1;

BEGIN {
use_ok( 'Array::To::Moose',
        qw( array_to_moose throw_nonunique_keys throw_multiple_rows
            set_class_ind set_key_ind
            _check_descriptor _check_subobj
            _check_ref_attribs _check_non_ref_attribs
          )
      );
}

diag( "Testing Array::To::Moose $Array::To::Moose::VERSION" );
