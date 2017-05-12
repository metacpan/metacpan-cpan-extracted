################################################################################
# This is CodeManager
# Copyright 2009-2013 by Waldemar Biernacki
# http://codemanager.sao.pl\n" .
#
# License statement:
#
# This program/library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# Last modified (DMYhms): 13-01-2013 09:42:01.
################################################################################

package Prima::CodeManager::Image;

use strict;
use warnings;

use POSIX;

################################################################################

our %IType;
our %Image;
our %Dim_X;
our %Dim_Y;
our %Obraz;

################################################################################

sub make_image {
	my ( $name ) = @_;

	return undef unless $Image{$name};

	my $data = '';

	my $string = $Image{$name};
	$string =~ s/\n//g;
	$string =~ s/\s//g;

	{
		use bytes;
		for ( my $x = 0; $x < length $string; $x += 2 ) {
			$data .= chr( hex( substr( $string, $x, 2 )));
		}
		no bytes;
	}
	$IType{$name} = 'image' unless $IType{$name};

	my $obraz;

	if ( $IType{$name} =~ /icon/i ) {
		$obraz = Prima::Icon->new(
			width		=> $Dim_X{$name},
			height		=> $Dim_Y{$name},
			type		=> 24,
			data		=> $data,
			autoMasking	=> 1,
		);
	} else {
		$obraz = Prima::Image->new(
			width		=> $Dim_X{$name},
			height		=> $Dim_Y{$name},
			type		=> 24,
			data		=> $data,
			autoMasking	=> 1,
		);
	}

	return $obraz;
}

################################################################################

$IType{'plus.png'} = 'image';
$Dim_X{'plus.png'} = 11;
$Dim_Y{'plus.png'} = 11;
$Image{'plus.png'} = q(
808080808080808080808080808080808080808080808080808080808080808080000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080ffffffffff
ffffffffffffff000000ffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffff000000ffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffff00
0000ffffffffffffffffffffffff808080000000808080ffffff000000000000000000000000000000000000000000ffffff808080000000808080ffffffffffffffffffffffff000000ffffffffffff
ffffffffffff808080000000808080ffffffffffffffffffffffff000000ffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffff000000ffffffffffffffffffffffff8080
80000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080808080808080808080808080808080808080808080808080808080808080000000
);

$IType{'minus.png'} = 'image';
$Dim_X{'minus.png'} = 11;
$Dim_Y{'minus.png'} = 11;
$Image{'minus.png'} = q(
808080808080808080808080808080808080808080808080808080808080808080000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080ffffffffff
ffffffffffffffffffffffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffffff
ffffffffffffffffffffffffffff808080000000808080ffffff000000000000000000000000000000000000000000ffffff808080000000808080ffffffffffffffffffffffffffffffffffffffffff
ffffffffffff808080000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff8080
80000000808080ffffffffffffffffffffffffffffffffffffffffffffffffffffff808080000000808080808080808080808080808080808080808080808080808080808080808080000000
);
################################################################################

1;

__END__

=pod

=head1 NAME

Prima::CodeManager::Image

=head1 DESCRIPTION

This is part of CodeManager project - not for direct use.

=head1 AUTHOR

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2013 by Waldemar Biernacki.

L<http://codemanager.sao.pl>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
