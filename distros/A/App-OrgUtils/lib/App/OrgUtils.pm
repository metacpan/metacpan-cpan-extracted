package App::OrgUtils;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.46'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Org::Parser;

our %common_args1 = (
    files => {
        schema => ['array*' => of => 'str*', min_len=>1],
        req    => 1,
        pos    => 0,
        greedy => 1,
        'x.schema.element_entity' => 'filename',
        'x.name.is_plural' => 1,
    },
    time_zone => {
        schema => ['str'],
        summary => 'Will be passed to parser\'s options',
        description => <<'_',

If not set, TZ environment variable will be picked as default.

_
        'x.schema.entity' => 'timezone',
    },
);

our $_complete_state = sub {
    use experimental 'smartmatch';
    require Complete::Util;

    my %args = @_;

    # only return answer under CLI
    return undef unless my $cmdline = $args{cmdline};
    my $r = $args{r};

    # force read config
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    return undef unless $res->[0] == 200;
    my $args = $res->[2];

    # read org
    return unless $args->{files} && @{ $args->{files} };
    my $tz = $args->{time_zone} // $ENV{TZ} // "UTC";
    my %docs = App::OrgUtils::_load_org_files(
        [grep {-f} @{ $args->{files} }], {time_zone=>$tz});

    # get todo states
    my @states;
    for my $doc (values %docs) {
        for (@{ $doc->todo_states }, @{ $doc->done_states }) {
            push @states, $_ unless $_ ~~ @states;
        }
    }
    Complete::Util::complete_array_elem(array=>\@states, word=>$args{word});
};

our $_complete_priority = sub {
    use experimental 'smartmatch';
    require Complete::Util;

    my %args = @_;

    # only return answer under CLI
    return undef unless my $cmdline = $args{cmdline};
    my $r = $args{r};

    # force read config
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    return undef unless $res->[0] == 200;
    my $args = $res->[2];

    # read org
    return unless $args->{files} && @{ $args->{files} };
    my $tz = $args->{time_zone} // $ENV{TZ} // "UTC";
    my %docs = App::OrgUtils::_load_org_files(
        [grep {-f} @{ $args->{files} }], {time_zone=>$tz});

    # get priorities
    my @prios;
    for my $doc (values %docs) {
        for (@{ $doc->priorities }) {
            push @prios, $_ unless $_ ~~ @prios;
        }
    }
    Complete::Util::complete_array_elem(array=>\@prios, word=>$args{word});
};

our $_complete_tags = sub {
    use experimental 'smartmatch';
    require Complete::Util;

    my %args = @_;

    # only return answer under CLI
    return undef unless my $cmdline = $args{cmdline};
    my $r = $args{r};

    # force read config
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    return undef unless $res->[0] == 200;
    my $args = $res->[2];

    # read org
    return unless $args->{files} && @{ $args->{files} };
    my $tz = $args->{time_zone} // $ENV{TZ} // "UTC";
    my %docs = App::OrgUtils::_load_org_files(
        [grep {-f} @{ $args->{files} }], {time_zone=>$tz});

    # collect tags
    my @tags;
    for my $doc (values %docs) {
        $doc->walk(
            sub {
                my $el = shift;
                return unless $el->isa('Org::Element::Headline');
                for ($el->get_tags) {
                    push @tags, $_ unless $_ ~~ @tags;
                }
            }
        );
    }
    Complete::Util::complete_array_elem(array=>\@tags, word=>$args{word});
};

sub _load_org_files {
    require Cwd;
    require Digest::MD5;

    my ($files, $opts0) = @_;
    $files or die "Please specify files";

    my $orgp = Org::Parser->new;
    my %docs;
    for my $file (@$files) {
        my $opts = { %{$opts0 // {}} };
        # by default turn on cache, unless user specifically has
        # PERL_ORG_PARSER_CACHE set to 0.
        $opts->{cache} = 1 if $ENV{PERL_ORG_PARSER_CACHE} // 1;
        $docs{$file} = $orgp->parse_file($file, $opts);
    }

    %docs;
}

1;
# ABSTRACT: Some utilities for Org documents

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OrgUtils - Some utilities for Org documents

=head1 VERSION

This document describes version 0.46 of App::OrgUtils (from Perl distribution App-OrgUtils), released on 2017-07-10.

=head1 DESCRIPTION

This distribution includes a few modules (scripts) for dealing with Org
documents; some originally created as examples/demos for L<Org::Parser>. The
following are the included scripts:

=over

=item * L<count-done-org-todos>

=item * L<count-org-todos>

=item * L<count-undone-org-todos>

=item * L<dump-org-structure>

=item * L<list-org-anniversaries>

=item * L<list-org-headlines>

=item * L<list-org-priorities>

=item * L<list-org-tags>

=item * L<list-org-todo-states>

=item * L<list-org-todos>

=item * L<move-done-todos>

=item * L<org2html>

=item * L<org2html-wp>

=item * L<stat-org-document>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-OrgUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OrgUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OrgUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Org::Parser>

L<orgsel> in L<App::orgsel>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
