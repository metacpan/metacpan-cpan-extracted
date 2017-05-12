package Complete::FS;

our $DATE = '2015-11-29'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_fs
               );

our %SPEC;

$SPEC{complete_fs} = {
    v => 1.1,
    summary => 'Complete filesystem name on the local system',
    args => {
        word => {
            schema  => [str=>{default=>''}],
            req     => 1,
            pos     => 0,
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
    'x.no_index' => 1,
};
sub complete_fs {
    die "Not yet implemented";
}

1;
# ABSTRACT: Complete filesystem name on the local system

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::FS - Complete filesystem name on the local system

=head1 VERSION

This document describes version 0.02 of Complete::FS (from Perl distribution Complete-FS), released on 2015-11-29.

=head1 DESCRIPTION

B<NAME GRAB. NOT YET IMPLEMENTED.>

=for Pod::Coverage .+

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-FS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-FS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-FS>

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
