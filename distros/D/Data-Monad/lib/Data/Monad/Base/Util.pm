package Data::Monad::Base::Util;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(list);

sub list { wantarray ? @_ : shift }

1;
__END__

=head1 NAME

Data::Monad::Base::Util - Utilities for my own use.

=head1 SYNOPSIS

  use Data::Monad::Base::Util qw(list);
  sub a_function {
      my ($x, $y, $z) = @_;
      my @results = ...;
      return list @results;
  }

=head1 DESCRIPTION

This is a utility class.

=head1 FUNCTIONS

=over 4

=item return list @results;

Return values of an array as one list even if it called on scalar context.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

