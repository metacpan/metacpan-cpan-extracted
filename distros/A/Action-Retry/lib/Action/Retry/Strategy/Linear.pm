#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::Linear;
{
  $Action::Retry::Strategy::Linear::VERSION = '0.24';
}

# ABSTRACT: Linear incrementation of sleep time strategy

use Moo;


with 'Action::Retry::Strategy';
with 'Action::Retry::Strategy::HelperRole::RetriesLimit';
with 'Action::Retry::Strategy::HelperRole::SleepTimeout';


has initial_sleep_time => (
    is => 'ro',
    lazy => 1,
    default => sub { 1000 },
);

# the current sleep time, as it's computed
has _current_sleep_time => (
    is => 'rw',
    lazy => 1,
    default => sub { $_[0]->initial_sleep_time },
    init_arg => undef,
    clearer => 1,
);


has multiplicator => (
    is => 'ro',
    lazy => 1,
    default => sub { 2 },
);

sub reset {
    my ($self) = @_;
    $self->_clear_current_sleep_time;
    return;
}

sub compute_sleep_time {
    my ($self) = @_;
    return $self->_current_sleep_time;
}

sub next_step {
    my ($self) = @_;
    $self->_current_sleep_time($self->_current_sleep_time * $self->multiplicator);
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

Action::Retry::Strategy::Linear - Linear incrementation of sleep time strategy

=head1 VERSION

version 0.24

=head1 SYNOPSIS

To be used as strategy in L<Action::Retry>

=head1 ATTRIBUTES

=head2 initial_sleep_time

  ro, Int, defaults to 1000 ( 1 second )

The number of milliseconds to wait for the first retry

=head2 multiplicator

  ro, Int, defaults to 2

Number multiplied by the last sleep time. E.g. if set to 2, the time between
two retries will double. If set to 1, it'll remain constant. Defaults to 2

=head2 max_retries_number

  ro, Int|Undef, defaults to 10

The number of times we should retry before giving up. If set to undef, never
stop retrying.

=head2 max_sleep_time

  ro, Int|Undef, defaults to undef

If Action::Retry is about to sleep more than this number ( in milliseconds ),
stop retrying. If set to undef, never stop retrying.

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
