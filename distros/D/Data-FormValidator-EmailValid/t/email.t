#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Data::FormValidator;
use Data::FormValidator::EmailValid qw(FV_email_filter FV_email);

###############################################################################
# Check and see if we have access to a DNS server which can resolve a known
# domain for us.  If we don't, we'll have to skip anything that relies on
# "-mxcheck".
my $known_good = eval { Email::Valid->address(-address => 'cpan@howlingfrog.com', -mxcheck => 1) };
my $known_bad  = eval { Email::Valid->address(-address => 'this@does.not.exist.howlingfrog.com', -mxcheck => 1) };
my $have_good_dns = $known_good && !$known_bad;

###############################################################################
subtest 'Constraint' => sub {
    plan skip_all => 'DNS missing, or failing to properly resolve' unless ($have_good_dns);

    my $results = Data::FormValidator->check(
        {
            good      => 'cpan@howlingfrog.com',
            bad_no_mx => 'this@does.not.exist.howlingfrog.com',
        },
        {
            required           => [qw( good bad_no_mx )],
            constraint_methods => {
                good      => FV_email(),
                bad_no_mx => FV_email(),
            },
        },
    );

    ok $results->valid('good'), 'good e-mail is valid';
    ok !$results->valid('bad_no_mx'), 'e-mail with no MX record is invalid';
};

###############################################################################
subtest 'Filter - valid' => sub {
    my $results = Data::FormValidator->check(
        {
            good           => 'cpan@howlingfrog.com',
            with_name      => 'Graham TerMarsch <cpan@howlingfrog.com>',
            mixed_case     => 'cPaN@HowlingFrog.com',
            case_preserved => 'cPaN@HowlingFrog.com',
            no_mx_check    => 'test@this.domain.does.not.exist.howlingfrog.com',
        },
        {
            required      => [qw( good with_name mixed_case case_preserved no_mx_check )],
            field_filters => {
                good           => FV_email_filter(),
                with_name      => FV_email_filter(),
                mixed_case     => FV_email_filter(),
                case_preserved => FV_email_filter(lc => 0),
                no_mx_check    => FV_email_filter(),
            },
        },
    );

    is $results->valid('good'),           'cpan@howlingfrog.com',                            'valid e-mail';
    is $results->valid('with_name'),      'cpan@howlingfrog.com',                            'e-mail with name';
    is $results->valid('mixed_case'),     'cpan@howlingfrog.com',                            'e-mail in mixed case';
    is $results->valid('case_preserved'), 'cPaN@HowlingFrog.com',                            'e-mail with case preserved';
    is $results->valid('no_mx_check'),    'test@this.domain.does.not.exist.howlingfrog.com', 'MX check is not enabled when used as a filter';
};

###############################################################################
subtest 'Filter - invalid' => sub {
    my $results = Data::FormValidator->check(
        {
            no_domain    => 'test@',
            no_user      => '@howlingfrog.com',
            not_an_email => 'this is not an e-mail address',
        },
        {
            required      => [qw( no_domain no_user not_an_email )],
            field_filters => {
                no_domain    => FV_email_filter(),
                no_user      => FV_email_filter(),
                not_an_email => FV_email_filter(),
            },
        },
    );

    ok !$results->valid('no_domain'),    'missing domain';
    ok !$results->valid('no_user'),      'missing username';
    ok !$results->valid('not_an_email'), 'not an e-mail address';
};

###############################################################################
done_testing();
