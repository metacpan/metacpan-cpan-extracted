package App::PDRUtils::DistIniCmd::remove_prereq;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.122'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::PDRUtils::Cmd;
use App::PDRUtils::DistIniCmd;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Add a prereq',
    args => {
        %App::PDRUtils::DistIniCmd::common_args,
        %App::PDRUtils::Cmd::mod_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $iod   = $args{parsed_dist_ini};
    my $mod   = $args{module};

    my @sections = grep {
        $_ =~ m!\APrereqs(?:\s*/\s*\w+)?\z!
    } $iod->list_sections;

    my $modified;
    for my $section (@sections) {
        my $num_deleted = $iod->delete_key({all=>1}, $section, $mod);
        $modified++ if $num_deleted;
    }

    if ($modified) {
        return [200, "Removed prereq '$mod'", $iod];
    } else {
        return [304, "Not modified"];
    }
}

1;
# ABSTRACT: Add a prereq

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::DistIniCmd::remove_prereq - Add a prereq

=head1 VERSION

This document describes version 0.122 of App::PDRUtils::DistIniCmd::remove_prereq (from Perl distribution App-PDRUtils), released on 2021-05-25.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add a prereq.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<str>

=item * B<parsed_dist_ini>* => I<obj>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
