package AnyEvent::SMTP;

use AnyEvent;
use common::sense;
use 5.008008;
m{# trying to cheat with cpants game ;)
use strict;
use warnings;
}x;

sub import {
	my $me = shift;
	my $pkg = caller;
	@_ or return;
	for (@_) {
		if ( $_ eq 'sendmail') {
			require AnyEvent::SMTP::Client;
			*{$pkg.'::'.$_} = \&AnyEvent::SMTP::Client::sendmail;
		}
		elsif ( $_ eq 'smtp_server') {
			require AnyEvent::SMTP::Server;
			*{$pkg.'::'.$_} = \&AnyEvent::SMTP::Server::smtp_server;
		}
		else {
			require Carp; Carp::croak "$_ is not exported by $me";
		}
	}
}

=head1 NAME

AnyEvent::SMTP - SMTP client and server

=cut

our $VERSION = '0.10';


=head1 SYNOPSIS

    use AnyEvent::SMTP 'sendmail';
    
    sendmail
        from => 'mons@cpan.org',
        to   => 'mons@cpan.org', # SMTP host will be detected from addres by MX record
        data => 'Test message '.time().' '.$$,
        cb   => sub {
            if (my $ok = shift) {
                warn "Successfully sent";
            }
            if (my $err = shift) {
                warn "Failed to send: $err";
            }
        }
    ;

    use AnyEvent::SMTP 'smtp_server';

    smtp_server undef, 2525, sub {
        my $mail = shift;
        warn "Received mail from $mail->{from} to $mail->{to}\n$mail->{data}\n";
    };


=head1 EXPORT

By default doesn't export anything. When requested, uses Client or Server exports.

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::SMTP
