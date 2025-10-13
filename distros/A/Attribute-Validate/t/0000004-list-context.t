use strict;
use warnings;
use lib 'lib';

use Attribute::Validate qw/anon_requires/;

use Test::Exception;
use Test::More tests => 8;

{
    sub only_use_in_list_context : ListContext {
    }
    eval { my $a = only_use_in_list_context(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    dies_ok {
        my $lawless = only_use_in_list_context();
    } 'Trying to store list context sub return in scalar dies';
    dies_ok {
        only_use_in_list_context();
    } 'Trying to use list context sub in void context dies';
    lives_ok {
        my @a = only_use_in_list_context();
    } 'Using list context sub in list context works correctly';
}

{
    sub never_use_in_list_context : NoListContext {
        return (1);
    }
    eval { my @a = never_use_in_list_context(undef); };
    unlike $@, qr@Attribute/Validate@,
      'Doesn\'t reference the module in the errors';

    lives_ok {
        my $lawful = never_use_in_list_context();
    } 'Storing in scalar no list context sub works';
    dies_ok {
        my @lawful = never_use_in_list_context();
    } 'Storing in array no list context sub dies';
    lives_ok {
        never_use_in_list_context();
    } 'Not trying to do anything with the return of no list context sub works';
}


