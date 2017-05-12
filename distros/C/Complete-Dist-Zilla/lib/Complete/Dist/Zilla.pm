package Complete::Dist::Zilla;

our $DATE = '2015-11-30'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_dzil_plugin
                       complete_dzil_bundle
                       complete_dzil_role
               );

$SPEC{complete_dzil_plugin} = {
    v => 1.1,
    summary => 'Complete with installed Dist::Zilla plugin names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_dzil_plugin {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Dist::Zilla::Plugin',
    );
}

$SPEC{complete_dzil_role} = {
    v => 1.1,
    summary => 'Complete with installed Dist::Zilla role names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_dzil_role {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Dist::Zilla::Role',
    );
}

$SPEC{complete_dzil_bundle} = {
    v => 1.1,
    summary => 'Complete with installed Dist::Zilla bundle names',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_dzil_bundle {
    require Complete::Module;

    my %args = @_;

    my $word = $args{word} // '';

    Complete::Module::complete_module(
        word => $word,
        ns_prefix => 'Dist::Zilla::PluginBundle',
    );
}

1;
# ABSTRACT: Complete with installed Dist::Zilla plugin names

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Dist::Zilla - Complete with installed Dist::Zilla plugin names

=head1 VERSION

This document describes version 0.07 of Complete::Dist::Zilla (from Perl distribution Complete-Dist-Zilla), released on 2015-11-30.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 complete_dzil_bundle(%args) -> any

Complete with installed Dist::Zilla bundle names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_dzil_plugin(%args) -> any

Complete with installed Dist::Zilla plugin names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)


=head2 complete_dzil_role(%args) -> any

Complete with installed Dist::Zilla role names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Dist-Zilla>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Dist-Zilla>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Dist-Zilla>

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
