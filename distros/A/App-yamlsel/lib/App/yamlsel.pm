package App::yamlsel;

our $DATE = '2016-09-01'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(refaddr);

our %SPEC;

sub _encode_yaml {
    require YAML::XS;
    YAML::XS::Dump($_[0]);
}

sub _decode_yaml {
    require YAML::XS;
    YAML::XS::Load($_[0]);
}

$SPEC{yamlsel} = {
    v => 1.1,
    summary => 'Select YAML elements using CSel (CSS-selector-like) syntax',
    args => {
        %App::CSelUtils::foosel_common_args,
        %App::CSelUtils::foosel_struct_action_args,
    },
};
sub yamlsel {
    my %args = @_;

    my $expr = $args{expr};
    my $actions = $args{actions};

    # parse first so we can bail early on error without having to read the input
    require Data::CSel;
    Data::CSel::parse_csel($expr)
          or return [400, "Invalid CSel expression '$expr'"];

    my $data;
    if ($args{file} eq '-') {
        binmode STDIN, ":utf8";
        $data = _decode_yaml(join "", <>);
    } else {
        require File::Slurper;
        $data = _decode_yaml(File::Slurper::read_text($args{file}));
    }

    require Data::CSel::WrapStruct;
    my $tree = Data::CSel::WrapStruct::wrap_struct($data);

    my @matches = Data::CSel::csel(
        {class_prefixes=>['Data::CSel::WrapStruct']}, $expr, $tree);

    # skip root node itself to avoid duplication
    @matches = grep { refaddr($_) ne refaddr($tree) } @matches
        unless @matches <= 1;

    for my $action (@$actions) {
        if ($action eq 'print') {
            $action = 'print_func_or_meth:meth:value.func:App::yamlsel::_encode_yaml',
        }
    }

    App::CSelUtils::do_actions_on_nodes(
        nodes   => \@matches,
        actions => $args{actions},
    );
}

1;
# ABSTRACT: Select YAML elements using CSel (CSS-selector-like) syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::yamlsel - Select YAML elements using CSel (CSS-selector-like) syntax

=head1 VERSION

This document describes version 0.003 of App::yamlsel (from Perl distribution App-yamlsel), released on 2016-09-01.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 yamlsel(%args) -> [status, msg, result, meta]

Select YAML elements using CSel (CSS-selector-like) syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<actions> => I<array[str]> (default: ["print"])

Specify action(s) to perform on matching nodes.

=item * B<expr>* => I<str>

=item * B<file> => I<str> (default: "-")

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

Please visit the project's homepage at L<https://metacpan.org/release/App-yamlsel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-yamlsel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-yamlsel>

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
