package Authen::SASL::SASLprep;

use strict;
use utf8;
use warnings;
require 5.006_000;

our $VERSION = '1.100';
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(saslprep);

use Unicode::Stringprep;

use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;

my %C12_to_SPACE = ();
for(my $pos=0; $pos <= $#Unicode::Stringprep::Prohibited::C12; $pos+=2) 
{
  for(my $char = $Unicode::Stringprep::Prohibited::C12[$pos]; 
         defined $Unicode::Stringprep::Prohibited::C12[$pos]
	 && $char <= $Unicode::Stringprep::Prohibited::C12[$pos];
	 $char++) {
    $C12_to_SPACE{$char} = ' ';
  }
};

our $_saslprep_stored;
our $_saslprep_query;

sub saslprep {
  my ($input, $stored) = @_;
  splice @_, 1, 1; ## remove $stored

  if($stored) {
    goto &$_saslprep_stored;
  } else {
    goto &$_saslprep_query;
  }
}

BEGIN {
  my @_common_args = (
  3.2,
  [ \@Unicode::Stringprep::Mapping::B1,
    \%C12_to_SPACE ],
  'KC',
  [ \@Unicode::Stringprep::Prohibited::C12,
    \@Unicode::Stringprep::Prohibited::C21,
    \@Unicode::Stringprep::Prohibited::C22,
    \@Unicode::Stringprep::Prohibited::C3,
    \@Unicode::Stringprep::Prohibited::C4,
    \@Unicode::Stringprep::Prohibited::C5,
    \@Unicode::Stringprep::Prohibited::C6,
    \@Unicode::Stringprep::Prohibited::C7,
    \@Unicode::Stringprep::Prohibited::C8,
    \@Unicode::Stringprep::Prohibited::C9,
  ],
  1
  );

  our $_saslprep_stored = Unicode::Stringprep->new(
    @_common_args,
    1,
  );

  our $_saslprep_query = Unicode::Stringprep->new(
    @_common_args,
    0,
  );
};

1;
__END__

=encoding utf8

=head1 NAME

Authen::SASL::SASLprep - A Stringprep Profile for User Names and Passwords (RFC 4013)

=head1 SYNOPSIS

  use Authen::SASL::SASLprep;
  $output_query = saslprep $input;
  $output_stored = saslprep $stored;

=head1 DESCRIPTION

This module implements the I<SASLprep> specification, which describes how to
prepare Unicode strings representing user names and passwords for comparison.
SASLprep is a profile of the stringprep algorithm.

=head1 FUNCTIONS

This module implements a single function, C<saslprep>, which is exported by default.

=over 4

=item B<saslprep($input, [$stored]>

Processes C<$input> according to the I<SASLprep> specification and
returns the result.

If C<$input> contains characters not allowed for I<SASLprep>, it
throws an exception (so use C<eval> if necessary).

If the boolean parameter C<$stored> is true, an exception is also thrown when
characters are not allowed for stored strings (i.e., when characters are
unassigned in Unicode 3.2). The default is to prepare query strings, in which
unassigned characters are allowed.

=back

=head1 AUTHOR

Claus Färber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2009-2016 Claus Färber.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Stringprep>, S<RFC 4013> L<http://www.ietf.org/rfc/rfc4013.txt>

=cut
