package App::ExtractDate;

our $DATE = '2016-04-06'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our $DATE_EXTRACT_MODULE = $ENV{PERL_DATE_EXTRACT_MODULE} // "Date::Extract";

$SPEC{extract_date} = {
    v => 1.1,
    summary => 'Extract date from lines of text',
    args => {
        input => {
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_files',
            #stream => 1,
        },
        module => {
            summary => 'Date::Extract module to use',
            schema => 'str*',
            cmdline_aliases => {m=>{}},
        },
    },
};
sub extract_date {
    my %args = @_;

    my $module = $args{module} // $DATE_EXTRACT_MODULE;
    $module = "Date::Extract::$module" unless $module =~ /::/;
    die "Invalid module '$module'" unless $module =~ /\A\w+(::\w+)*\z/;
    eval "use $module"; die if $@;
    my $parser = $module->new;

    my $res = [];
    for my $line (@{$args{input}}) {
        chomp $line;
        my $dt = $parser->extract($line);
        push @$res, [$line, $dt ? "$dt" : undef];
    }

    [200, "OK", $res, {'table.fields' => ['orig', 'date']}];
}

1;
# ABSTRACT: Extract date from lines of text

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ExtractDate - Extract date from lines of text

=head1 VERSION

This document describes version 0.002 of App::ExtractDate (from Perl distribution App-ExtractDate), released on 2016-04-06.

=head1 SYNOPSIS

 % ls | extract-date

 % ls | extract-date -m ID   ;# use Date::Extract::ID

=head1 FUNCTIONS


=head2 extract_date(%args) -> [status, msg, result, meta]

Extract date from lines of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input>* => I<array[str]>

=item * B<module> => I<str>

Date::Extract module to use.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 PERL_DATE_EXTRACT_MODULE => str

Set default for C<module>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ExtractDate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ExtractDate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ExtractDate>

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
