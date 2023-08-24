package My::Test::Plugin;

our $VERSION = '0.01';

use parent 'Form::Tiny::Plugin';
use experimental 'signatures';

sub plugin ( $self, $caller, $context ) {
    return { meta_roles => [ __PACKAGE__ . '::Meta', ], };
}

1;

