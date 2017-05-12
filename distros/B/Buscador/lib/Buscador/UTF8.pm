package Buscador::UTF8;


package Email::Store::Mail;
use strict;

sub body {
    my $mail = shift;
    my $mime = Email::MIME->new($mail->message);
       
    my $body = $mime->body;
    my $charset = $mime->{ct}->{attributes}{charset};
    if ($charset and $charset !~ /utf-?8/i) {
        eval {
            require Encode;
            $body = Encode::decode($charset, $body);
            Encode::_utf8_off($body);
        };
    }
    $body;
}

1;

=head1 NAME

Buscador::UTF8 - Buscador plugin to encode the body of a message to UTF8

=head1 DESCRIPTION

This plugin provides a C<body> method to B<Email::Store::Mail>
that returns a UTF-8 encoded body text.

=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut


