package App::lcpan::Cmd::dist_meta;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Get distribution metadata',
    args => {
        %App::lcpan::dist_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my ($dist_id, $cpanid, $file_name, $file_id, $has_metajson, $has_metayml) = $dbh->selectrow_array(
        "SELECT d.id, d.cpanid, f.name, f.id, f.has_metajson, f.has_metayml FROM dist d JOIN file f ON d.file_id=f.id WHERE d.is_latest AND d.name=?", {}, $args{dist});
    $dist_id or return [404, "No such dist '$args{dist}'"];
    $has_metajson || $has_metayml or return [412, "Dist does not have metadata"];

    my $path = App::lcpan::_fullpath($file_name, $state->{cpan}, $cpanid);
    my $la_res = App::lcpan::_list_archive_members($path, $file_name, $file_id);
    return [500, "Can't read archive $path: $la_res->[1]"] unless $la_res->[0] == 200;

    my $gm_res = App::lcpan::_get_meta($la_res);
    return [500, "Can't extract distmeta from $path: $gm_res->[1]"] unless $gm_res->[0] == 200;
    $gm_res;
}

1;
# ABSTRACT: Get distribution metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::dist_meta - Get distribution metadata

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::dist_meta (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Get distribution metadata.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dist>* => I<perl::distname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
