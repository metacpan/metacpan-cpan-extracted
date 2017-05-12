#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy::HelperRole::RetriesLimit;
{
  $Action::Retry::Strategy::HelperRole::RetriesLimit::VERSION = '0.24';
}

# ABSTRACT: Helper to be consumed by Action::Retry Strategies, to enable giving up retrying after a number of retries

use Moo::Role;

has max_retries_number => (
    is => 'ro',
    lazy => 1,
    default => sub { 10 },
);

# the current number of retries
has _current_retries_number => (
    is => 'rw',
    lazy => 1,
    default => sub { 0 },
    init_arg => undef,
    clearer => 1,
);

around needs_to_retry => sub {
    my $orig = shift;
    my $self = shift;
    defined $self->max_retries_number
      or return $orig->($self, @_);
    $orig->($self, @_) && $self->_current_retries_number < $self->max_retries_number
};

after next_step => sub {
    my ($self) = @_;
    $self->_current_retries_number($self->_current_retries_number + 1);
};

after reset => sub {
    my ($self) = @_;
    $self->_clear_current_retries_number;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy::HelperRole::RetriesLimit - Helper to be consumed by Action::Retry Strategies, to enable giving up retrying after a number of retries

=head1 VERSION

version 0.24

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
