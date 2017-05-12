package Complete::Kernel;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       complete_kernel
               );

our %SPEC;

$SPEC{complete_kernel} = {
    v => 1.1,
    summary => 'Complete kernel name',
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_kernel {
    require Complete::Util;

    my %args  = @_;

    my %kernels;
    {
        opendir my($dh), "/lib/modules" or last;
        while (my $e = readdir($dh)) {
            next if $e eq '.' || $e eq '..';
            $kernels{$e}++;
        }
    }

    Complete::Util::complete_hash_key(
        word=>$args{word}, hash=>\%kernels,
    );
}

1;
# ABSTRACT: Complete kernel name

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Kernel - Complete kernel name

=head1 VERSION

This document describes version 0.001 of Complete::Kernel (from Perl distribution Complete-Kernel), released on 2016-10-18.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_kernel(%args) -> array

Complete kernel name.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Kernel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Kernel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Kernel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
