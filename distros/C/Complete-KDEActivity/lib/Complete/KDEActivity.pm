package Complete::KDEActivity;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-07'; # DATE
our $DIST = 'Complete-KDEActivity'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       complete_kde_activity_guid
                       complete_kde_activity_name
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to KDE activities',
};

$SPEC{complete_kde_activity_name} = {
    v => 1.1,
    summary => 'Complete from a list of existing KDE activity names',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_kde_activity_name {
    require Complete::Util;
    require Desktop::KDEActivity::Util;

    my %args = @_;

    my $res = Desktop::KDEActivity::Util::list_kde_activities(detail=>1);
    return {message=>"Can't list KDE activities: $res->[0] - $res->[1]"}
        unless $res->[0] == 200;

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => [map {$_->{name}} @{ $res->[2] }],
    );
}

$SPEC{complete_kde_activity_guid} = {
    v => 1.1,
    summary => 'Complete from a list of existing KDE activity GUIDs',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_kde_activity_guid {
    require Complete::Util;
    require Desktop::KDEActivity::Util;

    my %args = @_;

    my $res = Desktop::KDEActivity::Util::list_kde_activities(detail=>1);
    return {message=>"Can't list KDE activities: $res->[0] - $res->[1]"}
        unless $res->[0] == 200;

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => [map {$_->{guid}} @{ $res->[2] }],
    );
}

1;
# ABSTRACT: Completion routines related to KDE activities

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::KDEActivity - Completion routines related to KDE activities

=head1 VERSION

This document describes version 0.001 of Complete::KDEActivity (from Perl distribution Complete-KDEActivity), released on 2026-04-07.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_kde_activity_guid

Usage:

 complete_kde_activity_guid(%args) -> any

Complete from a list of existing KDE activity GUIDs.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

(No description)


=back

Return value:  (any)



=head2 complete_kde_activity_name

Usage:

 complete_kde_activity_name(%args) -> any

Complete from a list of existing KDE activity names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-KDEActivity>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-KDEActivity>.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-KDEActivity>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
