package Acme::PricelessMethods;

use 5.006;
use warnings;
use strict;

our $VERSION = '0.01';

# ###### Implementation ###########

sub new {
    my $self = shift;

    my $object = { universe => 1 };

    return bless $object, $self;
}

sub is_perl_installed {
    my $self = shift;

    # let's check if perl is somewhere around here...
    return 1 if defined $^X;
}

sub is_machine_on {
    my $self = shift;

    # indeed, it won't return the proper 1,
    # but hey, it's the thought that counts
    return 1 if return 1;
}

sub universe_still_exists {
    my $self = shift;

    # check if universe still exists
    return 1 if defined $self->{'universe'};
}

sub is_program_running {
    my $self = shift;

    # we're assuming that if the version of the interpreter is defined,
    # it's for a good reason
    return 1 if defined $^V;
}

sub is_time_moving_forward {
    my $self = shift;

    # time probably is moving forward, but one can never be too sure
    my $before = time;
    sleep 2;
    my $after = time;

    return $after - $before;
}

sub is_true_true {
    my $self = shift;

    # if 1 is true, we return 1
    if (1) {
        return 1;
    }
    # if 1 is not true, we return false, which is 1
    else {
        return 1;
    }
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Acme-PricelessMethods - Acme-PricelessMethods


=head1 VERSION

This document describes Acme-PricelessMethods version 0.01


=head1 SYNOPSIS

    use Acme::PricelessMethods;

    my $acmer = Acme::PricelessMethods->new;

    $acmer->universe_still_exists() or exit;

=head1 DESCRIPTION

Signing up on Perlmonks... free...

Learning Perl... $40...

Attending a YAPC... $100...

Perl training at a YAPC... $200...

Being able to create this module... Priceless...

=head1 INTERFACE 

=head2 Program Interface

=head3 new

Creates a new Acme-PricelessMethods object.

    my $acmer = Acme-PricelessMethods->new();

=head3 is_perl_installed

Returns true if perl is available somewhere.

    if ( $acmer->is_perl_installed ) {
        # do something with perl
    }

=head3 is_machine_on

Returns true if the mochine is on.

    if ( $acmer->is_machine_on ) {
        # do something with the machine
    }

=head3 universe_still_exists

Returns true if universe still exists.

    if ( $acmer->universe_still_exists ) {
        # do something with universe
    }

=head3 is_program_running

Returns true if the program is running.

    if ( $acmer->is_program_running ) {
        # do something
    }

=head3 is_time_moving_forward

Returns true if time is moving forward.

    if ( $acmer->is_time_moving_forward ) {
        # do something
    }
    else {
        # undo something (might not work if time is stopped)
    }

=head3 is_true_true

Returns true if true is true.

    if ( $acmer->is_true_true ) {
        # use true
    }

=head1 AUTHOR

Jose Castro  C<< <cog@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
