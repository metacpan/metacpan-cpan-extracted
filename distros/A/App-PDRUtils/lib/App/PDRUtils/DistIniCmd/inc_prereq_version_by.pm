package App::PDRUtils::DistIniCmd::inc_prereq_version_by;

our $DATE = '2016-12-28'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::PDRUtils::Cmd;
use App::PDRUtils::DistIniCmd;
use App::PDRUtils::DistIniCmd::_modify_prereq_version;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Increase prereq version by a certain increment',
    args => {
        %App::PDRUtils::DistIniCmd::common_args,
        %App::PDRUtils::Cmd::mod_args,
        %App::PDRUtils::Cmd::by_ver_args,
    },
};
sub handle_cmd {
    App::PDRUtils::DistIniCmd::_modify_prereq_version::_modify_prereq_version(
        'inc_by', @_);
}

1;
# ABSTRACT: Increase prereq version by a certain increment

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::DistIniCmd::inc_prereq_version_by - Increase prereq version by a certain increment

=head1 VERSION

This document describes version 0.09 of App::PDRUtils::DistIniCmd::inc_prereq_version_by (from Perl distribution App-PDRUtils), released on 2016-12-28.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

Increase prereq version by a certain increment.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by>* => I<str>

=item * B<module>* => I<str>

=item * B<parsed_dist_ini>* => I<obj>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
