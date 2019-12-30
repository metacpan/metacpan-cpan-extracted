package App::RetroPAN;
# vim:ts=4:shiftwidth=4:expandtab

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

App::RetroPAN - Makes a historic minicpan ⏳

=head1 SYNOPSIS

  use App::RetroCPAN;

  my ($author, $dist_name, $url) = find_module_on_date("2011-01-01T00:00:00", "Moose");

=head1 DESCRIPTION

Uses the MetaCPAN API to find releases made prior to a given date to
satisfy your modules' dependencies.

=head1 SEE ALSO

=over

=item *

L<retropan>

=item *

L<OrePAN2>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Dave Lambley <dlambley@cpan.org>

=cut

use HTTP::Request;
use LWP::UserAgent;
use List::MoreUtils qw/ uniq /;
use Module::CoreList;
use OrePAN2::Injector;
use OrePAN2::Indexer;

use Cpanel::JSON::XS qw/ encode_json decode_json /;

our $VERSION = '0.03';

my $ua = LWP::UserAgent->new( keep_alive => 2, agent => "retropan/$VERSION" );

sub find_module_dependencies {
    my ($au, $dist) = @_;

    my $q = {
        "size" => 1,
        "query" => {
            "bool" => {
                "filter" => [
                    {
                        "match" => {
                            "name" => $dist,
                        }
                    },
                    {
                        "match" => {
                            "author" => $au,
                        }
                    },

                ],
            }
        }
    };

    my $req = HTTP::Request->new( POST => 'https://fastapi.metacpan.org/v1/release/_search', [
        "Content-Type" => "text/json",
        "Accept" => "text/json"
    ], encode_json($q) );

    my $res = $ua->request($req);
    die $res->status_line if !$res->is_success;
    my $data = decode_json($res->decoded_content);
    my $hit = $data->{hits}->{hits}->[0];
    if (!defined $hit) {
        warn "could not find $au/$dist";
        return;
    }

    my @deps =
        grep { !Module::CoreList::is_core($_) }
        grep { $_ ne "perl" }
        map { $_->{module} } @{ $hit->{_source}->{dependency} };

    return @deps;
}
sub find_module_on_date {
    my ($module, $before) = @_;

    return if Module::CoreList::is_core($module);

    # We prefer authorized modules, but can fall back to unauthorized if none
    # available.
    my $q = {
        "size" => 30, # TODO, keep search open.
        "sort" => [
            { "module.authorized" => "desc" },
            { "version_numified" => "desc" },
            "_score",
        ],
        "query" => {
            "bool" => {
                "filter" => [
                    {
                        "match" => {
                            "module.name" => $module,
                        }
                    },
                    {
                        "match" => {
                            "maturity" => "released",
                        }
                    },
                    {
                        "range" => { "date" => {"lt" => $before }}
                    },
                ],
            }
        }
    };

    my $req = HTTP::Request->new( POST => 'https://fastapi.metacpan.org/v1/module/_search', [
        "Content-Type" => "text/json",
        "Accept" => "text/json"
    ], encode_json($q) );

    my $res = $ua->request($req);
    die $res->status_line if !$res->is_success;
    my $data = decode_json($res->decoded_content);


    my $author;
    my $version = -1;
    my $release;
    my $url;
    my $authorized;

    # Some distributions re-release  existing modules outside their own
    # distribution, eg., perl-5.005-minimal-bin-0-arm-linux
    # We therefore iterate through all modules returned to find the newest
    # version.
    foreach my $hit (@{ $data->{hits}->{hits} }) {
	next if $hit->{_source}->{distribution} eq 'perl';
        foreach my $mod (@{ $hit->{_source}->{module} }) {
            if (($authorized ? $mod->{authorized} : 1) && $mod->{name} eq $module && $mod->{version_numified} > $version) {
                $author     = $hit->{_source}->{author};
                $release    = $hit->{_source}->{release};
                $url        = $hit->{_source}->{download_url};
                $version    = $mod->{version_numified};
                $authorized = $mod->{authorized};
            }
        }
    }


    if (!defined $release) {
        warn "could not find $module before $before";
        return;
    }

    return ($author, $release, $url);
}

sub find_deps_on_date {
    my ($before, @modules) = @_;

    my %done_modules;
    my @dists_required;
    my %dist_to_url;

    while (@modules) {
        my $mod = pop @modules;
        next if $done_modules{$mod};

        my ($au, $dist, $url) = find_module_on_date($mod, $before);
        $done_modules{$mod} = 1;
        next if !defined($au) || !defined($dist);
        $dist_to_url{"$au/$dist"} = $url;

        push @modules, find_module_dependencies($au, $dist);
        unshift @dists_required, "$au/$dist";
    }

    return (
        [uniq @dists_required],
        \%dist_to_url,
    );
}

sub make_minicpan {
    my ($localdir, $dists_required, $dist_to_url) = @_;

    my $injector = OrePAN2::Injector->new(
        directory => $localdir,
        author_subdir => 1
    );

    foreach my $d (@{ $dists_required }) {
        my ($author, $dist) = split(/\//, $d, 2);
        $injector->inject(
            $dist_to_url->{$d} // die,
            {
                author => $author,
            }
        );
    }

    # XXX undocumented.
    my $orepan = OrePAN2::Indexer->new(
        directory => $localdir,
        metacpan  => 0,
        simple    => 1,
    );
    $orepan->make_index(
        no_compress => 1,
    );
    return;
}
