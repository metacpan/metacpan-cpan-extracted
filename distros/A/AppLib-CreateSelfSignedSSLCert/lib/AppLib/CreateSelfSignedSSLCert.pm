package AppLib::CreateSelfSignedSSLCert;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-05'; # DATE
our $DIST = 'AppLib-CreateSelfSignedSSLCert'; # DIST
our $VERSION = '0.152'; # VERSION

use Expect;
#use File::chdir;
#use File::Temp;
use IPC::System::Options 'system', -log=>1;
use Proc::ChildError qw(explain_child_error);
use String::ShellQuote;

sub _sq { shell_quote($_[0]) }

our %SPEC;

$SPEC{create_self_signed_ssl_cert} = {
    v => 1.1,
    summary => 'Create self-signed SSL certificate',
    args => {
        hostname => {
            schema => ['str*' => match => qr/\A\w+(\.\w+)*\z/],
            req => 1,
            pos => 0,
        },
        ca => {
            summary => 'path to CA cert file',
            schema => ['str*'],
            'x.completion' => [filename => {file_regex_filter=>qr/\.(crt|pem)$/}],
        },
        ca_key => {
            summary => 'path to CA key file',
            schema => ['str*'],
            'x.completion' => [filename => {file_regex_filter=>qr/\.(key|pem)$/}],
        },
        interactive => {
            schema => [bool => default => 0],
            cmdline_aliases => {
                i => {},
            },
        },
        wildcard => {
            schema => [bool => default => 0],
            summary => 'If set to 1 then Common Name is set to *.hostname',
            description => 'Only when non-interactive',
        },
        csr_only => {
            schema => [bool => default => 0],
            summary => 'If set to 1 then will only generate .csr file',
            description => <<'_',

Can be useful if want to create .csr and submit it to a CA.

_
        },
    },
    deps => {
        exec => 'openssl',
    },
};
sub create_self_signed_ssl_cert {
    my %args = @_;

    my $h = $args{hostname};

    system("openssl genrsa 2048 > "._sq("$h.key"));
    return [500, "Can't generate key: ".explain_child_error()] if $?;
    chmod 0400, "$h.key" or warn "WARN: Can't chmod 400 $h.key: $!";

    my $cmd = "openssl req -new -key "._sq("$h.key")." -out "._sq("$h.csr");
    if ($args{interactive}) {
        system $cmd;
        return [500, "Can't generate csr: ".explain_child_error()] if $?;
    } else {
        my $exp = Expect->spawn($cmd);
        return [500, "Can't spawn openssl req"] unless $exp;
        $exp->expect(
            30,
            [ qr!^.+\[[^\]]*\]:!m ,=> sub {
                  my $exp = shift;
                  my $prompt = $exp->exp_match;
                  if ($prompt =~ /common name/i) {
                      $exp->send(($args{wildcard} ? "*." : "") . "$h\n");
                  } else {
                      $exp->send("\n");
                  }
                  exp_continue;
              } ],
        );
        $exp->soft_close;
    }
    if ($args{csr_only}) {
        log_info("Your CSR has been created at $h.csr");
        return [200];
    }

    # we can provide options later, but for now let's
    system(join(
        "",
        "openssl x509 -req -days 3650 -in ", _sq("$h.csr"),
        " -signkey ", _sq("$h.key"),
        ($args{ca} ? " -CA "._sq($args{ca}) : ""),
        ($args{ca_key} ? " -CAkey "._sq($args{ca_key}) : ""),
        ($args{ca} ? " -CAcreateserial" : ""),
        " -out ", _sq("$h.crt"),
    ));
    return [500, "Can't generate crt: ".explain_child_error()] if $?;

    system("openssl x509 -noout -fingerprint -text < "._sq("$h.crt").
               "> "._sq("$h.info"));
    return [500, "Can't generate info: ".explain_child_error()] if $?;

    system("cat "._sq("$h.crt")." "._sq("$h.key")." > "._sq("$h.pem"));
    return [500, "Can't generate pem: ".explain_child_error()] if $?;

    system("chmod 400 "._sq("$h.pem"));

    log_info("Your certificate has been created at $h.pem");

    [200];
}

$SPEC{create_ssl_csr} = {
    v => 1.1,
    args => {
        hostname => {
            schema => ['str*' => match => qr/\A\w+(\.\w+)*\z/],
            req => 1,
            pos => 0,
        },
        interactive => {
            schema => [bool => default => 0],
            cmdline_aliases => {
                i => {},
            },
        },
        wildcard => {
            schema => [bool => default => 0],
            summary => 'If set to 1 then Common Name is set to *.hostname',
            description => 'Only when non-interactive',
        },
    },
    deps => {
        # XXX should've depended on create_self_signed_ssl_cert() func instead,
        # and dependencies should be checked recursively.
        exec => 'openssl',
    },
};
sub create_ssl_csr {
    my %args = @_;
    create_self_signed_ssl_cert(%args, csr_only=>1);
}

1;
# ABSTRACT: Create self-signed SSL certificate

__END__

=pod

=encoding UTF-8

=head1 NAME

AppLib::CreateSelfSignedSSLCert - Create self-signed SSL certificate

=head1 VERSION

This document describes version 0.152 of AppLib::CreateSelfSignedSSLCert (from Perl distribution AppLib-CreateSelfSignedSSLCert), released on 2023-06-05.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 create_self_signed_ssl_cert

Usage:

 create_self_signed_ssl_cert(%args) -> [$status_code, $reason, $payload, \%result_meta]

Create self-signed SSL certificate.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ca> => I<str>

path to CA cert file.

=item * B<ca_key> => I<str>

path to CA key file.

=item * B<csr_only> => I<bool> (default: 0)

If set to 1 then will only generate .csr file.

Can be useful if want to create .csr and submit it to a CA.

=item * B<hostname>* => I<str>

(No description)

=item * B<interactive> => I<bool> (default: 0)

(No description)

=item * B<wildcard> => I<bool> (default: 0)

If set to 1 then Common Name is set to *.hostname.

Only when non-interactive


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 create_ssl_csr

Usage:

 create_ssl_csr(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<hostname>* => I<str>

(No description)

=item * B<interactive> => I<bool> (default: 0)

(No description)

=item * B<wildcard> => I<bool> (default: 0)

If set to 1 then Common Name is set to *.hostname.

Only when non-interactive


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppLib-CreateSelfSignedSSLCert>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppLib-CreateSelfSignedSSLCert>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppLib-CreateSelfSignedSSLCert>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
