#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::Fibonacci;
{
  $Action::Retry::Strategy::Fibonacci::VERSION = '0.24';
}

# ABSTRACT: Fibonacci incrementation of sleep time strategy

use Math::Fibonacci qw(term);

use Moo;



with 'Action::Retry::Strategy';
with 'Action::Retry::Strategy::HelperRole::RetriesLimit';
with 'Action::Retry::Strategy::HelperRole::SleepTimeout';


has initial_term_index => (
    is => 'ro',
    lazy => 1,
    default => sub { 0 },
);

# the current sequence term index
has _current_term_index => (
    is => 'rw',
    lazy => 1,
    default => sub { $_[0]->initial_term_index },
    init_arg => undef,
    clearer => 1,
);



has multiplicator => (
    is => 'ro',
    lazy => 1,
    default => sub { 1000 },
);

sub reset {
    my ($self) = @_;
    $self->_clear_current_term_index;
    return;
}

sub compute_sleep_time {
    my ($self) = @_;
#    print STDERR " -- sleep time is " . term($self->_current_term_index) * $self->multiplicator . "\n";
    return term($self->_current_term_index) * $self->multiplicator;
}

sub next_step {
    my ($self) = @_;
    $self->_current_term_index($self->_current_term_index + 1);
    return;
}

sub needs_to_retry { 1 }

# Inherited from Action::Retry::Strategy::HelperRole::RetriesLimit


# Inherited from Action::Retry::Strategy::HelperRole::SleepTimeout


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy::Fibonacci - Fibonacci incrementation of sleep time strategy

=head1 VERSION

version 0.24

=head1 SYNOPSIS

To be used as strategy in L<Action::Retry>

=head1 DESCRIPTION

Sleeps incrementally by following the Fibonacci sequence : F(i) = F(i-1) +
F(i-2) starting from 0,1. By default F(0) = 0, F(1) = 1, F(2) = 1, F(3) = 2

=head1 ATTRIBUTES

=head2 initial_term_index

  ro, Int, defaults to 0

Term number of the Fibonacci sequence to start at. Defaults to 0

=head2 multiplicator

  ro, Int, defaults to 1000

Number of milliseconds that will be multiplied by the fibonacci sequence term
value. Defaults to 1000 ( 1 second )

=head2 max_retries_number

  ro, Int, defaults to 10

The number of times we should retry before giving up. If set to undef, never stop retrying

=head2 max_sleep_time

  ro, Int|Undef, defaults to undef

If Action::Retry is about to sleep more than this number ( in milliseconds ),
stop retrying. If set to undef, never stop retrying

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
