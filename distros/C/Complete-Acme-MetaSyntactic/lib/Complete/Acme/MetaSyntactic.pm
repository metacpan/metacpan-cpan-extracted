package Complete::Acme::MetaSyntactic;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);
use List::Util qw(uniq);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_meta_category
                       complete_meta_theme
                       complete_meta_theme_and_category
               );

#TODO: complete_meta_name

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines for Acme::MetaSyntactic',
};

$SPEC{complete_meta_theme} = {
    v => 1.1,
    summary => 'Complete from list of available themes',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_meta_theme {
    require Complete::Util;
    require PERLANCAR::Module::List;

    my %args = @_;

    my $res = PERLANCAR::Module::List::list_modules(
        "Acme::MetaSyntactic::", {list_modules=>1});
    my @ary = sort keys %$res;
    for (@ary) {
        s/\AAcme::MetaSyntactic:://;
    }
    @ary = grep { !/^[A-Z]/ } @ary;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => \@ary,
    );
}

$SPEC{complete_meta_category} = {
    v => 1.1,
    summary => 'Complete from list of categories for a particular theme',
    args => {
        %arg_word,
        theme => {
            schema => ['str*', match => qr/\A\w+\z/],
            req => 1,
            completion => sub {
                complete_meta_theme(@_);
            },
        },
    },
    result_naked => 1,
};
sub complete_meta_category {
    no strict 'refs';
    require Complete::Util;

    my %args = @_;

    my $theme = $args{theme} or return [];
    my $pkg = "Acme::MetaSyntactic::$theme";
    (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
    eval { require $pkg_pm; 1 } or return [];
    my $meta = $pkg->new;
    Complete::Util::complete_array_elem(
        word => $args{word},
        array => [$pkg->categories],
    );
}

$SPEC{complete_meta_theme_and_category} = {
    v => 1.1,
    summary => 'Complete from list of available themes (or "theme/category")',
    description => <<'_',

This routine can complete from a list of themes, like `complete_meta_theme()`.
Additionally, if the word is in the form of "word/" or "word/rest" then the
"rest" will be completed from list of categories of theme "word".

_
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_meta_theme_and_category {
    require Complete::Util;
    require PERLANCAR::Module::List;

    my %args = @_;
    my $word = $args{word};

    if ($word =~ /\A(\w*)\z/) {
        return complete_meta_theme(word => $word);
    } elsif ($word =~ m!\A(\w+)/((?:/\w+)*\w*)\z!) {
        my ($theme, $cat) = ($1, $2);
        my $themes = complete_meta_theme(word => $theme);
        return [] unless @$themes == 1;
        my $pkg = "Acme::MetaSyntactic::$themes->[0]";
        (my $pkg_pm = "$pkg.pm") =~ s!::!/!g;
        return [] unless eval { require $pkg_pm; 1 };
        my $meta = $pkg->new;
        my $cats = Complete::Util::complete_array_elem(
            word => $cat,
            array => [$meta->categories],
        );
        return [map {"$themes->[0]/$_"} @$cats];
    } else {
        return [];
    }
}

1;
# ABSTRACT: Completion routines for Acme::MetaSyntactic

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Acme::MetaSyntactic - Completion routines for Acme::MetaSyntactic

=head1 VERSION

This document describes version 0.002 of Complete::Acme::MetaSyntactic (from Perl distribution Complete-Acme-MetaSyntactic), released on 2019-07-05.

=head1 FUNCTIONS


=head2 complete_meta_category

Usage:

 complete_meta_category(%args) -> any

Complete from list of categories for a particular theme.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<theme>* => I<str>

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)



=head2 complete_meta_theme

Usage:

 complete_meta_theme(%args) -> any

Complete from list of available themes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)



=head2 complete_meta_theme_and_category

Usage:

 complete_meta_theme_and_category(%args) -> any

Complete from list of available themes (or "theme/category").

This routine can complete from a list of themes, like C<complete_meta_theme()>.
Additionally, if the word is in the form of "word/" or "word/rest" then the
"rest" will be completed from list of categories of theme "word".

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Acme-MetaSyntactic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Acme-MetaSyntactic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Acme-MetaSyntactic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
