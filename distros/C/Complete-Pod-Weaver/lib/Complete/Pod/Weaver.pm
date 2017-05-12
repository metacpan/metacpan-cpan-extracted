package Complete::Pod::Weaver;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_weaver_plugin
                       complete_weaver_section
                       complete_weaver_bundle
                       complete_weaver_role
               );

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Pod::Weaver-related completion routines',
};

$SPEC{complete_weaver_plugin} = {
    v => 1.1,
    summary => 'Complete with installed Pod::Weaver plugin names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_weaver_plugin {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Pod::Weaver::Plugin',
    );
}

$SPEC{complete_weaver_section} = {
    v => 1.1,
    summary => 'Complete with installed Pod::Weaver::Section names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_weaver_section {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Pod::Weaver::Section',
    );
}

$SPEC{complete_weaver_role} = {
    v => 1.1,
    summary => 'Complete with installed Pod::Weaver role names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_weaver_role {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Pod::Weaver::Role',
    );
}

$SPEC{complete_weaver_bundle} = {
    v => 1.1,
    summary => 'Complete with installed Pod::Weaver bundle names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_weaver_bundle {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Pod::Weaver::PluginBundle',
    );
}

1;
# ABSTRACT: Pod::Weaver-related completion routines

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Pod::Weaver - Pod::Weaver-related completion routines

=head1 VERSION

This document describes version 0.05 of Complete::Pod::Weaver (from Perl distribution Complete-Pod-Weaver), released on 2015-11-29.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 complete_weaver_bundle(%args) -> any

Complete with installed Pod::Weaver bundle names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_weaver_plugin(%args) -> any

Complete with installed Pod::Weaver plugin names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_weaver_role(%args) -> any

Complete with installed Pod::Weaver role names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_weaver_section(%args) -> any

Complete with installed Pod::Weaver::Section names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Pod-Weaver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Pod-Weaver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Pod-Weaver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
