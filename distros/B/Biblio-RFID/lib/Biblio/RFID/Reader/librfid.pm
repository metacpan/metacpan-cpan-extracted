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

This version uses modidified C<librfid-tool> which supports
new C<-s> flag which reads sectors 0-3 with C<-k> key and
sectors 4-7 with key from C<-s> option.

However, this code might provide template for integration
with any command-line utilities for different RFID readers.

Currently tested with only with Omnikey CardMan 5321 which
has problems. After a while it stops responding to commands
by C<librfid-tool> so I provided small C program to reset it:

C<examples/usbreset.c>

=cut

sub serial_settings {} # don't open serial

sub init { 1 }

sub _grep_tool {
	my ( $bin, $param, $coderef, $path ) = @_;

	my $timeout = 3; # s

	eval {

	warn "# _grep_tool $bin $param\n";
#	$param .= ' 2>/dev/null';
	my $pipe_pid = open(my $s, '-|', "$bin $param") || die $!;

	local $SIG{ALRM} = sub {
		warn "TIMEOUT!";
		kill TERM => $pipe_pid;
		die "timeout\n"
	};
	alarm $timeout;

	my $sid;
	my $iso;

	while(<$s>) {
		chomp;
		warn "## $_\n";

		if ( m/Layer 2 success.+\(([^\)]+)\).*:\s+(.+)/ ) {
			( $sid, $iso ) = ( $2, $1 );
			$sid =~ s/\s*'\s*//g;
			my @sid = split(/\s+/, $sid);
			@sid = reverse @sid if $iso =~ m/15693/;
			$sid = uc join('', @sid);
			warn "## sid=[$sid] iso=[$iso]\n";
		}
		$coderef->( $sid, $iso );
	}

	alarm(0);
	close($s);

	}; # eval

	if ( $? >> 8 || $@ ) {
		my $lsusb = `lsusb -d 076b:`;
		if ( $lsusb =~ m/\S+\s+(\d+)\s+\S+\s+(\d+)/ ) {
			my $cmd = "usbreset /dev/bus/usb/$1/$2";
			warn "# $cmd\n";
			system $cmd;
		} else {
			warn "can't reset device $lsusb";
		}
	}

}

my $sid_iso;

sub inventory {

	my @tags; 
	$sid_iso = {};
	_grep_tool 'librfid-tool', '--scan' => sub {
		my ( $sid, $iso ) = @_;
		if ( $sid && ! exists $sid_iso->{$sid} ) {
			push @tags, $sid;
			$sid_iso->{$sid} = $iso;
		}
	};
	warn "# invetory ",dump(@tags);
	return @tags;
}

sub tag_type {
	my ( $self, $tag ) = @_;
	return $sid_iso->{$tag} =~ m/15693/ ? 'RFID501' : 'SmartX';
}

our $mifare_keys;
sub read_mifare_keys {
	my $key_path = $0;
	$key_path =~ s{/[^/]+$}{/};
	$key_path .= "mifare_keys.pl";
	warn "# $key_path";
	if ( -e $key_path ) {
		require $key_path;
		warn "# mifare keys for sectors ", join(' ', keys %$mifare_keys), " loaded\n";
	}
}

sub read_blocks {
	my ( $self, $sid ) = @_;

	my $iso = $sid_iso->{$sid};
	my $blocks;

	if ( $iso =~ m/15693/ ) {
		_grep_tool 'librfid-tool', '--read -1' => sub {
			$sid ||= shift;
			$blocks->{$sid}->[$1] = hex2bytes($2)
			if m/block\[\s*(\d+):.+data.+:\s*(.+)/;

		};
	} else {
		read_mifare_keys unless $mifare_keys;

=for unmodified mifate-tool
		foreach my $sector ( keys %$mifare_keys ) {
			my $key = lc $mifare_keys->{$sector};
			_grep_tool 'mifare-tool', "-k $key -r $sector" => sub {
				$blocks->{$sid}->[$sector] = hex2bytes($1)
				if m/data=\s*(.+)/;
			};
		}
=cut
		_grep_tool 'mifare-tool', "-k " . $mifare_keys->{0} . " -s " . $mifare_keys->{4} => sub {
			$blocks->{$sid}->[$1] = hex2bytes($2)
			if m/page=(\d+).*data=\s*(.+)/;
		};

		my $blocks_read = 0;
		$blocks_read += $_ foreach grep { defined $blocks->{$sid}->[$_] } ( 4 .. 6 );
 		if ( $blocks_read < (4 + 5 + 6) ) {
			warn "# invalidate partial read of SmartX card\n";
			$blocks = undef;
		}
	}
	warn "# read_blocks ",dump($blocks);
	return $blocks;
}

sub write_blocks {}
sub read_afi { -1 }
sub write_afi {}

1
