package TestClass;

use strict;
use warnings;

use parent qw( Test::Class );

use Test::More;

use Crypt::Perl::BigInt ();

use constant fail_if_returned_early => 1;

sub runtests {
    my ($self, @args) = @_;

    diag sprintf(
        'Math::BigInt %s (backend: %s %s)',
        $Math::BigInt::VERSION,
        Math::BigInt->config('lib'),
        Math::BigInt->config('lib_version'),
    );

    return $self->SUPER::runtests(@args);
}

1;
