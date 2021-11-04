package DateTime::Patch::AddDowNameToYmd;

use strict;
use warnings;

use parent qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-06'; # DATE
our $DIST = 'DateTime-Patch-AddDowNameToYmd'; # DIST
our $VERSION = '0.001'; # VERSION

my @dow_names = qw(0 mo tu we th fr sa su);

sub _wrap_ymd {
    my $ctx = shift;
    my $res = $ctx->{orig}->(@_);
    my $self = $_[0];
    $res .= $dow_names[$self->day_of_week];
}

sub patch_data {
    return {
        v => 3,
        config => {
        },
        patches => [
            {
                action => 'wrap',
                #mod_version => qr/^6\./,
                sub_name => 'ymd',
                code => \&_wrap_ymd,
            },
        ],
    };
}

1;
# ABSTRACT: Make DateTime's ymd() output YYYY-MM-DDXX instead of YYYY-MM-DD, where XX is 2-letter day-of-week name

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Patch::AddDowNameToYmd - Make DateTime's ymd() output YYYY-MM-DDXX instead of YYYY-MM-DD, where XX is 2-letter day-of-week name

=head1 VERSION

This document describes version 0.001 of DateTime::Patch::AddDowNameToYmd (from Perl distribution DateTime-Patch-AddDowNameToYmd), released on 2021-09-06.

=head1 SYNOPSIS

 use DateTime::Patch::AddDowNameToYmd;
 use DateTime;

 say DateTime->now->ymd; # => "2021-09-06mo"

=head1 DESCRIPTION

Note that many code expects C<ymd()> to be YYYY-MM-DD only, so use this at your
own peril.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Patch-AddDowNameToYmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Patch-AddDowNameToYmd>.

=head1 SEE ALSO

L<DateTime>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Patch-AddDowNameToYmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
