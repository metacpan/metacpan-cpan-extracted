package Datahub::Factory::Flash;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use Moo::Role;
use MooX::Aliases;
use Term::ANSIColor qw(:constants);
use namespace::clean;

has verbose => ( is => 'rw' );

sub info {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say YELLOW, $msg;
    }
}

sub error {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say BRIGHT_RED, "\x{2716} - $msg";
    }
}

sub success {
    my ($self, $msg) = @_;
    if (defined $self->verbose) {
        local $Term::ANSIColor::AUTORESET = 1;
        say BRIGHT_GREEN, "\x{2714} - $msg";
    }
}

1;

__END__

=head1 NAME

Datahub::Factory::Flash - Pretty verbose flash messages

=head1 DESCRIPTION

Output pretty verbose messages on the command line interface.

=head1 USAGE

The C<verbose> flag is a boolean used to enables or disable the output fo messages. Messages will be outputed by default to STDOUT. This module currently supports three types of messages C<info>, C<error> and C<success>. The ouput is styled using L<Term::ANSIColor>.

This package is a L<Moo::Role>.

For example, consider this module:

    package Datahub::Factory::Foo;

    use Moo;
    with 'Datahub::Factory::Flash';

    sub messaging {
        $self->{verbose} = 1;

        $self->info("An info message");
        $self->error("An error message");
        $self->success("A success message");
    }

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
