package App::PDRUtils::MultiCmd;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.120'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::PDRUtils::Cmd;
use App::PDRUtils::DistIniCmd;
use File::chdir;
use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Object;

our %common_args = (
    repos => {
        summary => '',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'repo',
        schema => ['array*', of=>'str*'],
        tags => ['common'],
    },

    # XXX has_dist_ini filter option

    depends => {
        summary => 'Only include repos that has prereq to specified module(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },

    doesnt_depend => {
        summary => 'Exclude repos that has prereq to specified module(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },

    include_dists => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_dist',
        summary => 'Only include repos which have specified name(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },
    exclude_dists => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'exclude_dist',
        summary => 'Exclude repos which have specified name(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },
    include_dist_patterns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_dist_pattern',
        summary => 'Only include repos which match specified pattern(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },
    exclude_dist_patterns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'exclude_dist_pattern',
        summary => 'Exclude repos which match specified pattern(s)',
        schema => ['array*', of=>'str*'],
        tags => ['common', 'category:fitering'],
    },
    has_tags => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'has_tag',
        summary => 'Only include repos which have specified tag(s)',
        description => <<'_',

A repo can be tagged by tag `X` if it has a top-level file named `.tag-X`.

_
        schema => ['array*', of=>['str*'=>match=>qr/\A[A-Za-z0-9_-]+\z/]],
        tags => ['common', 'category:fitering'],
    },
    lacks_tags => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'lacks_tag',
        summary => 'Exclude repos which have specified tag(s)',
        description => <<'_',

A repo can be tagged by tag `X` if it has a top-level file named `.tag-X`.

_
        schema => ['array*', of=>['str*'=>match=>qr/\A[A-Za-z0-9_-]+\z/]],
        tags => ['common', 'category:fitering'],
    },
);

sub _ciod {
    state $ciod = do {
        require Config::IOD;
        Config::IOD->new(
            ignore_unknown_directive => 1,
        );
    };
    $ciod;
}

sub _for_each_repo {
    require File::Slurper;

    my ($opts, $pargs, $callback) = @_;

    $opts //= {};

    local $CWD = $CWD;
    my $envres = envresmulti();
  REPO:
    for my $repo (@{ $pargs->{repos} }) {
        log_trace("Processing repo %s ...", $repo);

        eval { $CWD = $repo };
        if ($@) {
            log_warn("Can't cd to repo %s, skipped", $repo);
            $envres->add_result(500, "Can't cd to repo", {item_id=>$repo});
            next REPO;
        }

        my $requires_parsed_dist_ini = $opts->{requires_parsed_dist_ini} //
            (grep {defined($pargs->{$_})} qw/
                                                depends doesnt_depend
                                                include_dists exclude_dists
                                                include_dist_patterns exclude_dist_patterns
                                            /);
        my $requires_dist_ini = $opts->{requires_dist_ini};
        $requires_dist_ini ||= $requires_parsed_dist_ini;

        my $dist_ini;
        my $parsed_dist_ini;

        if ($requires_dist_ini) {
            unless (-f "dist.ini") {
                log_warn("No dist.ini in repo %s, skipped", $repo);
                $envres->add_result(412, "No dist.ini in repo", {item_id=>$repo});
                next REPO;
            }
            $dist_ini = File::Slurper::read_text("dist.ini");
        }

        if ($requires_parsed_dist_ini) {
            eval { $parsed_dist_ini = _ciod->read_string($dist_ini) };
            if ($@) {
                log_warn("Can't parse dist.ini in repo %s, skipped", $repo);
                $envres->add_result(412, "Can't parse dist.ini: $@");
                next REPO;
            }
        }

        my $excluded;
        my $dist_name = $parsed_dist_ini->get_value("GLOBAL", "name");
      FILTER:
        {
          INCLUDE_DISTS:
            {
                last unless $pargs->{include_dists} && @{ $pargs->{include_dists} };
                unless (defined $dist_name) {
                    log_warn("Dist name undefined in repo %s, skipped", $repo);
                    $excluded++;
                    last FILTER;
                }
                for my $d (@{ $pargs->{include_dists} }) {
                    if ($dist_name eq $d) {
                        last INCLUDE_DISTS;
                    }
                }
                log_trace("Skipping repo (not in include_dists)");
                $excluded++;
                last FILTER;
            }
          EXCLUDE_DISTS:
            {
                last unless $pargs->{exclude_dists} && @{ $pargs->{exclude_dists} };
                unless (defined $dist_name) {
                    log_warn("Dist name undefined in repo %s, skipped", $repo);
                    $excluded++;
                    last FILTER;
                }
                for my $d (@{ $pargs->{exclude_dists} }) {
                    if ($dist_name eq $d) {
                        log_trace("Skipping repo (in exclude_dists)");
                        $excluded++;
                        last FILTER;
                    }
                }
            }
          INCLUDE_DIST_PATTERNS:
            {
                last unless $pargs->{include_dist_patterns} && @{ $pargs->{include_dist_patterns} };
                unless (defined $dist_name) {
                    log_warn("Dist name undefined in repo %s, skipped", $repo);
                    $excluded++;
                    last FILTER;
                }
                for my $d (@{ $pargs->{include_dist_patterns} }) {
                    if ($dist_name =~ /$d/) {
                        last INCLUDE_DIST_PATTERNS;
                    }
                }
                log_trace("Skipping repo (doesn't match include_dist_patterns)");
                $excluded++;
                last FILTER;
            }
          EXCLUDE_DIST_PATTERNS:
            {
                last unless $pargs->{exclude_dist_patterns} && @{ $pargs->{exclude_dist_patterns} };
                unless (defined $dist_name) {
                    log_warn("Dist name undefined in repo %s, skipped", $repo);
                    $excluded++;
                    last FILTER;
                }
                for my $d (@{ $pargs->{exclude_dist_patterns} }) {
                    if ($dist_name =~ /$d/) {
                        log_trace("Skipping repo (match exclude_dist_patterns)");
                        $excluded++;
                        last FILTER;
                    }
                }
            }
          DEPENDS:
            {
                my $mods = $pargs->{depends};
                last unless $mods && @$mods;
                for my $mod (@$mods) {
                    if (App::PDRUtils::Cmd::_has_prereq($parsed_dist_ini, $mod)) {
                        last DEPENDS;
                    }
                }
                log_trace("Skipping repo %s (doesn't depend on ".join("/", @$mods).")", $repo);
                $excluded++;
                last FILTER;
            }
          DOESNT_DEPEND:
            {
                my $mods = $pargs->{doesnt_depend};
                last unless $mods && @$mods;
                for my $mod (@$mods) {
                    if (App::PDRUtils::Cmd::_has_prereq($parsed_dist_ini, $mod)) {
                        log_trace("Skipping repo %s (depends on $mod)", $repo);
                        $excluded++;
                        last FILTER;
                    }
                }
            }
          HAS_TAGS:
            {
                last unless $pargs->{has_tags} && @{ $pargs->{has_tags} };
                for my $t (@{ $pargs->{has_tags} }) {
                    if (-f ".tag-$t") {
                        last HAS_TAGS;
                    }
                }
                log_trace("Skipping repo (doesn't have any tag in has_tags)");
                $excluded++;
                last FILTER;
            }
          LACKS_TAGS:
            {
                last unless $pargs->{lacks_tags} && @{ $pargs->{lacks_tags} };
                for my $t (@{ $pargs->{lacks_tags} }) {
                    if (-f ".tag-$t") {
                        log_trace("Skipping repo (has tag '$t' in lacks_tags)");
                        $excluded++;
                        last FILTER;
                    }
                }
            }
        }
        next REPO if $excluded;

        my $res = $callback->(
            parent_args => $pargs,
            repo => $repo,
            (dist => $dist_name) x !!defined($dist_name),
            (dist_ini => $dist_ini) x !!defined($dist_ini),
            (parsed_dist_ini => $parsed_dist_ini) x !!defined($parsed_dist_ini),
        );
        log_trace("Result for repo '%s': %s", $repo, $res);
        if ($res->[0] != 200 && $res->[0] != 304) {
            log_warn("Processing repo %s failed: %s", $repo, $res);
        }
        $envres->add_result(@$res, {item_id=>$repo});
    }
    $envres->as_struct;
}

sub create_cmd_from_dist_ini_cmd {
    no strict 'refs';

    my %cargs = @_;

    my $name = $cargs{dist_ini_cmd};

    my $source_pkg = "App::PDRUtils::DistIniCmd::$name";
    my $target_pkg = caller();#"App::PDRUtils::MultiCmd::$name";

    eval "use $source_pkg"; die if $@;

    my $source_specs = \%{"$source_pkg\::SPEC"};
    my $spec = clone($source_specs->{handle_cmd});

    for (keys %App::PDRUtils::DistIniCmd::common_args) {
        delete $spec->{args}{$_};
    }
    for (keys %common_args) {
        $spec->{args}{$_} = $common_args{$_};
    }
    $spec->{features}{dry_run} = 1;

    ${"$target_pkg\::SPEC"}{handle_cmd} = $spec;
    *{"$target_pkg\::handle_cmd"} = sub {
        my %fargs = @_;

        _for_each_repo(
            {requires_parsed_dist_ini => 1},
            \%fargs,
            sub {
                my %cbargs = @_;

                my $repo = $cbargs{repo};
                my $dist = $cbargs{dist};
                my $pargs = $cbargs{parent_args};

                my %diargs;
                $diargs{parsed_dist_ini} = $cbargs{parsed_dist_ini};
                for (keys %{$spec->{args}}) {
                    $diargs{$_} = $pargs->{$_} if exists $pargs->{$_};
                }

                my $handle_cmd = \&{"$source_pkg\::handle_cmd"};
                my $res = $handle_cmd->(%diargs);

                if ($res->[0] == 200) {
                    log_info("%s[dist %s] %s",
                                $fargs{-dry_run} ? "[DRY-RUN] " : "",
                                $dist,
                                $res->[1]);
                    if ($fargs{-dry_run}) {
                        $res->[0] = 304;
                    } else {
                        File::Slurper::write_text(
                            "dist.ini", $res->[2]->as_string);
                    }
                    undef $res->[2];
                } else {
                    log_trace("%d - %s", $res->[0], $res->[1]);
                }
                $res;
            }, # callback
        ); # for each repo
    };
}

1;
# ABSTRACT: Common stuffs for App::PDRUtils::MultiCmd::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::MultiCmd - Common stuffs for App::PDRUtils::MultiCmd::*

=head1 VERSION

This document describes version 0.120 of App::PDRUtils::MultiCmd (from Perl distribution App-PDRUtils), released on 2018-04-03.

=head1 DESCRIPTION

A module in L<App::PDRUtils::MultiCmd> namespace represents a subcommand for the
L<pdrutil-multi> utility.

=head1 FUNCTIONS

=head2 create_cmd_from_dist_ini_cmd(%args)

Turn a DistIniCmd into a MultiCmd.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
