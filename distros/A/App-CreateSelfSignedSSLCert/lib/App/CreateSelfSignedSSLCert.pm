package App::CreateSelfSignedSSLCert;

our $DATE = '2016-06-09'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

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
        $log->info("Your CSR has been created at $h.csr");
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

    $log->info("Your certificate has been created at $h.pem");

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

App::CreateSelfSignedSSLCert - Create self-signed SSL certificate

=head1 VERSION

This document describes version 0.13 of App::CreateSelfSignedSSLCert (from Perl distribution App-CreateSelfSignedSSLCert), released on 2016-06-09.

=head1 SYNOPSIS

This distribution provides command-line utility called
L<create-self-signed-ssl-cert> and L<create-ssl-csr>.

=head1 FUNCTIONS


=head2 create_self_signed_ssl_cert(%args) -> [status, msg, result, meta]

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

=item * B<interactive> => I<bool> (default: 0)

=item * B<wildcard> => I<bool> (default: 0)

If set to 1 then Common Name is set to *.hostname.

Only when non-interactive

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 create_ssl_csr(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<hostname>* => I<str>

=item * B<interactive> => I<bool> (default: 0)

=item * B<wildcard> => I<bool> (default: 0)

If set to 1 then Common Name is set to *.hostname.

Only when non-interactive

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CreateSelfSignedSSLCert>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CreateSelfSignedSSLCert>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CreateSelfSignedSSLCert>

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
