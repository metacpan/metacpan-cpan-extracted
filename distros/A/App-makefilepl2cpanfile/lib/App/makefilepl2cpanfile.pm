package App::makefilepl2cpanfile;

use strict;
use warnings;
use autodie qw(:all);

use Path::Tiny;
use YAML::Tiny;
use File::HomeDir;

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

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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
	my $with_dev = exists $args{with_develop} ? $args{with_develop} : 1;

	my %deps;
	my $min_perl;

	die "Cannot read '$makefile': $!" unless -r $makefile;

	my $content = path($makefile)->slurp_utf8;

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
			$block =~ s/#[^\n]*//g;	# strip comments

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
	if ($existing =~ /on\s+["']develop["']\s*=>\s*sub\s*\{(.*?)\};/s) {
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
			my $yaml = YAML::Tiny->read($cfg_file) or die "Failed to parse $cfg_file: ", YAML::Tiny->errstr();
			my $y = $yaml->[0];
			%default = %{ $y->{develop} } if $y->{develop};
		}

		for my $mod (keys %default) {
			$deps{develop}{$mod} //= $default{$mod};
		}
	}

	return _emit(\%deps, $min_perl);
}

# _emit - Render collected dependency data as a cpanfile-format string
#
#   Converts a structured hash of phase-keyed dependencies and an optional
#   minimum Perl version into a valid cpanfile string ready to be written
#   to disk.
#
# Entry:
#   $_[0] - hashref of dependency data, keyed by phase name:
#               'runtime', 'configure', 'build', 'test', 'develop'
#           Each value is a hashref of Module::Name => version_string,
#           where version_string may be 0 or '' to indicate no minimum.
#   $_[1] - optional scalar containing the minimum Perl version string
#           (e.g. '5.010'), or undef if none was declared.
#
# Exit:
#   Returns a scalar string containing the complete cpanfile content,
#   always terminated with a single newline. Never returns undef.
#
# Side effects:
#   None.
#
# Notes:
#   - Dependencies with a version of 0 or '' are emitted without a version
#     constraint, as cpanfile treats an absent version as "any version".
#   - The 'runtime' block is emitted without an enclosing 'on' block, per
#     cpanfile convention.
#   - Phase blocks (configure, build, test, develop) are separated by a
#     blank line; no trailing blank line is emitted after the final block.
#   - Modules within each phase are sorted alphabetically for reproducibility.
sub _emit {
	my ($deps, $min_perl) = @_;

	my $out = "# Generated from Makefile.PL using makefilepl2cpanfile\n\n";
	$out .= "requires 'perl', '$min_perl';\n\n" if $min_perl;

	if (my $rt = $deps->{runtime}) {
		for my $m (sort keys %$rt) {
			$out .= "requires '$m'";
			$out .= ", '$rt->{$m}'" if defined $rt->{$m} && $rt->{$m} ne '' && $rt->{$m} != 0;
			$out .= ";\n";
		}
		$out .= "\n";
	}

	my @blocks;

	for my $phase (qw(configure build test develop)) {
		my $h = $deps->{$phase} or next;
		next unless %$h;

		my $block = "on '$phase' => sub {\n";
		for my $m (sort keys %$h) {
			$block .= "	requires '$m'";
			$block .= ", '$h->{$m}'" if defined $h->{$m} && $h->{$m} ne '' && $h->{$m} != 0;
			$block .= ";\n";
		}
		$block .= "};";
		push @blocks, $block;
	}

	$out .= join("\n\n", @blocks) . "\n" if @blocks;

	return $out;
}

1;

__END__

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
