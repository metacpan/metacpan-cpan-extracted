package App::FindUtils;

our $DATE = '2019-09-18'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{find_duplicate_filenames} = {
    v => 1.1,
    summary => 'Search directories recursively and find files/dirs with duplicate names',
    args => {
        dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'dir',
            schema => ['array*', of=>'dirname*'],
            default => ['.'],
            pos => 0,
            slurpy => 1,
        },
        #case_insensitive => {
        #    schema => 'bool*',
        #    cmdline_aliases=>{i=>{}},
        #},
        detail => {
            summary => 'Instead of just listing duplicate names, return all the location of duplicates',
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub find_duplicate_filenames {
    require Cwd;
    require File::Find;

    my %args = @_;
    $args{dirs} //= ["."];
    #my $ci = $args{case_insensitive};

    my %files; # filename => {realpath1=>orig_filename, ...}. if hash has >1 keys than it's duplicate
    File::Find::find(
        sub {
            no warnings 'once'; # for $File::find::dir
            # XXX inefficient
            my $realpath = Cwd::realpath($_);
            $files{$_}{$realpath}++;
        },
        @{ $args{dirs} }
    );

    my @res;
    for my $file (sort keys %files) {
        next unless keys(%{$files{$file}}) > 1;
        if ($args{detail}) {
            for my $path (sort keys %{$files{$file}}) {
                push @res, {name=>$file, path=>$path};
            }
        } else {
            push @res, $file;
        }
    }
    [200, "OK", \@res];
}

1;
# ABSTRACT: Utilities related to finding files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FindUtils - Utilities related to finding files

=head1 VERSION

This document describes version 0.002 of App::FindUtils (from Perl distribution App-FindUtils), released on 2019-09-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<find-duplicate-filenames>

=back

=head1 FUNCTIONS


=head2 find_duplicate_filenames

Usage:

 find_duplicate_filenames(%args) -> [status, msg, payload, meta]

Search directories recursively and find files/dirs with duplicate names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Instead of just listing duplicate names, return all the location of duplicates.

=item * B<dirs> => I<array[dirname]> (default: ["."])

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FindUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FindUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FindUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
