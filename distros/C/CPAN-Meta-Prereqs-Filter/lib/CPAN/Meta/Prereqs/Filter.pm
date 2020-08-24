package CPAN::Meta::Prereqs::Filter;
$CPAN::Meta::Prereqs::Filter::VERSION = '0.005';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/filter_prereqs/;

use Carp 'croak';
use Scalar::Util 'isvstring';

my @phases = qw/configure build test runtime develop/;
my @relationships = qw/requires recommends suggests/;

my %dependents_for = (
	configure => [ qw/build test develop/ ],
	runtime => [ qw/build test develop/ ],
	build => [ qw/test develop/ ],
	test => [ qw/develop/ ],
);

sub _normalize_version {
	my $raw = shift;
	if (isvstring($raw)) {
		$raw = sprintf 'v%vd', $raw;
	}
	if ($raw =~ / \A v5 (?> \. \d+)* \z /x) {
		require version;
		return sprintf '%7.6f', version->new($raw)->numify;
	}
	elsif ($raw eq 'latest') {
		require Module::CoreList;
		return (reverse sort keys %Module::CoreList::version)[0];
	}
	return sprintf '%7.6f', $raw;
}

sub filter_prereqs {
	my ($prereqs, %args) = @_;
	return $prereqs if not grep { $_ } values %args;
	$prereqs = $prereqs->clone;
	my $core_version = defined $args{omit_core} ? _normalize_version($args{omit_core}) : undef;
	if ($core_version) {
		require Module::CoreList;
		croak "$core_version is not a known perl version" if not exists $Module::CoreList::version{$core_version};
		for my $phase (@phases) {
			for my $relation (@relationships) {
				my $req = $prereqs->requirements_for($phase, $relation);

				$req->clear_requirement('perl') if $req->accepts_module('perl', $core_version);
				for my $module ($req->required_modules) {
					next if not exists $Module::CoreList::version{$core_version}{$module};
					next if not $req->accepts_module($module, $Module::CoreList::version{$core_version}{$module});
					next if Module::CoreList->is_deprecated($module, $core_version);
					$req->clear_requirement($module);
				}
			}
		}
	}
	if ($args{sanitize}) {
		for my $parent (qw/runtime configure build/) {
			for my $child ( @{ $dependents_for{$parent} } ) {
				for my $relationship (@relationships) {
					my $source = $prereqs->requirements_for($parent, $relationship);
					my $sink = $prereqs->requirements_for($child, $relationship);
					for my $module ($source->required_modules) {
						next if not defined(my $right = $sink->requirements_for_module($module));
						my $left = $source->requirements_for_module($module);
						$sink->clear_requirement($module) if $left eq $right || $right eq '0';
					}
				}
			}
		}
	}
	if ($args{only_missing}) {
		require Module::Metadata;
		for my $phase (@phases) {
			for my $relation (@relationships) {
				my $req = $prereqs->requirements_for($phase, $relation);
				$req->clear_requirement('perl') if $req->accepts_module('perl', $]);
				for my $module ($req->required_modules) {
					if ($req->requirements_for_module($module)) {
						my $metadata = Module::Metadata->new_from_module($module);
						if ($metadata && $req->accepts_module($module, $metadata->version($module) || 0)) {
							$req->clear_requirement($module);
						}
					}
					else {
						$req->clear_requirement($module) if Module::Metadata->find_module_by_name($module);
					}
				}
			}
		}
	}
	return $prereqs;
}

1;

# ABSTRACT: Filtering various things out of CPAN::Meta::Prereqs

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Prereqs::Filter - Filtering various things out of CPAN::Meta::Prereqs

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use CPAN::Meta::Prereqs::Filter 'filter_prereqs';
 $prereqs = filter_prereqs($prereqs, sanitize => 1, only_missing => 1, omit_core => 5.008003);

=head1 DESCRIPTION

This module provides various filters for CPAN::Meta::Prereqs objects.

=head1 FUNCTIONS

=head2 filter_prereqs($prereqs, %opts)

This function filters various things entries from the $prereqs, and returns it in a new L<Prereqs|CPAN::Meta::Prereqs> object. Allowed options are:

=over 4

=item sanitize

If true, any double-declared entries are removed. For example, runtime dependencies will be removed from testing dependencies, because runtime dependencies should already be installed during testing. The exact algorithm may change in future versions.

=item omit_core

This takes a perl version, and will remove all requirements that are provided by that version of perl. It can take the version argument as a number (C<5.008008>), a string starting with a v (C<'v5.8.8'>), a v-string or the special string C<'latest'> which will substitute the highest known version in L<Module::CoreList|Module::CoreList> (this is not necessarily the latest released version of perl, you may want to upgrade your Module::CoreList for more up-to-date data).

=item only_missing

This will filter out requirements that are met on the current system (as determined using L<Module::Metadata|Module::Metadata>).

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
