package App::instopt;

our $DATE = '2018-09-13'; # DATE
our $VERSION = '0.000'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::swcat ();
use PerlX::Maybe;

use vars '%Config';
our %SPEC;

our %args_common = (
    archive_dir => {
        schema => 'dirname*',
        tags => ['common'],
    },
    arch => {
        schema => 'software::arch*',
        tags => ['common'],
    },
);

our %arg_arch = (
    arch => {
        schema => ['software::arch*'],
    },
);

sub _load_swcat_mod {
    my $name = shift;

    (my $mod = "Software::Catalog::SW::$name") =~ s/-/::/g;
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;
    $mod;
}

sub _set_args_default {
    my $args = shift;
    if (!$args->{arch}) {
        $args->{arch} = App::swcat::_detect_arch();
    }
}

sub _init {
    my ($args) = @_;

    unless ($App::instopt::state) {
        _set_args_default($args);
        my $state = {
        };
        $App::instopt::state = $state;
    }
    $App::instopt::state;
}

$SPEC{list_installed} = {
    v => 1.1,
    summary => 'List all installed software',
    args => {
        %args_common,
    },
};
sub list_installed {
    [501, "Not yet implemented"];
}

$SPEC{list_downloaded} = {
    v => 1.1,
    summary => 'List all downloaded software',
    args => {
        %args_common,
        %App::swcat::arg0_software,
        detail => {
            schema => ['bool*', is=>1],
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_downloaded {
    [501, "Not yet implemented"];
}

$SPEC{download} = {
    v => 1.1,
    summary => 'Download latest version of software',
    args => {
        %args_common,
        %App::swcat::arg0_software,
    },
};
sub download {
    my %args = @_;
    my $state = _init(\%args);

    return [501, "Not yet implemented"];
    #my $mod = _load_swcat_mod($args{software});
    #$mod->get_download_url(
    #    maybe arch => $args{arch},
    #);
}

$SPEC{update} = {
    v => 1.1,
    summary => 'Update a software to latest version',
    args => {
        %args_common,
        %App::swcat::arg0_software,
    },
};
sub update {
    my %args = @_;
    my $state = _init(\%args);

    return [501, "Not yet implemented"];
}

$SPEC{update_all} = {
    v => 1.1,
    summary => 'Update all installed software',
    args => {
        %args_common,
    },
};
sub update_all {
    my %args = @_;
    my $state = _init(\%args);

    return [501, "Not yet implemented"];
}

1;
# ABSTRACT: Download and install software

__END__

=pod

=encoding UTF-8

=head1 NAME

App::instopt - Download and install software

=head1 VERSION

This document describes version 0.000 of App::instopt (from Perl distribution App-instopt), released on 2018-09-13.

=head1 SYNOPSIS

See L<instopt> script.

=head1 FUNCTIONS


=head2 download

Usage:

 download(%args) -> [status, msg, result, meta]

Download latest version of software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<archive_dir> => I<dirname>

=item * B<software>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_downloaded

Usage:

 list_downloaded(%args) -> [status, msg, result, meta]

List all downloaded software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<archive_dir> => I<dirname>

=item * B<detail> => I<bool>

=item * B<software>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_installed

Usage:

 list_installed(%args) -> [status, msg, result, meta]

List all installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<archive_dir> => I<dirname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update

Usage:

 update(%args) -> [status, msg, result, meta]

Update a software to latest version.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<archive_dir> => I<dirname>

=item * B<software>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update_all

Usage:

 update_all(%args) -> [status, msg, result, meta]

Update all installed software.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<arch> => I<software::arch>

=item * B<archive_dir> => I<dirname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-instopt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-instopt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-instopt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
