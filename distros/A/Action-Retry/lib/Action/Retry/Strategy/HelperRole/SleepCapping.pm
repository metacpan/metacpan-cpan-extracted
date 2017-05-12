#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::HelperRole::SleepCapping;
{
  $Action::Retry::Strategy::HelperRole::SleepCapping::VERSION = '0.24';
}

# ABSTRACT: Helper to be consumed by Action::Retry Strategies, to enable capping the sleep time

use Moo::Role;

use List::Util qw(min);

has capped_sleep_time => (
    is => 'ro',
    lazy => 1,
    default => sub { undef },
);

around compute_sleep_time => sub {
    my $orig = shift;
    my $self = shift;
    
    return defined $self->capped_sleep_time
      ? min($orig->($self, @_), $self->capped_sleep_time)
      : $orig->($self, @_);

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy::HelperRole::SleepCapping - Helper to be consumed by Action::Retry Strategies, to enable capping the sleep time

=head1 VERSION

version 0.24

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
