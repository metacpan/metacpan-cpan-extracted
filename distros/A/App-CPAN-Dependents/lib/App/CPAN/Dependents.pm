package App::CPAN::Dependents;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use MetaCPAN::Client;

our $VERSION = '1.000';

our @EXPORT_OK = ('find_all_dependents');

sub find_all_dependents {
	my %options = @_;
	my $mcpan = delete $options{mcpan};
	unless (defined $mcpan) {
		my $http = delete $options{http};
		my %mcpan_params;
		$mcpan_params{ua} = $http if defined $http;
		$mcpan = MetaCPAN::Client->new(%mcpan_params);
	}
	my $module = delete $options{module};
	my $dist = delete $options{dist};
	my %dependent_dists;
	if (defined $dist) {
		my $modules = _dist_modules($mcpan, $dist);
		_find_dependents($mcpan, $modules, \%dependent_dists, \%options);
	} elsif (defined $module) {
		my $dist = _module_dist($mcpan, $module); # check if module is valid
		_find_dependents($mcpan, [$module], \%dependent_dists, \%options);
	} else {
		croak 'No module or distribution defined';
	}
	return [sort keys %dependent_dists];
}

sub _find_dependents {
	my ($mcpan, $modules, $dependent_dists, $options) = @_;
	$dependent_dists //= {};
	$options //= {};
	my $dists = _module_dependents($mcpan, $modules, $options);
	if ($options->{debug} and @$dists) {
		my @names = map { $_->{name} } @$dists;
		warn "Found dependent distributions: @names\n";
	}
	foreach my $dist (@$dists) {
		my $name = $dist->{name};
		next if exists $dependent_dists->{$name};
		$dependent_dists->{$name} = 1;
		my $modules = $dist->{provides};
		warn @$modules ? "Modules provided by $name: @$modules\n"
			: "No modules provided by $name\n" if $options->{debug};
		_find_dependents($mcpan, $modules, $dependent_dists, $options) if @$modules;
	}
	return $dependent_dists;
}

sub _module_dependents {
	my ($mcpan, $modules, $options) = @_;
	
	my @relationships = ('requires');
	push @relationships, 'recommends' if $options->{recommends};
	push @relationships, 'suggests' if $options->{suggests};
	my @dep_filters = (
		{ terms => { 'dependency.module' => $modules } },
		{ terms => { 'dependency.relationship' => \@relationships } },
	);
	push @dep_filters, { not => { term => { 'dependency.phase' => 'develop' } } }
		unless $options->{develop};
	
	my %filter = (
		and => [
			{ term => { maturity => 'released' } },
			{ term => { status => 'latest' } },
			{ nested => {
				path => 'dependency',
				filter => { and => \@dep_filters },
			} },
		],
	);
	
	my $response = $mcpan->all('releases', {
		fields => [ 'distribution', 'provides' ],
		es_filter => \%filter,
	});
	
	my @results;
	while (my $hit = $response->next) {
		my $name = $hit->distribution;
		my $provides = $hit->provides // [];
		$provides = [$provides] unless ref $provides;
		push @results, { name => $name, provides => $provides };
	}
	return \@results;
}

sub _dist_modules {
	my ($mcpan, $dist) = @_;
	my $response = $mcpan->release($dist) // return [];
	return $response->provides // [];
}

sub _module_dist {
	my ($mcpan, $module) = @_;
	my $response = $mcpan->module($module) // return undef;
	return $response->distribution;
}

1;

=head1 NAME

App::CPAN::Dependents - Recursively find all reverse dependencies for a
distribution or module

=head1 SYNOPSIS

  use App::CPAN::Dependents 'find_all_dependents';
  my $dependents = find_all_dependents(module => 'JSON::Tiny'); # or dist => 'JSON-Tiny'
  print "Distributions dependent on JSON::Tiny: @$dependents\n";
  
  # From the commandline
  $ cpan-dependents --with-recommends JSON::Tiny
  $ cpan-dependents -c JSON-Tiny

=head1 DESCRIPTION

L<App::CPAN::Dependents> provides the function L</"find_all_dependents">
(exportable on demand) for the purpose of determining all distributions which
are dependent on a particular CPAN distribution or module.

This module uses the MetaCPAN API, and must perform several requests
recursively, so it may take a long time (sometimes minutes) to complete. If the
function encounters HTTP errors (including when querying a nonexistent module
or distribution) or is unable to connect, it will die.

This module will only find distributions that explicitly list prerequisites in
metadata; C<dynamic_config> will not be used. Also, it assumes the MetaCPAN API
will correctly extract the provided modules for distributions, so any unindexed
or unauthorized modules will be ignored.

See L<cpan-dependents> for command-line usage.

=head1 FUNCTIONS

=head2 find_all_dependents

  my $dependents = find_all_dependents(module => 'JSON::Tiny', recommends => 1);

Find all dependent distributions. Returns an array reference of distribution
names. The following parameters are accepted:

=over

=item module

The module name to find dependents for. Mutually exclusive with C<dist>.

=item dist

The distribution to find dependents for. Mutually exclusive with C<module>.

=item http

Optional L<HTTP::Tiny> object to use for building the default
L<MetaCPAN::Client> object.

=item mcpan

Optional L<MetaCPAN::Client> object to use for querying MetaCPAN. If not
specified, a default L<MetaCPAN::Client> object will be created using
L</"http"> if specified.

=item recommends

Boolean value, if true then C<recommends> prerequisites will be considered in
the results. Defaults to false.

=item suggests

Boolean value, if true then C<suggests> prerequisites will be considered in the
results. Defaults to false.

=item develop

Boolean value, if true then C<develop> phase prerequisites will be considered
in the results. Defaults to false.

=item debug

Boolean value, if true then debugging information will be printed to STDERR as
it is retrieved.

=back

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<cpan-dependents>, L<Test::DependentModules>, L<MetaCPAN::Client>,
L<CPAN::Meta::Spec>
