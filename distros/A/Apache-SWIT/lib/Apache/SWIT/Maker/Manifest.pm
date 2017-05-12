use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Manifest;
use base 'Exporter';
use File::Slurp;
use File::Basename qw(dirname);
use File::Path;
use ExtUtils::Manifest;
use File::Copy;

our @EXPORT = qw(swmani_filter_out swmani_write_file mkpath_write_file
		swmani_dual_tests swmani_replace_file swmani_replace_in_files);

sub swmani_filter_out {
	my $file = shift;
	my @lines = grep { !(/$file/) } read_file('MANIFEST');
	write_file('MANIFEST', join("", @lines));
}

sub mkpath_write_file {
	my ($f, $str) = @_;
	mkpath(dirname($f));
	write_file($f, $str);
}

sub swmani_write_file {
	my ($f, $str) = @_;
	die "Cowardly refusing to overwrite $f" if -f $f;
	mkpath_write_file($f, $str);
	-f 'MANIFEST' ?  ExtUtils::Manifest::maniadd({ $f => "" })
			: write_file('MANIFEST', "$f\n");
}

sub swmani_dual_tests {
	my $mf = ExtUtils::Manifest::maniread();
	return grep { /t\/dual\/.+\.t$/ } keys %$mf;
}

sub swmani_replace_file {
	my ($from, $to) = @_;
	my @lines = read_file('MANIFEST');
	for my $l (@lines) {
		next unless $l =~ m#$from#;
		my ($f) = ($l =~ /^(\S+)/);

		$l =~ s#$from#$to#g;
		my ($t) = ($l =~ /^(\S+)/);
		mkpath(dirname($t));
		rename($f, $t) or die "Unable to rename $f to $t";
	}
	write_file('MANIFEST', join("", @lines));
}

sub swmani_replace_in_files {
	my ($from, $to) = @_;
	my $mf = ExtUtils::Manifest::maniread();
	my $sub = ref($from) ? $from : sub { s#$from#$to#g; };
	for my $f (keys %$mf) {
		$_ = read_file($f);
		&$sub;
		write_file($f, $_);
	}
}

1;
