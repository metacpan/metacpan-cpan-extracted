
package Config::YAMLMacros;

use strict;
use warnings;
use Config::YAMLMacros::YAML qw(Load);
use File::Slurp qw(read_file);
use Carp qw(confess);
use File::Basename qw(basename dirname);
require Hash::Merge;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_config);
our @EXPORT_OK = (@EXPORT, qw(listify replace));

my $max_replace_iterations = 10;

sub listify(\%@)
{
	my ($href, @keys) = @_;
	for my $k (@keys) {
		next unless exists $href->{$k};
		if (! ref($href->{$k})) {
			$href->{$k} = [ $href->{$k} ];
		} elsif (ref($href->{$k}) eq 'ARRAY') {
			# fine
		} else {
			confess;
		}
	}
}

sub replace(\%\$)
{
	my ($href, $sref) = @_;
	my $jlist = join('|', map { "\Q$_\E" } keys %$href);
	return unless $jlist;
	my $re = qr/$jlist/;
	my $iteration = 0;
	my $replace = sub {
		# print STDERR "# replacing '$_[0]' with '$href->{$_[0]}'\n";
		return $href->{$_[0]};
	};
	for (;;) {
		$$sref =~ s/($re)/$replace->($1)/ge or last;
		if ($iteration++ >= $max_replace_iterations) {
			confess "too many replacements in $$sref";
		}
	}
}

sub get_config
{
	my ($config_file, %opts) = @_;

	my $raw = read_file($config_file);
	my @sections = split(/^---\n/m, $raw);

	my %metakeys = (
		EVAL_REPLACE	=> 'do string replacements with evaluated perl',
		REPLACE		=> 'do string replacements',
		NO_REPLACE	=> 'stop doing string replacements',
		INCLUDE		=> 'include another file',
		OVERRIDE_FROM	=> 'overrides from another file',
	);

	my $old_behavior = Hash::Merge::get_behavior();
	Hash::Merge::set_behavior($opts{merge_behavior} || 'RETAINMENT_PRECEDENT');

	my %replacements = $opts{replacements} ? %{$opts{replacements}} : ();
	my $config = {};
	while (@sections) {
		my $yaml = shift @sections;
		next unless $yaml; # skip empty sections
		$yaml =~ s/^(\t+)/" " x length($1) * 8/e;
		my $newstuff = eval { Load( { file => $config_file }, "---\n$yaml"); };
		die "When loadking from $config_file, YAML error: $@" if $@;
		my $meta = 0;
		my $non_meta = 0;
		for my $k (keys %$newstuff) {
			if ($metakeys{$k}) {
				$meta++;
			} else {
				$non_meta++;
			}
		}
		if ($meta && $non_meta) {
			die;
		} elsif ($meta) {
			if ($newstuff->{NO_REPLACE}) {
				listify(%$newstuff, 'NO_REPLACE');
				delete @replacements{@{$newstuff->{NO_REPLACE}}};
			}
			replace(%replacements, $yaml);
			$newstuff = Load( { file => $config_file }, "---\n$yaml");
			@replacements{keys %{$newstuff->{REPLACE}}} = values %{$newstuff->{REPLACE}}
				if $newstuff->{REPLACE};
			if ($newstuff->{EVAL_REPLACE}) {
				die "In $config_file, EVAL_REPLACE should be a hash" 
					unless ref($newstuff->{EVAL_REPLACE}) eq 'HASH';
				for my $ekey (keys %{$newstuff->{EVAL_REPLACE}}) {
					$replacements{$ekey} = eval $newstuff->{EVAL_REPLACE}{$ekey};
					die "Eval failure for $ekey in $config_file: $@" if $@;
				}
			}
			listify(%$newstuff, qw(INCLUDE OVERRIDE_FROM));
			for my $include (@{$newstuff->{INCLUDE}}) {
				die if ref($include);

				if (! -e $include) {
					my $alt = dirname($config_file) . "/" . $include;
					$include = $alt if -e $alt;
				}

				my $conf = get_config($include, %opts, replacements => \%replacements);

				$config = Hash::Merge::merge($config, $conf);
			}
			for my $override (@{$newstuff->{OVERRIDE_FROM}}) {
				my $conf = get_config($override, %opts, replacements => \%replacements);
				Hash::Merge::set_behavior('RIGHT_PRECEDENT');
				$config = Hash::Merge::merge($config, $conf);
				Hash::Merge::set_behavior($opts{merge_behavior} || 'RETAINMENT_PRECEDENT');
			}
		} else {
			# non-meta, normal
			replace(%replacements, $yaml);
			$newstuff = Load( { file => $config_file }, "---\n$yaml");
			$config = Hash::Merge::merge($config, $newstuff);
		}
	}
	Hash::Merge::set_behavior($old_behavior) if $old_behavior;
	return $config;
}


__END__

=head1 NAME

Config::YAMLMacros - Include file and string subsitution for YAML configuration files

=head1 SYNOPSIS

use Config::YAMLMacros;

my $config = get_config('/some/file');

=head1 DESCRIPTION

This module is a wrapper around loading YAML configuration files.
It does several things:

=head2 expand tabs

Initial tabs on lines are expanded so that YAML doesn't choke on 
invisible variations in whitespace.

=head2 join sections

The YAML file may be split into sections, divided with C<---> lines.
The sections will be merged together to create the final result.

=head2 string replacements

You can declare string replacements to use for the rest of the 
file.  For example:

 ---
 REPLACE:
   %FOO%:	BAR
 ---

You can declare string replacements where the value of the 
replacement string is evaluated as a perl expression:

 ---
 EVAL_REPLACE:
   %FOO%:	$ENV{HOME}
 ---

You can turn off the replacements with a C<NO_REPLACE> directive:

 ---
 NO_REPLACE: %FOO%
 ---

=head2 include files

You can include additional files as part of your configuration file.
They will be merged in.

 ---
 INCLUDE: filename.yml
 ---

You can specify that the new file override stuff that has already been
seen in the current file:

 ---
 OVERRIDE_FROM: filename.yml
 ---

=

For the C<INCLUDE>, C<OVERRIDE_FROM>, and C<NO_REPLACE> directives, they
can be either lists or a single item:

 ---
 OVERRIDE_FROM:
   - file1.yml
   - file2.yml
 NO_REPLACE:
   - %FOO%
   - %BAR%
 INCLUDE: justone.yml
 ---

These new directives need to be in a yaml block all by themselves 
(delimited by C<--->).

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

