package Sah::Schema::bencher::scenario;

our $DATE = '2020-05-12'; # DATE
our $VERSION = '1.049'; # VERSION

use strict;
use warnings;

our %dh_props = (
    v => {},
    defhash_v => {},
    name => {},
    caption => {},
    summary => {},
    description => {},
    tags => {},
    default_lang => {},
    x => {},
);

our $schema = [hash => {
    # tmp
    _prop => {
        %dh_props,

        participants => {
            _elem_prop => {
                %dh_props,

                type => {},
                module => {},
                function => {},
                code => {},
                code_template => {},
                fcall_template => {},
                cmdline => {}, # str|array[str]
            },
        },
        datasets => {
            _elem_props => {
                %dh_props,

                args => {}, # hash
                argv => {}, # array
            },
        },
        on_failure => {}, # die*, skip
        module_startup => {},
        extra_modules => {},
    },
}, {}];

1;
# ABSTRACT: Bencher scenario

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::bencher::scenario - Bencher scenario

=head1 VERSION

This document describes version 1.049 of Sah::Schema::bencher::scenario (from Perl distribution Bencher-Backend), released on 2020-05-12.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("bencher::scenario*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['bencher::scenario*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
