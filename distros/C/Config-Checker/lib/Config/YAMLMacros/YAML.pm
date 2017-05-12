
package Config::YAMLMacros::YAML;

use strict;
use warnings;
use File::Slurp;
require Exporter;
use YAML::Syck qw(Dump);
use Carp qw(confess);

our @ISA = qw(YAML::Syck);
our @EXPORT = qw(Load Dump LoadFile);

sub LoadFile
{
	my ($file) = @_;
	my @r;
	if (wantarray) {
		@r = eval { YAML::Syck::Load(scalar(read_file($file))); }
	} else {
		$r[0] = eval { YAML::Syck::Load(scalar(read_file($file))); }
	}
	yaml_error($@, $file, scalar(read_file($file))) if $@;
	return @r if wantarray;
	return $r[0];
}

sub Load
{
	my @r;
	my $opts = { file => 'unknown file' };
	$opts = shift if ref $_[0];
	if (wantarray) {
		@r = eval { YAML::Syck::Load(@_); }
	} else {
		$r[0] = eval { YAML::Syck::Load(@_); }
	}
	yaml_error($@, $opts->{file}, join('', @_)) if $@;
	return @r if wantarray;
	return $r[0];
}

sub yaml_error
{
	my ($error, $filename, $input) = @_;

	my @x = split(/\n/, $input);

	my $from = 0;
	my $to = 10000;
	my $eline;

	if ($error =~ /Syck parser \(line (\d+), column 87\): .*/) {
		$eline = $1;
	} elsif ($error =~ /Code: [A-Z_\d]+\n\s+Line: (\d+)/) {
		$eline = $1;
	}

	if (defined $eline) {
		$from = $eline - 20;
		$to = $eline + 20;
	}
	$from = 0 if $from < 0;
	$to = $#x if $to > $#x;

	my $context = join("\n", map { sprintf("%-4d%s", $_, $x[$_]) } $from..$to);

	die "YAML INPUT:\n$context\nYAML Error when loading $filename: $error";
}

1;

__END__

=head1 NAME

Config::YAMLMacros::YAML - small wrapper for YAML::Syck to improve error reporting

=head1 SYNOPSIS

 use Config::YAMLMacros::YAML;

 $obj = LoadFile("file");
 @objs = LoadFile("file");

 $obj = Load("--- yaml here");
 @objs = Load("--- yaml here");

=head1 DESCRIPTION

Error reporting from the various YAML modules is worse than
lousy.  This module is a light-weight wrapper for L<YAML::Syck> that
tries to provide a bit of context for reported errors.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

