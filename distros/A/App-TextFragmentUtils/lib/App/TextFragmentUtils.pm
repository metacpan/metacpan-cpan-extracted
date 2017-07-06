package App::TextFragmentUtils;

our $DATE = '2016-10-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Clone;
use File::Slurper qw(read_text);
use Text::Fragment ();

our %SPEC;

my $filename_arg = {
    schema => 'filename*',
    req => 1,
    pos => 0,
    cmdline_aliases => {f=>{}},
};

sub _get_tf_args {
    my %args = @_;

    my %tf_args = %args;
    my $filename = delete $tf_args{filename};
    my $text;
    if ($filename eq '-') {
        local $/;
        $text = <STDIN>;
    } else {
        $text = read_text($filename);
    }
    $tf_args{text} = $text;
    \%tf_args;
}

$SPEC{list_fragments} = do {
    my $meta = clone $Text::Fragment::SPEC{list_fragments};
    delete $meta->{args}{text};
    $meta->{args}{filename} = $filename_arg,
    $meta;
};
sub list_fragments {
    my %args = @_;

    my $tf_args = _get_tf_args(%args);
    Text::Fragment::list_fragments(%$tf_args);
}

$SPEC{get_fragment} = do {
    my $meta = clone $Text::Fragment::SPEC{get_fragment};
    delete $meta->{args}{text};
    $meta->{args}{filename} = $filename_arg,
    $meta;
};
sub get_fragment {
    my %args = @_;

    my $tf_args = _get_tf_args(%args);
    Text::Fragment::get_fragment(%$tf_args);
}

1;
# ABSTRACT: CLI utilities related to Text::Fragment

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TextFragmentUtils - CLI utilities related to Text::Fragment

=head1 VERSION

This document describes version 0.001 of App::TextFragmentUtils (from Perl distribution App-TextFragmentUtils), released on 2016-10-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
text fragment:

=over

=item * L<get-fragment>

=item * L<list-fragments>

=back

=head1 FUNCTIONS


=head2 get_fragment(%args) -> [status, msg, result, meta]

Get fragment with a certain ID in text.

If there are multiple occurences of the fragment with the same ID ,

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<comment_style> => I<str> (default: "shell")

Comment style.

=item * B<filename>* => I<filename>

=item * B<id>* => I<str>

Fragment ID.

=item * B<label> => I<str> (default: "FRAGMENT")

Comment label.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: Fragment (array)


Will return status 200 if fragment is found. Result will be a hash with the
following keys: C<raw> (string), C<payload> (string), C<attrs> (hash), C<id>
(string, can also be found in attributes).

Return 404 if fragment is not found.


=head2 list_fragments(%args) -> [status, msg, result, meta]

List fragments in text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<comment_style> => I<str> (default: "shell")

Comment style.

=item * B<filename>* => I<filename>

=item * B<label> => I<str> (default: "FRAGMENT")

Comment label.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: List of fragments (array)


Will return status 200 if operation is successful. Result will be an array of
fragments, where each fragment is a hash containing these keys: C<raw> (string),
C<payload> (string), C<attrs> (hash), C<id> (string, can also be found in
attributes).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TextFragmentUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TextFragmentUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TextFragmentUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Fragment>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
