package Business::CompanyDesignator::SplitResult;

use Moose;
use utf8;
use warnings qw(FATAL utf8);
use Carp;
use namespace::autoclean;

has [ qw(before after designator designator_std) ] =>
  ( is => 'ro', isa => 'Str', required => 1 );
has 'records' => ( is => 'ro', isa => 'ArrayRef', required => 1 );

sub short_name {
  my $self = shift;
  return $self->before || $self->after // '';
}

sub extra {
  my $self = shift;
  return $self->before ? ($self->after // '') : '';
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Business::CompanyDesignator::SplitResult - class for modelling
L<Business::CompanyDesignator::split_designator> result records

=head1 SYNOPSIS

  # Returned by split_designator in scalar context
  $bcd = Business::CompanyDesignator->new;
  $res = $bcd->split_designator("Open Fusion Pty Ltd (Australia)");

  # Accessors
  say $res->designator;         # Pty Ltd (designator as found in input string)
  say $res->designator_std;     # Pty. Ltd. (standardised version of designator)
  say $res->before;             # Open Fusion (trimmed text before designator)
  say $res->after;              # (Australia) (trimmed text after designator)
  say $res->short_name;         # Open Fusion ($res->before || $res->after)
  say $res->extra;              # (Australia) ($res->before ? $res->after : '')

  # Designator records arrayref (since designator might be ambiguous and map to multiple)
  foreach (@{ $res->records }) {
    say join ", ", $_->long, $_->lang;
  }


=head1 ACCESSORS

=head2 designator()

If a designator is found, returns the matched designator as it exists in
the input string. Otherwise returns an empty string ('').

  say $res->designator;

=head2 designator_std()

If a designator is found, returns the standardised version of the designator
as it exists in the company designator dataset. This may or may not match
$res->designator().

  say $res->designator_std;

e.g. "Open Fusion Pty Ltd" would return a designator of 'Pty Ltd', but a
designator_std of 'Pty. Ltd.' (with the dots).

The designator_std version can be used to retrieve the matching dataset
record(s) using $bcd->records( $res->designator_short ).

=head2 before()

If a non-leading designator is found, returns the (whitespace-trimmed)
text before the designator. If a leading designator is found, returns
an empty string (''). If no designator is found, returns the full company
name i.e. the input.

  say $res->before;

=head2 after()

If a designator is found, returns the (whitespace-trimmed) text after the
designator, if any. Otherwise returns an empty string ('').

  say $res->after;

=head2 short_name()

If a non-leading designator is found, returns $res->before. If a leading
designator is found, returns, $res->after. That is, it returns the logical
'short name' of the company (stripped of the designator), for both trailing
and leading designators.

=head2 extra()

If a non-leading designator is found, returns $res->after. That is, it's any
extra text not include in $res->short_name, if any. Otherwise returns an
empty string ('').

=head1 AUTHOR

Gavin Carr <gavin@profound.net>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2013-2015 Gavin Carr

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
