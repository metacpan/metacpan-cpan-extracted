package CSAF::Validator::Base;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Validator::Message;
use List::Util qw(first);

use Moo;
extends 'CSAF::Base';

has messages => (is => 'rw', default => sub { [] });
has tests    => (is => 'rw', default => sub { [] });

sub validate {
    my $self = shift;
    $self->exec_test($_) for (@{$self->tests});
    return @{$self->messages};
}

sub has_error {
    return (first { $_->type eq 'error' } @{$_[0]->messages}) ? 1 : 0;
}

sub has_warning {
    return (first { $_->type eq 'warning' } @{$_[0]->messages}) ? 1 : 0;
}

sub add_message {

    my ($self, %params) = @_;

    my $message = CSAF::Validator::Message->new(%params);
    push @{$self->messages}, $message;

}

sub exec_test {

    my ($self, $test_id) = @_;

    my $test_sub = "TEST_$test_id";
    $test_sub =~ tr/\./_/;

    if (my $code_ref = $self->can($test_sub)) {
        eval { $code_ref->($self) };
        Carp::croak "Failed to execute test $test_id: $@" if ($@);
        return 1;
    }

    Carp::carp "Missing test $test_id";

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::Base - Base class for CSAF validation

=head1 SYNOPSIS

    use CSAF::Validator::Base;

    my $v = CSAF::Validator::Base->new( csaf => $csaf );

=head1 DESCRIPTION


=head2 ATTRIBUTES

=over

=item messages

ARRAY of validation messages.

=item tests

ARRAY of test IDs.

=back


=head2 METHODS

L<CSAF::Validator::Base> inherits all methods from L<CSAF::Base> and implements the following new ones.

=over

=item add_message

Add new L<CSAF::Validator::Message> item.

    $v->add_message(
        type     => 'warning',
        category => 'optional',
        path     => '/document/tracking/initial_release_date',
        code     => '6.2.5',
        message  => 'Older Initial Release Date than Revision History'
    );

=item exec_test

Execute a single validation test.

    $v->exec_test('6.2.5');

=item has_error

Check if validation have error messages

    my @messages = $v->validate;

    if ($v->has_error) {
        say "Invalid CSAF document";
        say $_ for (@messages);
    }

=item has_warning

Check if validation have warning messages

    my @messages = $v->validate;

    if ($v->has_warning) {
        say "CSAF document with warnings";
        say $_ for (@messages);
    }

=item validate

Execute all validation tests and return all validation messages.

    my @messages = $v->validate;
    say $_ for (@messages);

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
