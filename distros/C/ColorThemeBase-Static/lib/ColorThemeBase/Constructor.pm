package ColorThemeBase::Constructor;

use strict 'subs', 'vars';
#use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.009'; # VERSION

sub new {
    my $class = shift;

    # check that %THEME exists
    my $theme_hash = \%{"$class\::THEME"};
    unless (defined $theme_hash->{v}) {
        die "Class $class does not define \%THEME with 'v' key";
    }
    unless ($theme_hash->{v} == 2) {
        die "\%$class\::THEME's v is $theme_hash->{v}, I only support v=2";
    }

    # check for known and required arguments
    my %args = @_;
    {
        my $args_spec = $theme_hash->{args};
        last unless $args_spec;
        for my $arg_name (keys %args) {
            die "Unknown argument '$arg_name'" unless $args_spec->{$arg_name};
        }
        for my $arg_name (keys %$args_spec) {
            die "Missing required argument '$arg_name'"
                if $args_spec->{$arg_name}{req} && !exists($args{$arg_name});
            # apply default
            $args{$arg_name} = $args_spec->{$arg_name}{default}
                if !defined($args{$arg_name}) &&
                exists $args_spec->{$arg_name}{default};
        }
    }

    bless {
        args => \%args,

        # we store this because applying roles to object will rebless the object
        # into some other package.
        orig_class => $class,
    }, $class;
}

1;
# ABSTRACT: Provide new()

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeBase::Constructor - Provide new()

=head1 VERSION

This document describes version 0.009 of ColorThemeBase::Constructor (from Perl distribution ColorThemeBase-Static), released on 2024-07-17.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

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

This software is copyright (c) 2024, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
