=pod

=head1 NAME

Error::Mimetic - The error class definition for Crypt::Mimetic(3) (see Error(3) module)

=head1 DESCRIPTION

This module is a part of Crypt::Mimetic(3) distribution.

This module extends I<Error::Simple>.

=cut

package Error::Mimetic;
use Error;
use strict;
use vars qw($VERSION);
$VERSION = '0.02';

=pod

=head1 CLASS INTERFACE

See Error(3) for details about methods not described below

=cut

@Error::Mimetic::ISA = qw(Error::Simple);

=pod

=head2 CONSTRUCTORS

Error::Mimetic constructor takes 3 arguments:
the first is the error description, the second are details and the last
is the type: C<error> (default) or C<warning>.

=cut

sub new {
	my ($self, $text, $details, $type) = @_;
	my $s = $self->SUPER::new($text,0);
	$s->{'-object'} = $details;
	$s->{'-type'} = "error";
	$s->{'-type'} = $type if $type;
	return $s;
}

=pod

=head2 OVERLOAD METHODS

=over 4

=item string I<stringify> ()

A method that converts the object into a string.

If I<$Error::Debug> is == 0, then only description is printed.

If I<$Error::Debug> is > 0, then details are printed after description.

If I<$Error::Debug> is > 1, then description, details and informations about files and lines where error raised are printed.

=cut

sub stringify {
	my $self = shift;
	my $cache = $self->{'-cache'};
	return $cache if $cache;
	my $obj = $self->{'-object'};
	$self->{'-text'} .= ".\n" unless $Error::Debug > 1;
	my $s = $self->SUPER::stringify;
	if ($Error::Debug > 0 && $obj) {
		my @lines = split /\n/, $obj;
		chomp(@lines);
		$obj = $lines[0];
		chomp $s;
		$s .= " - $obj";
		chomp $s;
		if ($Error::Debug < 2) {
			$s =~ s/ at (\S+) line (\d+)(\.)*$//s  ||
				$s =~ s/ at \(.*?\) line (\d+)(\.)*$//s;
		}
		$s .= "\n";
	}
	$self->{'-cache'} = $s;
	return $s;
}

=pod

=head2 OBJECT METHODS

=item string I<type> ()

Return error type: C<error> (default) or C<warning>.

=cut

sub type {
	my $self = shift;
	return $self->{'-type'};
}

1;
__END__

=pod

=head1 NEEDED MODULES

This module needs:
   Error

=head1 SEE ALSO

Error(3), Crypt::Mimetic(3)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself (Artistic/GPL2).

=head1 AUTHOR

Erich Roncarolo <erich-roncarolo@users.sourceforge.net>

=cut
