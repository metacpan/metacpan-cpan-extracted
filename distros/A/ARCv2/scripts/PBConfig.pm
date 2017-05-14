package PBConfig;

use strict;
use Getopt::Long;
require Exporter;
use vars qw(@ISA @EXPORT_OK @config $fn $opt @EXPORT $usage);

@ISA = qw(Exporter);
@EXPORT = qw(@config $fn $opt opt_parse file_parse opt_help $usage);  # symbols to export on request
						   
# Configuration array, Filename to treat

$opt = {};

$usage = sub {};

sub opt_parse
{
	my @go = ();
	foreach (@config) {
		my ($n,$c,$t);
		$n = $_->[1] eq "b" ? $_->[0]."!" : $_->[0];
		$c = $_->[1] ne "" && $_->[1] ne "b" ? "=" : "";
		$t = $_->[1] eq "b" ? "" : $_->[1];
		push @go, $n.$c.$t;
	}

	Getopt::Long::GetOptions(
		$opt,
		"help",
		@go
	);

	&$usage() if $opt->{help};

	# getting default values
	foreach (@config) {
		$opt->{$_->[0]} = $_->[2] unless defined $opt->{$_->[0]};
	}
}

sub file_parse {
	open(FS,"<$fn");
	open(FD,">$fn.new");

	my $c = 0;
	my $ins;
	while(my $l = <FS>) {
		$ins = 0;
		foreach (@config) {
			if ($l =~ /^\$$_->[0]/) {
				my ($v);
				# Default values
				$v = defined $opt->{$_->[0]} ? $opt->{$_->[0]} : $_->[2];
				# String in "
				$v = $_->[1] eq "s" ? '"'.$v.'"' : $v;

				$c++;
				print FD '$',$_->[0],' = ',$v,";\n";
				$ins = 1;
				last;
			}
		}
		print FD $l unless $ins;
	}

	close(FS);
	close(FD);

	if ($c != scalar @config) {
	#if (1) {
		die "Could not find all hooks for setting default values in $fn.";
	} else {
		unlink("$fn");
		rename("$fn.new","$fn");
	}
}

sub opt_help
{
	foreach (@config) {
		my ($n);
		$n = $_->[1] eq "b" ? "(no-)".$_->[0] : $_->[0];
		print "     --".$n."\t".$_->[3]."\n";
	}
}

1;
