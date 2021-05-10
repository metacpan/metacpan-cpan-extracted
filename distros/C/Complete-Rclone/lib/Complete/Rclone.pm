package Complete::Rclone;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-09'; # DATE
our $DIST = 'Complete-Rclone'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Rclone::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_rclone_remote
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to rclone',
};

$SPEC{complete_rclone_remote} = {
    v => 1.1,
    summary => 'Complete from a list of configured rclone remote names',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        %Rclone::Util::argspecs_common,
        type => {
            summary => 'Only list remotes of a certain type (e.g. "drive" for Google Drive, "google photos" for Google Photos)',
            schema => 'str*',
            tags => ['category:filtering'],
        },
    },
    result_naked => 1,
};
sub complete_rclone_remote {
    require Complete::Util;
    require Hash::Subset;

    my %args = @_;

    my $res = Rclone::Util::parse_rclone_config(Hash::Subset::hash_subset(\%args, \%Rclone::Util::argspecs_common));
    return {message=>"Can't parse rclone config files: $res->[1]"} unless $res->[0] == 200;
    my $config = $res->[2];

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => [$args{type} ? (grep {$config->{$_}{type} eq $args{type}} sort keys %$config) : (sort keys %$config)],
    );
}

1;
# ABSTRACT: Completion routines related to rclone

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Rclone - Completion routines related to rclone

=head1 VERSION

This document describes version 0.003 of Complete::Rclone (from Perl distribution Complete-Rclone), released on 2021-05-09.

=for Pod::Coverage .+

=head1 FUNCTIONS


=head2 complete_rclone_remote

Usage:

 complete_rclone_remote(%args) -> any

Complete from a list of configured rclone remote names.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<rclone_config_dirs> => I<array[dirname]>

=item * B<rclone_config_filenames> => I<array[filename]>

=item * B<type> => I<str>

Only list remotes of a certain type (e.g. "drive" for Google Drive, "google photos" for Google Photos).

=item * B<word>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Rclone>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Rclone>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Rclone>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

L<https://rclone.org>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
