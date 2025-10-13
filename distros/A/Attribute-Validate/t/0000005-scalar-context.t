use strict;
use warnings;
use lib 'lib';

use Attribute::Validate qw/anon_requires/;

use Test::Exception;
use Test::More tests => 8;

{
    sub only_scalar_context : ScalarContext {
    }
    eval { only_scalar_context(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    lives_ok {
        my $lawful = only_scalar_context();
    } 'Trying to store in scalar scalar context sub works';
    dies_ok {
        only_scalar_context();
    } 'Trying to use scalar context sub in void context dies';
    dies_ok {
        my @a = only_scalar_context();
    } 'Using scalar context sub in list context dies';
}

{
    sub never_scalar_context : NoScalarContext {
        return (1);
    }
    eval { my $a = never_scalar_context(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    dies_ok {
        my $scalar = never_scalar_context();
    } 'Storing in scalar no scalar context sub dies';
    lives_ok {
        my @lawful = never_scalar_context();
    } 'Storing in list no scalar context sub works';
    lives_ok {
        never_scalar_context();
    } 'Not trying to do anything with the return of no scalar context sub works';
}


