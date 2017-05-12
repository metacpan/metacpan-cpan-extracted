package Acme::SDUM::Renew;

use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::Form;
use File::Temp qw/tempfile/;
use Mail::Sender;
use Carp;

=head1 NAME

Acme::SDUM::Renew - Renew your books from www.sdum.uminho.pt

=head1 VERSION

Version 0.02

=cut

our $VERSION  = '0.02';
our (@ISA)    = qw/Exporter/;
our (@EXPORT) = qw/sdum_renew/;

=head1 SYNOPSIS

This module just exports one function wich is responsible 
of renew all your books from SDUM. At the end a report
is sent to an email, so you can manually check (yes, manually!)
if the operation suceeded.

    use Acme::SDUM::Renew;

    sdum_renew($username, $password, $email, $smtp);

=head1 EXPORT

sdum_renew

=head1 FUNCTIONS

=head2 sdum_renew

This is where the magic happens. This function receives the
following parameters:

=over 4

=item username

Username to SDUM (don't forget to prepend a 'A' in case you are a student like me).

=item password

Your super ultra secret password.

=item email

A valid email address to send the report.

=item smtp [optional]

This argument is optional but should be usefull when Mail::Sender defaults
doesn't suit your network configuration. Just pass here the SMTP where
your email are relayed and everything should go smoothly.

=back

=cut

sub sdum_renew {
    my ($username, $password, $email, $smtp) = @_;

    croak "Username required" unless $username;
    croak "Password required" unless $password;
    croak "Notification email required" unless $email;
    # smtp is optional

    my $browser = LWP::UserAgent->new(
        requests_redirectable => ['GET', 'HEAD', 'POST']
    );
    $browser->cookie_jar( {} );
    $browser->env_proxy;
    
    # Fase 1: Get the session
    my $res = $browser->get('http://aleph.sdum.uminho.pt/');
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 1)\n";
    
    $res->content =~ /Math\.rand/ or die "Content not expected (Phase 1)\n";
    
    # Fase 2: Generate the random session
    my $session = int(rand() * 1000000000);
    $res = $browser->get('http://aleph.sdum.uminho.pt/F?RN=' . $session);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 2)\n";
    
    $res->content =~ /top\.location/ or die "Content not expected (Phase 2)\n";
    $res->content =~ /\'(http[^\']+)\'/;
    
    # Fase 3: Get main page
    $res = $browser->get($1);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 3)\n";
    
    $res->content =~ /href\=\"([^\"]+login-session)\"/
    or die "Content not expected (Phase 4)\n";
    
    # Fase 4: Get login form
    $res = $browser->get($1);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 4)\n";
    
    my @forms = HTML::Form->parse($res);
    my $form = shift @forms;
    
    $form->value('bor_id', $username);
    $form->value('bor_verification', $password);
    
    $res = $browser->request($form->click);
    $res->is_success or die "Error submiting login form (Phase 4)\n";
    
    # Fase 5: Get Area Pessoal Link
    $res->content =~ /rea Pessoal/ or die "Content not expected (check username/password) (Phase 5)\n";
    
    $res->content =~ /href\=\"([^\"]+bor\-info)\"/
    or die "Can't find Area Pessoal Link (Phase 5)\n";
    
    $res = $browser->get($1);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 5)\n";
    
    # Fase 6: Get Empréstimos Link
    $res->content =~ /Irregularidades/ or die "Content not expected (Phase 6)\n";
    
    $res->content =~ /href\=\"([^\"]+bor\-loan)\"/
    or die "Can't find Empréstimos Link (Phase 6)\n";
    
    $res = $browser->get($1);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 6)\n";
    
    # Fase 7: Renew
    $res->content =~ /Desc Exemplar/ or die "Content not expected (Phase 7)\n";
    
    $res->content =~ /href\=\"([^\"]+bor\-renew\-all)\"/
    or die "Can't find Renovar Todos Link (Phase 7)\n";
    
    $res = $browser->get($1);
    $res->is_success or die "Error reading from aleph.sdum.uminho.pt (Phase 7)\n";
    
    my ($tempfh, $tempfile) = tempfile();
    print $tempfh $res->content;
    close $tempfh;
    
    # Send to email
    my $sender = new Mail::Sender { 
        smtp => $smtp,
        from => 'robot@futurama.net'
    };
    $sender->MailFile({
        to => $email,
        subject => 'SDUM Renew Results',
        msg => 'Please check the results',
        file => $tempfile,
        ctype => 'text/html',
    });

    croak $Mail::Sender::Error if $Mail::Sender::Error;
}

=head1 AUTHOR

Ruben Fonseca, C<< <root at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-sdum-renew at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-SDUM-Renew>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::SDUM::Renew

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-SDUM-Renew>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-SDUM-Renew>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-SDUM-Renew>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-SDUM-Renew>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ruben Fonseca, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::SDUM::Renew
