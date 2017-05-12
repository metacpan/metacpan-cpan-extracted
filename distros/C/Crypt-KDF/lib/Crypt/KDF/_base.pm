package Crypt::KDF::_base;

use strict;
use vars qw($VERSION);

### ($VERSION) = sprintf '%i.%03i', split(/\./,('$Revision: 0.1 $' =~ /Revision: (\S+)\s/)[0]);  # $Date: $
$VERSION = '0.02';

=head1 NAME

Crypt::KDF::_base

=cut

sub new { die "must subclass"; }

sub init { die "must subclass"; }

sub kdf_hex
{
	my $self = shift @_;
	my $ret;
	if($_[0])
	{
		$ret=$self->kdf($_[0]);
	}
	else
	{
		$ret=$self->kdf();
	}
	return unpack('H*',$ret);
}

sub kdf { die "must subclass"; }

=head1 METHODS

=head2 $digest = $kdf->digest( $digest )

Sets/gets the digest to be used as the source of derived keys.

=cut

sub digest
{
	my $self = shift @_;
	if($_[0])
	{
		$self->{-digest} = (ref($_[0]) ? ref($_[0]) : $_[0]);
	}
	return $self->{-digest};
}

=head2 $digestparam = $kdf->digestparam( $digestparam )

Sets/gets the optional parameters for the digest used to derive keys.

=cut

sub digestparam
{
	my $self = shift @_;
	if($_[0])
	{
		$self->{-digestparam} = $_[0];
	}
	return $self->{-digestparam};
}

=head2 $seed = $kdf->seed( $seed )

Sets/gets the seed to be used to derive keys.

=cut

sub seed
{
	my $self = shift @_;
	if($_[0])
	{
		$self->{-seed} = $_[0];
	}
	return $self->{-seed};
}

=head2 $counter = $kdf->counter( $counter )

Sets/gets the start value of counter used to derive keys.

=cut

sub counter
{
	my $self = shift @_;
	if($_[0])
	{
		$self->{-counter} = $_[0];
	}
	return $self->{-counter};
}

=head2 $iv = $kdf->iv( $iv )

Sets/gets the optional iv to be used to derive keys.

=cut

sub iv
{
	my $self = shift @_;
	if($_[0])
	{
		$self->{-iv} = $_[0];
	}
	return $self->{-iv};
}

=head2 ( $derivedKey, $derivedIV ) = $kdf->kdf_iv( $kLen, $ivLen )

Return length bytes generated from the derivation function.

=cut

sub kdf_iv
{
	my $self = shift @_;
	my $kLen = 16;
	if($_[0])
	{
		$kLen = $_[0];
	}
	my $ivLen = 16;
	if($_[1])
	{
		$ivLen = $_[1];
	}
	my $len=$kLen+$ivLen;
	my $out=$self->kdf($len);
	return (substr($out,0,$kLen), substr($out,$kLen,$ivLen));
}

1;
__END__

=head1 EXAMPLES

=head1 SEE ALSO

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHORS 

=cut