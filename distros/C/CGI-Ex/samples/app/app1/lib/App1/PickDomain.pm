package App1::PickDomain;

=head1 NAME

App1::PickDomain - handle this step of the App1 app

=cut

use strict;
use warnings;
use base qw(App1);

sub hash_swap {
    my $self = shift;
    return {
        remote_addr => $ENV{'REMOTE_ADDR'},
        time        => scalar(localtime),
    };
}

sub hash_validation {
    return {
        'group no_alert'   => 1,
        'group no_confirm' => 1,
        domain => {
            required   => 1,
            to_lower_case => 1,
            type       => 'DOMAIN',
            type_error => 'Please enter a valid domain',
        },
    };
}

sub finalize {
    my $self = shift;
    my $domain = $self->form->{'domain'};

    # contrived "check" for availability
    # in theory - these checks would also cache with something like memcache
    if ($domain =~ /^(\w+)\.com$/) { # for this test - .com isn't available
        $self->stash->{'domain_prefix'} = $1;
    } else {
        $self->stash->{'domain_available'} = 1;
    }

    return 1;
}

1;
