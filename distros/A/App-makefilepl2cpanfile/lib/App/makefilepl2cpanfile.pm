package App::makefilepl2cpanfile;

use strict;
use warnings;

use File::Slurp qw(read_file);
use YAML::Tiny;
use File::HomeDir;

our $VERSION = '0.01';

=head1 NAME

App::makefilepl2cpanfile - Convert Makefile.PL to a cpanfile automatically

=head1 SYNOPSIS

	use App::makefilepl2cpanfile;

	# Generate a cpanfile string
	my $cpanfile_text = App::makefilepl2cpanfile::generate(
		makefile	=> 'Makefile.PL',
		existing	=> '',		# optional, existing cpanfile content
		with_develop => 1,			# include developer dependencies
	);

	# Write to disk
	open my $fh, '>', 'cpanfile' or die $!;
	print $fh $cpanfile_text;
	close $fh;

=head1 DESCRIPTION

This module parses a `Makefile.PL` and produces a `cpanfile` with:

=over 4

=item * Runtime dependencies (`PREREQ_PM`)

=item * Build, test, and configure requirements (`BUILD_REQUIRES`, `TEST_REQUIRES`, `CONFIGURE_REQUIRES`)

=item * Optional author/development dependencies in a `develop` block

=back

The parsing is done **safely**, without evaluating the Makefile.PL.

=head1 CONFIGURATION

You may create a YAML file in:

	~/.config/makefilepl2cpanfile.yml

with a structure like:

	develop:
	  Perl::Critic: 0
	  Devel::Cover: 0
	  Test::Pod: 0
	  Test::Pod::Coverage: 0

This will override the default development tools.

=head1 METHODS

=head2 generate(%args)

Generates a cpanfile string.

Arguments:

=over 4

=item * makefile

Path to `Makefile.PL`. Defaults to `'Makefile.PL'`.

=item * existing

Optional string containing an existing cpanfile. Existing `develop` blocks are merged.

=item * with_develop

Boolean. Include default or configured author tools. Defaults to true if not overridden.

=back

Returns the cpanfile as a string.

=cut

# ----------------------------
# Main generate sub
# ----------------------------
sub generate {
	my (%args) = @_;

	my $makefile = $args{makefile} || 'Makefile.PL';
	my $existing = $args{existing} || '';
	my $with_dev = $args{with_develop};

	my %deps;
	my $min_perl;

	my $content = read_file($makefile);

	# MIN_PERL_VERSION
	if ($content =~ /MIN_PERL_VERSION\s*=>\s*['"]?([\d._]+)['"]?/) {
		$min_perl = $1;
	}

	my %map = (
		PREREQ_PM		=> 'runtime',
		BUILD_REQUIRES	 => 'build',
		TEST_REQUIRES	=> 'test',
		CONFIGURE_REQUIRES => 'configure',
	);

	# Robust dependency hash extraction
	for my $mf_key (keys %map) {
		my $phase = $map{$mf_key};

		while ($content =~ /
			$mf_key \s*=>\s* \{
				( (?: [^{}] | \{[^}]*\} )*? )
			\}
		/gsx) {
			my $block = $1;

			while ($block =~ /
				['"]([^'"]+)['"]
				\s*=>\s*
				['"]?([\d._]+)?['"]?
			/gx) {
				$deps{$phase}{$1} = $2 // 0;
			}
		}
	}

	# Preserve existing develop block
	if ($existing =~ /on\s+'develop'\s*=>\s*sub\s*\{(.*?)\};/s) {
		while ($1 =~ /requires\s+['"]([^'"]+)['"](?:\s*,\s*['"]([^'"]+)['"])?/g) {
			$deps{develop}{$1} //= $2 // 0;
		}
	}

	# Post-processing: develop block
	if ($with_dev) {
		$deps{develop} ||= {};

		my %default = (
			'Perl::Critic'		=> 0,
			'Devel::Cover'		=> 0,
			'Test::Pod'		=> 0,
			'Test::Pod::Coverage' => 0,
		);

		my $cfg_file = File::HomeDir->my_home . '/.config/makefilepl2cpanfile.yml';
		if (-r $cfg_file) {
			my $y = YAML::Tiny->read($cfg_file)->[0];
			%default = %{ $y->{develop} } if $y->{develop};
		}

		for my $mod (keys %default) {
			$deps{develop}{$mod} //= $default{$mod};
		}
	}

	return _emit(\%deps, $min_perl);
}

# ----------------------------
# Emit cpanfile text
# ----------------------------
sub _emit {
	my ($deps, $min_perl) = @_;

	my $out = "# Generated from Makefile.PL\n\n";
	$out .= "requires 'perl', '$min_perl';\n\n" if $min_perl;

	if (my $rt = $deps->{runtime}) {
		for my $m (sort keys %$rt) {
			$out .= "requires '$m'";
			$out .= ", '$rt->{$m}'" if $rt->{$m};
			$out .= ";\n";
		}
		$out .= "\n";
	}

	for my $phase (qw(configure build test develop)) {
		my $h = $deps->{$phase} or next;
		next unless %$h;

		$out .= "on '$phase' => sub {\n";
		for my $m (sort keys %$h) {
			$out .= "	requires '$m'";
			$out .= ", '$h->{$m}'" if $h->{$m};
			$out .= ";\n";
		}
		$out .= "};\n";
	}

	return $out;
}

1;

__END__

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
