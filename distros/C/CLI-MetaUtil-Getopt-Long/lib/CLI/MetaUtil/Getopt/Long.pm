package CLI::MetaUtil::Getopt::Long;

use strict 'subs', 'vars';
use warnings;

use Getopt::Long ();

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-07'; # DATE
our $DIST = 'CLI-MetaUtil-Getopt-Long'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(GetOptionsCLIWrapper);
our %SPEC;

our @cli_argv;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Routine related to Getopt::Long',
};

$SPEC{GetOptionsCLIWrapper} = {
    v => 1.1,
    summary => 'Get options for a CLI wrapper',
    description => <<'_',

This routine can be used to get options for your CLI wrapper. For example, if
you are creating a wrapper for the `diff` command, this routine will let you
collect all known `diff` options (declared in <pm:CLI::Meta::diff>) while
letting you add new options.

_
    args => {
        cli => {
            schema => 'str*',
            req => 1,
        },
        add_opts => {
            schema => 'hash*',
        },
    },
    result_naked => 1,
};
sub GetOptionsCLIWrapper {
    my %args = @_;
    my $cli = $args{cli} or die "Please specify 'cli' argument";

    my %opts;
    my $mod = "CLI::Meta::$cli";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;
    my $meta = ${"$mod\::META"};

    @cli_argv = ();
    my $code_push_opt     = sub { my ($cb, $optval) = @_; my $optname = $cb->name; push @cli_argv, (length($optname) > 1 ? "--" : "-").$optname };
    my $code_push_opt_val = sub { my ($cb, $optval) = @_; my $optname = $cb->name; push @cli_argv, (length($optname) > 1 ? "--" : "-").$optname, $optval };
    for my $optspec (keys %{ $meta->{opts} }) {
        $opts{$optspec} = $optspec =~ /=/ ? $code_push_opt_val : $code_push_opt;
    }
    if ($args{add_opts}) {
        for my $optname (keys %{ $args{add_opts} }) {
            $opts{$optname} = $args{add_opts}{$optname};
        }
    }

    Getopt::Long::GetOptions(%opts);
    @ARGV = @cli_argv;
}

1;
# ABSTRACT: Routine related to Getopt::Long

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::MetaUtil::Getopt::Long - Routine related to Getopt::Long

=head1 VERSION

This document describes version 0.003 of CLI::MetaUtil::Getopt::Long (from Perl distribution CLI-MetaUtil-Getopt-Long), released on 2022-10-07.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 GetOptionsCLIWrapper

Usage:

 GetOptionsCLIWrapper(%args) -> any

Get options for a CLI wrapper.

This routine can be used to get options for your CLI wrapper. For example, if
you are creating a wrapper for the C<diff> command, this routine will let you
collect all known C<diff> options (declared in L<CLI::Meta::diff>) while
letting you add new options.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_opts> => I<hash>

=item * B<cli>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CLI-MetaUtil-Getopt-Long>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CLI-MetaUtil-Getopt-Long>.

=head1 SEE ALSO

L<CLI::MetaUtil::Getopt::Long::Complete>

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CLI-MetaUtil-Getopt-Long>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
