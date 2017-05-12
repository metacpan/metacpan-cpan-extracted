#!/usr/bin/perl -I../lib
use AnyEvent;
use AnyEvent::MSN;
use 5.012;
$|++;
$AnyEvent::MSN::DEBUG++;
my ($user, $pass) = @ARGV;    # XXX - Better to use a GetOpt-like module
my $cv = AnyEvent->condvar;
($user, $pass) = ('anyevent_msn@hotmail.com', 'public');
($user, $pass) = ('msn@penilecolada.com',     'password');
my $reconnect_timer;

#
my $msn = AnyEvent::MSN->new(
    passport => $user,  # XXX - I may change the name of this arg before pause
    password => $pass,

    # Extra user info
    status          => 'AWY',
    friendlyname    => 'Just another MSN hacker,',
    personalmessage => 'This can\'t be life!',

    # Basic events
    on_connect => sub {
        my $msn = shift;
        warn 'Connected as ' . $msn->passport;

        $msn->add_contact('msn@propernoun.com');
        $msn->send_message('msn@propernoun.com', 'Hi?');
    },
    on_im => sub {    # simple echo bot
        my ($msn, $head, $body) = @_;
        $msn->send_message($head->{From}, $body, $head->{'X-MMS-IM-Format'});
        given ($body) {
            when (/^status (...)$/) {
                use Try::Tiny;
                try { $msn->set_status($1) } catch { warn $_ };
            }
            when (/^add (.+)$/) {
                warn 'Adding ' . $1;
                $msn->add_contact($1);
            }
            when (/^remove (.+)$/) {
                warn 'Removing ' . $1;
                $msn->remove_contact($1);
            }
            when (/^circle (.+)$/) {
                $msn->create_group_chat;

=fdas
PUT 35 260
Routing: 1.0
From: 1:testmsnpsharp@live.cn;epid={ad9d9247-9181-4c57-8388-248304e153d3}
To: 10:00000000-0000-0000-0000-000000000000@live.com

Reliability: 1.0

Publication: 1.0
Content-Length: 0
Content-Type: application/multiparty+xml
Uri: /circle
=cut

            }
        }
    },
    on_nudge => sub {
        my ($msn, $head) = @_;
        warn $head->{From} . ' just nudged us';
        $msn->nudge($head->{From});
    },
    on_create_circle=>sub{

        warn 'NEW CIRCLE!!!!!';
    },
    on_error => sub {
        my ($msn, $msg) = @_;
        warn 'Error: ' . $msg;
    },
    on_fatal_error => sub {
        my ($msn, $msg, $fatal) = @_;
        warn sprintf 'Fatal error: ' . $msg;
        $reconnect_timer = AE::timer 30, 0, sub {
            return $msn->connect if $msn->connected;
            $cv->send;
            }
    }
);
$cv->wait;

# SOAP stuff: http://telepathy.freedesktop.org/wiki/Pymsn/MSNP/ContactListActions
# http://imfreedom.org/wiki/MSN
# http://msnpiki.msnfanatic.com/index.php/MSNP13:Contact_Membership

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with Microsoft.

=cut
