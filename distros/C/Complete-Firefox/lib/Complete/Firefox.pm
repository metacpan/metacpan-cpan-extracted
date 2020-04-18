package Complete::Firefox;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-18'; # DATE
our $DIST = 'Complete-Firefox'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_firefox_profile_name
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to Firefox',
};

$SPEC{complete_firefox_profile_name} = {
    v => 1.1,
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub complete_firefox_profile_name {
    require Complete::Util;
    require Firefox::Util::Profile;

    my %args = @_;

    my $res = Firefox::Util::Profile::list_firefox_profiles(detail=>1);
    return {message=>"Can't list Firefox profiles: $res->[0] - $res->[1]"}
        unless $res->[0] == 200;

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => [map {$_->{name}} @{ $res->[2] }],
    );
}

1;
# ABSTRACT: Completion routines related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Firefox - Completion routines related to Firefox

=head1 VERSION

This document describes version 0.001 of Complete::Firefox (from Perl distribution Complete-Firefox), released on 2020-04-18.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_firefox_profile_name

Usage:

 complete_firefox_profile_name(%args) -> any

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Firefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
