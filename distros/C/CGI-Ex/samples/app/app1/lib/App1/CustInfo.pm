package App1::CustInfo;

=head1 NAME

App1::CustInfo - enter user info and verify it

=cut

use strict;
use warnings;
use base qw(App1);
use CGI::Ex::Dump qw(debug);

sub hash_swap {
    my $self = shift;
    return {
        countries => $self->_countries,
    };
}

sub hash_fill {
    return if shift->ready_validate;
    return {country => 'US'};
}

sub hash_validation {
    my $self = shift;
    return {
        'group no_alert'   => 1,
        'group no_confirm' => 1,
        'group onevent'    => [qw(change blur submit)],
        first_name => {
            required => 1,
            max_len  => 50,
            custom   => sub { my ($key, $val) = @_; $val ne 'Matt' },
            custom_error => 'Too many people named Matt - please use a different first name',
        },
        last_name => {
            required => 1,
            max_len  => 50,
            min_len  => 2,
        },
        password => {
            required     => 1,
            max_len      => 15,
            match        => 'm/[a-z]/i',
            match_error  => 'Password must contain a letter',
            match2       => 'm/[0-9]/',
            match2_error => 'Password must contain a number',
        },
        password2 => {
            equals => 'password',
        },
        country => {
            required => 1,
            custom   => sub { my ($key, $val) = @_; $self->_countries->{$val} },
            custom_error => "Please pick from the list of valid countries",
        }
    };
}

sub _countries {
    # this is better off in a database
    return {
        US => "United States",
        CA => "Canada",
        MX => "Mexico",
    };
}

1;
