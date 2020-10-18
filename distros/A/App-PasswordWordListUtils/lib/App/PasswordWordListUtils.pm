package App::PasswordWordListUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-23'; # DATE
our $DIST = 'App-PasswordWordListUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{exists_in_password_wordlist} = {
    v => 1.1,
    summary => 'Check that string(s) match(es) word in a password wordlist',
    description => <<'_',

Password wordlist is one of WordList::* modules, without the prefix.

Since many password wordlist uses bloom filter, that means there's a possibility
of false positive (e.g. 0.1% chance; see each password wordlist for more
details).

_
    args => {
        wordlist => {
            schema => 'perl::wordlist::modname*',
            cmdline_aliases => {w=>{}},
            default => 'Password::10Million::Top1000000',
        },
        strings => {
            schema => ['array*', of=>'str*', min_len=>1],
            'x.name.is_plural' => 1,
            'x.name.singular' => 'string',
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
};
sub exists_in_password_wordlist {
    require WordListUtil::CLI;

    my %args = @_;
    my $strings = $args{strings};

    my $wl = WordListUtil::CLI::instantiate_wordlist($args{wordlist});

    if (@$strings == 1) {
        my $exists = $wl->word_exists($strings->[0]);
        [200, "OK", $exists, {
            'cmdline.exit_code' => $exists ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : "String ".($exists ? "most probably exists" : "DOES NOT EXIST")." in the wordlist",
        }];
    } else {
        my @rows;
        for (@$strings) {
            push @rows, {string=>$_, exists=>$wl->word_exists($_) ? 1:0};
        }
        [200, "OK", \@rows, {'table.fields'=>['string','exists']}];
    }
}

1;
# ABSTRACT: Command-line utilities related to checking string against password wordlists

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PasswordWordListUtils - Command-line utilities related to checking string against password wordlists

=head1 VERSION

This document describes version 0.001 of App::PasswordWordListUtils (from Perl distribution App-PasswordWordListUtils), released on 2020-05-23.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<exists-in-password-wordlist>

=back

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 exists_in_password_wordlist

Usage:

 exists_in_password_wordlist(%args) -> [status, msg, payload, meta]

Check that string(s) match(es) word in a password wordlist.

Password wordlist is one of WordList::* modules, without the prefix.

Since many password wordlist uses bloom filter, that means there's a possibility
of false positive (e.g. 0.1% chance; see each password wordlist for more
details).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<bool>

=item * B<strings>* => I<array[str]>

=item * B<wordlist> => I<perl::wordlist::modname> (default: "Password::10Million::Top1000000")


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PasswordWordListUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PasswordWordListUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PasswordWordListUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<WordList::Password::*> modules, e.g.
L<WordList::Password::10Million::Top1000000>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
