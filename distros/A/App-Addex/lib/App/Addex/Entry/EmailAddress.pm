use strict;
use warnings;
package App::Addex::Entry::EmailAddress 0.027;
# ABSTRACT: an address book entry's email address

#pod =head1 SYNOPSIS
#pod
#pod An App::Addex::Entry::EmailAddress object represents, well, an addess for an
#pod entry.
#pod
#pod =method new
#pod
#pod   my $address = App::Addex::Entry::EmailAddress->new("dude@example.aero");
#pod
#pod   my $address = App::Addex::Entry::EmailAddress->new(\%arg);
#pod
#pod Valid arguments are:
#pod
#pod   address - the contact's email address
#pod   label   - the label for this contact (home, work, etc)
#pod             there is no guarantee that labels are defined or unique
#pod
#pod   sends    - if true, this address may send mail; default: true
#pod   receives - if true, this address may receive mail; default: true
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  $arg = { address => $arg } if not ref $arg;
  undef $arg->{label} if defined $arg->{label} and not length $arg->{label};

  for (qw(sends receives)) {
    $arg->{$_} = 1 unless exists $arg->{$_};
  }

  bless $arg => $class;
}

#pod =method address
#pod
#pod This method returns the email address as a string.
#pod
#pod =cut

use overload '""' => 'address';

sub address {
  $_[0]->{address}
}

#pod =method label
#pod
#pod This method returns the address label, if any.
#pod
#pod =cut

sub label {
  $_[0]->{label}
}

#pod =method sends
#pod
#pod =method receives
#pod
#pod =cut

sub sends    { $_[0]->{sends} }
sub receives { $_[0]->{receives} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::Entry::EmailAddress - an address book entry's email address

=head1 VERSION

version 0.027

=head1 SYNOPSIS

An App::Addex::Entry::EmailAddress object represents, well, an addess for an
entry.

=head1 PERL VERSION SUPPORT

This module has the same support period as perl itself:  it supports the two
most recent versions of perl.  (That is, if the most recently released version
is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $address = App::Addex::Entry::EmailAddress->new("dude@example.aero");

  my $address = App::Addex::Entry::EmailAddress->new(\%arg);

Valid arguments are:

  address - the contact's email address
  label   - the label for this contact (home, work, etc)
            there is no guarantee that labels are defined or unique

  sends    - if true, this address may send mail; default: true
  receives - if true, this address may receive mail; default: true

=head2 address

This method returns the email address as a string.

=head2 label

This method returns the address label, if any.

=head2 sends

=head2 receives

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
