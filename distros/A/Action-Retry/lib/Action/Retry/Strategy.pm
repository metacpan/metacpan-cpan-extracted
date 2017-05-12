#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry::Strategy;
{
  $Action::Retry::Strategy::VERSION = '0.24';
}

# ABSTRACT: Srategy role that any Action::Retry strategy should consume

use Moo::Role;

requires 'needs_to_retry';
requires 'compute_sleep_time';
requires 'next_step';
requires 'reset';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry::Strategy - Srategy role that any Action::Retry strategy should consume

=head1 VERSION

version 0.24

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
