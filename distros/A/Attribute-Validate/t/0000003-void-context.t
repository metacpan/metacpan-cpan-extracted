use strict;
use warnings;
use lib 'lib';

use Attribute::Validate qw/anon_requires/;

use Test::Exception;
use Test::More tests => 10;

{
    sub doesnt_return : VoidContext {
    }
    eval { my $a = doesnt_return(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    dies_ok {
        my $lawless = doesnt_return();
    } 'Trying to store void context sub return dies';
    dies_ok {
        my @lawless = doesnt_return();
    } 'Trying to store void context sub return dies even in list context';
    dies_ok {
        my $lawless = 1 + doesnt_return();
    } 'Trying to use void context sub dies';
    lives_ok {
        doesnt_return();
    } 'Not trying to do anything with the return works';
}

{
    sub returns : NoVoidContext {
        return (1);
    }
    eval { returns(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    lives_ok {
        my $lawful = returns();
    } 'Storing in scalar no void context sub works';
    lives_ok {
        my @lawful = returns();
    } 'Storing in array no void context sub works';
    lives_ok {
        my $lawful = 1 + returns();
    } 'Trying to use no void context sub works';
    dies_ok {
        returns();
    } 'Not trying to do anything with the return of no void sub dies';
}


