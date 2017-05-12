package Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRW;

our $DATE = '2016-05-25'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(foo_dzprw);

our %SPEC;

$SPEC{foo_dzprw} = {
    v => 1.1,
    args => {
        a1 => {
            schema => 'int*',
            req => 1,
        },
        a2 => {
            schema => [array => of=>'int*'],
            default => [1],
        },
    },
    'x.perinci.sub.wrapper.disable_validate_args' => 1,
};
 $SPEC{foo_dzprw} = {args=>{a1=>{req=>1, schema=>["int", {req=>1}, {}]}, a2=>{default=>[1], schema=>["array", {of=>"int*"}, {}]}}, args_as=>"hash", v=>1.1, "x.perinci.sub.wrapper.disable_validate_args"=>1, "x.perinci.sub.wrapper.logs"=>[{normalize_schema=>1, validate_args=>0, validate_result=>1}]}; sub foo_dzprw { ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap
    #IFUNBUILT
#     die "Can only be used in built version";
    #END IFUNBUILT

    my %args = @_; my $_w_res = undef;$_w_res = do { ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap
    [200, "OK"];
};      unless (ref($_w_res) eq "ARRAY" && $_w_res->[0]) { return [500, 'BUG: Sub Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRW::foo_dzprw does not produce envelope']; } return $_w_res; } ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap

1;
# ABSTRACT: An example module that uses Rinci::Wrap dzil plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRW - An example module that uses Rinci::Wrap dzil plugin

=head1 VERSION

This document describes version 0.004 of Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateUsingDZPRW (from Perl distribution Bencher-Scenarios-PerinciSubValidateArgs), released on 2016-05-25.

=head1 FUNCTIONS


=head2 foo_dzprw(%args) -> [status, msg, result, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1>* => I<int>

=item * B<a2> => I<array[int]> (default: [1])

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

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubValidateArgs>

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
