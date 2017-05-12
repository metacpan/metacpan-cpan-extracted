#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::HelperRole::SleepTimeout;
{
  $Action::Retry::Strategy::HelperRole::SleepTimeout::VERSION = '0.24';
}

# ABSTRACT: Helper to be consumed by Action::Retry Strategies, to enable giving up retrying when the sleep_time is too big

use Moo::Role;

has max_sleep_time => (
    is => 'ro',
    lazy => 1,
    default => sub { undef },
);

around needs_to_retry => sub {
    my $orig = shift;
    my $self = shift;
    defined $self->max_sleep_time
      or return $orig->($self, @_);
    $orig->($self, @_) && $self->compute_sleep_time < $self->max_sleep_time
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy::HelperRole::SleepTimeout - Helper to be consumed by Action::Retry Strategies, to enable giving up retrying when the sleep_time is too big

=head1 VERSION

version 0.24

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
