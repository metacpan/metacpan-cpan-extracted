package Biblio::RFID::Reader::librfid;

use warnings;
use strict;

use base 'Biblio::RFID::Reader::API';
use Biblio::RFID;

use Data::Dump qw(dump);

=head1 NAME

Biblio::RFID::Reader::librfid - execute librfid-tool

=head1 DESCRIPTION

This is wrapper around C<librfid-tool> from

L<http://openmrtd.org/projects/librfid/>

Due to limitation of L<librfid-tool> only
L<Biblio::RFID::Reader::API/inventory> and
L<Biblio::RFID::Reader::API/read_blocks> is supported.

However, this code might provide template for integration
with any command-line utilities for different RFID readers.

Currently tested with only with Omnikey CardMan 5321 which
has problems. After a while it stops responding to commands
by C<librfid-tool> so I provided small C program to reset it:

C<examples/usbreset.c>

=cut

sub serial_settings {} # don't open serial

our $bin = '/rest/cvs/librfid/utils/librfid-tool';

sub init {
	my $self = shift;
	if ( -e $bin ) {
		warn "# using $bin";
		return 1;
	} else {
		warn "# no $bin found\n";
		return 0;
	}
}

sub _grep_tool {
	my ( $param, $coderef ) = @_;

	warn "# _grep_tool $bin $param\n";
	open(my $s, '-|', "$bin $param") || die $!;
	while(<$s>) {
		chomp;
		warn "## $_\n";

		my $sid;
		if ( m/success.+:\s+(.+)/ ) {
			$sid = $1;
			$sid =~ s/\s*'\s*//g;
			$sid = uc join('', reverse split(/\s+/, $sid));
		}

		$coderef->( $sid );
	}


}

sub inventory {

	my @tags; 
	_grep_tool '--scan' => sub {
		my $sid = shift;
		push @tags, $sid if $sid;
	};
	warn "# invetory ",dump(@tags);
	return @tags;
}

sub read_blocks {

	my $sid;
	my $blocks;
	_grep_tool '--read -1' => sub {
		$sid ||= shift;
		$blocks->{$sid}->[$1] = hex2bytes($2)
		if m/block\[\s*(\d+):.+data.+:\s*(.+)/;

	};
	warn "# read_blocks ",dump($blocks);
	return $blocks;
}

sub write_blocks {}
sub read_afi { -1 }
sub write_afi {}

1
