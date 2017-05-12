use AnyEvent;
use Test::More;
use lib -f 'BUILD' ? 'lib' : '../../lib';
use_ok 'AnyEvent::MSN';

#{package AnyEvent::MSN; $DEBUG=$DEBUG=1;}
my $cv = AnyEvent->condvar;
my $to
    = AnyEvent->timer(after => 60, cb => sub { diag 'Timeout!'; $cv->send });
my $msn = AnyEvent::MSN->new(
    passport   => 'anyevent_msn@hotmail.com',
    password   => 'public',
    on_connect => sub {
        my $s = shift;
        pass sprintf 'Connected as %s. Adding self to buddy list...',
            $s->passport;

        #$cv->send;
        $s->add_contact($s->passport);

        # $s->remove_buddy($s->passport);
    },
    on_error => sub {
        my (undef, $msg, $fatal) = @_;
        note ucfirst sprintf '%serror: %s', ($fatal ? 'fatal ' : ''), $msg;
        $cv->send if $fatal;
    },
    on_user_notification => sub {
        my ($s, $bud, $status) = @_;
        return if $bud->{From} !~ $s->passport;
        pass 'I came online!';

        # XXX - Remove self from buddy list, wait to see self go offline
        #$s->remove_contact($s->passport);
        $cv->send;
    }
);
$cv->recv;
done_testing;

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2012 by Sanko Robinson <sanko@cpan.org>

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
