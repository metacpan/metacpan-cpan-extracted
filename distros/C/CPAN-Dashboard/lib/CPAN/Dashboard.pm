package CPAN::Dashboard;
$CPAN::Dashboard::VERSION = '0.02';
use 5.010;
use Moo;
use JSON qw(decode_json);
use Carp;
use PAUSE::Packages;
use PAUSE::Permissions;
use HTTP::Tiny;
use JSON;
use CPAN::ReverseDependencies;
use CPAN::Testers::WWW::Reports::Query::AJAX;

use CPAN::Dashboard::Distribution;
use CPAN::Dashboard::Distribution::Kwalitee;
use CPAN::Dashboard::Distribution::CPANTesters;

has 'author'             => ( is => 'ro' );
has 'distribution_names' => ( is => 'ro' );
has 'distributions'      => ( is => 'lazy' );

sub _build_distributions
{
    my $self = shift;
    my @dist_names;
    my $iterator = PAUSE::Packages->new()->release_iterator(well_formed => 1);
    my $ua       = HTTP::Tiny->new();
    my %distmap;
    my ($url, $response, $dist);
    my %owner;

    while (my $release = $iterator->next_release) {
        my $distinfo = $release->distinfo;
        next unless ($self->author && $distinfo->cpanid eq $self->author)
                 || (   $self->distribution_names
                     && grep { $distinfo->dist eq $_ } @{ $self->distribution_names });
        $dist = CPAN::Dashboard::Distribution->new(
                    name         => $distinfo->dist,
                    release_path => $release->path,
                    version      => $distinfo->version,
                    is_developer => $distinfo->maturity eq 'developer',
                    distinfo     => $distinfo,
                    modules      => $release->modules,
                );
        $distmap{ $distinfo->dist } = $dist;

        # by setting this, we identify all modules associated with this dashboard
        if (defined($release->modules)) {
            $owner{$_->name} = undef for @{ $release->modules};
        }
    }

    # get and set counts of bugs and reverse dependencies
    my $revua = CPAN::ReverseDependencies->new();
    foreach my $distname (keys %distmap) {
        $dist     = $distmap{$distname};
        $url      = sprintf('https://api.metacpan.org/distribution/%s', $distname);
        $response = $ua->get($url);

        if (!$response->{success}) {
            warn "Failed to get bug count for dist '$distname'\n";
        }
        else {
            my $bug_data = decode_json($response->{content});
            $dist->bug_count($bug_data->{bugs}->{active} // 0);
        }

        #
        # Count of reverse dependencies
        # TODO: changes this to a list of dist names?
        #
        my @deps = $revua->get_reverse_dependencies($distname);
        $dist->rev_deps_count(int(@deps));

        #
        # CPAN Testers stats
        # TODO: possibly just put the ::AJAX instance, rather than our own class
        #
        my $testers = CPAN::Testers::WWW::Reports::Query::AJAX->new(dist => $distname);
        if (!defined($testers)) {
            warn "Failed to get CPAN Testers results for dist '$distname'\n";
        }
        else {
            $dist->cpan_testers(CPAN::Dashboard::Distribution::CPANTesters->new(
                                   passes   => $testers->pass,
                                   fails    => $testers->fail,
                                   na       => $testers->na,
                                   unknowns => $testers->unknown,
                               ));
        }

        #
        # Kwalitee
        # TODO: get the individual kwalitee fields
        #
        $url      = sprintf('http://cpants.cpanauthors.org/dist/%s', $distname);
        $response = $ua->get($url);

        if ($response->{success}
            && $response->{content} =~ m!<tr><th>Kwalitee</th><td>(.*?)</td></tr>.*?<tr><th>Core Kwalitee</th><td>(.*?)</td></tr>!mgs) {
            $dist->kwalitee(CPAN::Dashboard::Distribution::Kwalitee->new(
                                kwalitee      => $1,
                                core_kwalitee => $2,
                           ));
        }
        else {
            warn "Failed to get Kwalitee results for dist '$distname'\n";
        }

    }

    # First we get the owner for every module we're interested in
    $iterator = PAUSE::Permissions->new()->module_iterator();
    while (my $module = $iterator->next_module) {
        next unless exists($owner{$module->name});
        $owner{$module->name} = $module->owner if defined($module->owner);
    }

    foreach my $distname (keys %distmap) {
        my %seen;
        $dist = $distmap{$distname};
        foreach my $module (@{ $dist->modules }) {
            $seen{ $owner{$module->name} // '__undef' } = 1;
        }
        print STDERR "OWNER $distname: ", join(', ', keys %seen), "\n";
        $dist->owner( [keys %seen] );
    }

    return [sort { $a->rating <=> $b->rating } values %distmap];
}

1;

=head1 NAME

CPAN::Dashboard - generate a dashboard of information about a selection of CPAN dists

=head1 SYNOPSIS

 use CPAN::Dashboard;

 my $dashboard = CPAN::Dashboard->new(author => 'NEILB');
 foreach my $dist (@{ $dashboard->distributions }) {
    ...
 }

=head1 DESCRIPTION

CPAN::Dashboard constructs a list of I<distribution> objects,
which can then be used to construct a CPAN dashboard.
You either specify a CPAN author, in which case all the author's
current dists are used,
or you pass a list of distribution names.

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-Dashboard>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

