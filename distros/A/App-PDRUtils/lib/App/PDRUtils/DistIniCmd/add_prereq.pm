package App::PDRUtils::DistIniCmd::add_prereq;

our $DATE = '2019-07-25'; # DATE
our $VERSION = '0.121'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::PDRUtils::Cmd;
use App::PDRUtils::DistIniCmd;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Add a prereq',
    args => {
        %App::PDRUtils::DistIniCmd::common_args,
        %App::PDRUtils::Cmd::mod_args,
        %App::PDRUtils::Cmd::opt_mod_ver_args,
        phase => {
            summary => 'Select prereq phase',
            schema => ['str*', match=>qr/\A(build|configure|develop|runtime|test|x_\w+)\z/],
            default => 'runtime',
        },
        rel => {
            summary => 'Select prereq relationship',
            schema => ['str*', match=>qr/\A(requires|suggests|recommends|x_\w+)\z/],
            default => 'requires',
        },
        # TODO: replace option
    },
};
sub handle_cmd {
    my %args = @_;

    my $iod   = $args{parsed_dist_ini};
    my $mod   = $args{module};
    my $ver   = $args{module_version} // 0;
    my $phase = $args{phase} // 'runtime';
    my $rel   = $args{rel} // 'requires';

    if (App::PDRUtils::Cmd::_has_prereq($iod, $mod)) {
        return [304, "Already has prereq to '$mod'"];
    }

    my $section;
    for my $s ($iod->list_sections) {
        next unless $s =~ m!\Aprereqs(?:\s*/\s*(\w+))?\z!ix;
        if ($phase eq 'runtime' && $rel eq 'requires') {
            next unless !$1 || lc($1) eq 'runtimerequires';
        } else {
            next unless  $1 && lc($1) eq $phase.$rel;
        }
        $section = $s;
        last;
    }
    unless ($section) {
        if ($phase eq 'runtime' && $rel eq 'requires') {
            $section = 'Prereqs';
        } else {
            $section = 'Prereqs / '.ucfirst($phase).ucfirst($rel);
        }
    }

    my ($modified, $linum);

    if ($phase =~ /\Ax_/ || $rel =~ /\Ax_/) {
        $linum = $iod->insert_key(
            {create_section=>1, ignore=>1}, $section, "-phase", $phase);
        $modified = 1 if defined $linum;
        $linum = $iod->insert_key(
            {create_section=>1, ignore=>1}, $section, "-relationship", $rel);
        $modified = 1 if defined $linum;
    }

    $linum = $iod->insert_key(
        {create_section=>1, ignore=>1}, $section, $mod, $ver);
    $modified = 1 if defined $linum;

    if ($modified) {
        return [200, "Added prereq '$mod=$ver' to section [$section]", $iod];
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

App::PDRUtils::DistIniCmd::add_prereq - Add a prereq

=head1 VERSION

This document describes version 0.121 of App::PDRUtils::DistIniCmd::add_prereq (from Perl distribution App-PDRUtils), released on 2019-07-25.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Add a prereq.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<str>

=item * B<module_version> => I<str> (default: 0)

=item * B<parsed_dist_ini>* => I<obj>

=item * B<phase> => I<str> (default: "runtime")

Select prereq phase.

=item * B<rel> => I<str> (default: "requires")

Select prereq relationship.

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

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
