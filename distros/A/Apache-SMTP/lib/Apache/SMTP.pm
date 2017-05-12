package Apache::SMTP;

use 5.006001;
use strict;
use warnings FATAL => 'all';

use Apache::Server ();
use Apache::ServerUtil ();
use Apache::Connection ();
use Apache::Const -compile => 'OK';
use Apache::TieBucketBrigade;
use Apache::SMTP::Server;
use Net::SMTP;

our $VERSION = '0.01';

sub handler {
    my $c = shift;
    my $ath = Apache::TieBucketBrigade->new_tie($c);
                                                    
    my $smtp = Apache::SMTP::Server->new(         
        handle_in => $ath,
        handle_out => $ath,
    );
    $smtp->my_config($c);
    $smtp->set_callback(HELO => \&validate_hostname);
    $smtp->set_callback(RCPT => \&validate_recipient);
    $smtp->set_callback(DATA => \&queue_message);
    $smtp->set_callback(MAIL => \&validate_sender);
    $smtp->process;
    Apache::OK;
}

sub validate_hostname {
    my ($session, $hostname) = @_;
    return(1, 250, "ok");
}

sub validate_recipient {
    my ($session, $recipient) = @_;
    return(1, 250, "ok");
}

sub validate_sender {
    my ($session, $sender) = @_;
    return(1, 250, "ok");
}

sub queue_message {
    my($session, $data) = @_;
    my $sender = $session->get_sender();
    my @recipients = $session->get_recipients();
    my $mailhost = $session->get_mailhost();
    my $mailport = $session->get_mailport();
    my $mailip = $session->get_local_ip();
    return(0, 554, 'Error: no valid recipients')
        unless(@recipients);
    my $msgid = add_queue({mailhost => $mailhost,
                           mailport => $mailport,
                           mailip => $mailip,
                           sender => $sender,
                           recipients => \@recipients,
                           data => $$data});
    return(0) unless defined $msgid;
    return(1, 250, "message queued $msgid");
}

sub add_queue {
    my $args = shift;
    my @recipients = @{$args->{recipients}};
    my $smtp;
    foreach (@recipients) {
        return undef unless $smtp = Net::SMTP->new($args->{mailhost},
            Port => $args->{mailport},
            LocalAddr => $args->{mailip},);
        return undef unless $smtp->mail($args->{sender});
        return undef unless $smtp->to($_);
        return undef unless $smtp->data();
        return undef unless $smtp->datasend($args->{data});
        return undef unless $smtp->dataend();
        return undef unless $smtp->quit;
    }
    return (localtime())[0]; # lies that we tell - not a real msgid
}



1;
__END__

=head1 NAME

Apache::SMTP - A simple SMTP server using Apache and mod_perl made simple with
Apache::TieBucketBrigade

=head1 SYNOPSIS

Listen 127.0.0.1:25
<VirtualHost _default_:25>
      PerlSetVar        MailHost        some.smtp.server
      PerlSetVar        MailPort        25
      PerlModule                   Apache::SMTP
      PerlProcessConnectionHandler Apache::SMTP
</VirtualHost>


=head1 DESCRIPTION

This implements a very simple SMTP server using Apache and mod_perl 2.  The
current behavior is to immediately send (using Net::SMTP) any mail it
receives to the server set using 
PerlSetVar MailHost
on 
port PerlSetVar MailPort

Because of the above behavior, this module _may_ act as an ***OPEN RELAY***
which is a bad thing.  So please do not configure it as such.  Instead, 
subclass this module and write your own validate_sender() and 
validate_recipient() methods.  Alternatively, do not have your mail server
allow relaying from this server's ip, and you should be ok.

Also, this module, despite the methods "add_queue" and "queue_message" does
not actually implement a queue in the normal MTA sense of the word.  Maybe
you would like to implement one?

=head2 SUBCLASS

=over 4

You may want to subclass this module and write your own version of the 
following

=item validate_hostname

    sub validate_hostname {
        my ($session, $hostname) = @_;
        return(1, 250, "ok");
    }

=item validate_sender

    sub validate_sender {
        my ($session, $sender) = @_;
        return(1, 250, "ok");
    }


=item validate_recipient

    sub validate_recipient {
        my ($session, $recipient) = @_;
        return(1, 250, "ok");
    }

=item queue_message

    sub queue_message {
        my($session, $data) = @_;
        my $msgid = add_queue({mailhost => 'hostname',
                           mailport => '25',
                           mailip => '127.0.0.1',
                           sender => 'foo@example.com',
                           recipients => \('bar@example.com'),
                           data => $$data});
        return(1, 250, "message queued $msgid");
    }


=item add_queue

    my $msgid = add_queue({mailhost => 'hostname',
                           mailport => '25',          
                           mailip => '127.0.0.1',
                           sender => 'foo@example.com',
                           recipients => \('bar@example.com'),
                           data => 'somestuff'});      

=head1 SEE ALSO

Apache::SMTP::Server
Apache::TieBucketBrigade
Net::Server::Mail::SMTP
Net::SMTP
mod_perl 2

=head1 AUTHOR

mock, E<lt>mock@obscurity.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Will Whittaker and Ken Simpson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
