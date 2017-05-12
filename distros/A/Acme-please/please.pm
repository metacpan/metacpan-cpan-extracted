package Acme::please;

use 5.00000;
use strict;

use vars qw($VERSION $PLEASE $PCTG);

$VERSION = '0.01';

$PLEASE = ' please';
$PCTG = 25;

sub TIESCALAR{
	shift; #Package
	my %P = (please => $PLEASE, pctg => $PCTG, @_);

	bless \%P;
};

sub FETCH{
	rand(100) > $_[0]->{pctg} and return '';
	$_[0]->{please}
};

sub import{
	no strict 'refs';
	tie ${caller().'::please'}, shift, @_;
};

1;
__END__

=head1 NAME

Acme::please - intercal-compliant politesse

=head1 SYNOPSIS

  use Acme::please;
  print "will you$please sit down?\n" for 1..10; # two and a half pleases
  tie $plz => Acme::please, pctg => 70;
  print "will you$plz sit down?\n" for 1..10; # expect seven pleases
  tie $plait => Acme::please, please => " s'il vous plait";
  print "will you sit down$plait?\n" for 1..10; # expect 2.5 pleases in French

=head1 DESCRIPTION

A tie interface for creating scalar variables that have a percentage chance
of having either a predetermined value or they are empty strings when
evaluated. The tie interface takes two named arguments, C<pctg> and C<please>.

=head2 pctg

C<pctg>, which is short for "percentage", will be compared with C<rand(100)>
and the null string will be returned if the random number is larger. The
efault value is C<25>.

=head2 please

C<please>, named in honor of the legendary "politesse" compilation requirement
of Intercal, is the string which will be returned when the random number is
not larger. The default value is C<' please'> and it is reccommended that
the practice of using a leading blank space be adhered to for readability,
following the examples above.

=head2 EXPORT

C<$please> is exported into caller's package through the mechanism of
tieing C<${caller().'::please'}>.  This can be suppressed by
using Acme::please with an empty list:

  use Acme::please ();	# if you don't need please in your package


=head1 HISTORY

=over 8

=item 0.01

Original version

=back


=head1 AUTHOR

David Nicol, E<lt>davidnico@cpan.orgE<gt>

=cut
