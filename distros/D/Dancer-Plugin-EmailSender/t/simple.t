#!/usr/bin/perl

use strict;
use warnings;
use Dancer qw{:tests};
use Dancer::Plugin::EmailSender;
use Email::Simple;
use Email::Sender::Transport::Test;
use IO::File;
use Test::Fatal;
use Test::More import => ['!pass'];
use t::Util qw{body_is envelope_is header_is with_sent};

my $transport = Email::Sender::Transport::Test->new;

setting plugins => {EmailSender => {headers => {'X-Foo' => 'Bar'},
                                    transport => $transport}};

like (exception {sendemail}, qr/^You must pass me information on what to send/, 'Test for failure with no arguments');
like (exception {sendemail ''}, qr/^You must pass me a hashref to describe the email/, 'Test for failure with wrong type of arguments');
like (exception {sendemail {}}, qr/^You must tell me who the email is from/, 'Test for failure with missing from');
like (exception {sendemail {from => 'mdorman@ironicdesign.com'}}, qr/^You must tell me to whom to send the email/, 'Test for failure with missing to');
like (exception {sendemail {'envelope-from' => 'mdorman@ironicdesign.com'}}, qr/^You must tell me to whom to send the email/, 'Test for failure with missing to');

ok (sendemail ({from => 'mdorman@ironicdesign.com', to => ['mdorman@ironicdesign.com']}), 'Test sending with a null body');

with_sent $transport, sub {
    my ($sent) = @_;
    envelope_is $sent, 'from', 'mdorman@ironicdesign.com';
    envelope_is $sent, 'to', ['mdorman@ironicdesign.com'];
    my $email = $sent->{email};
    body_is $email, '';
    header_is $email, 'x-foo', 'Bar';
    header_is $email, 'from', 'mdorman@ironicdesign.com';
    header_is $email, 'to', 'mdorman@ironicdesign.com';
};
ok (sendemail ({from => 'mdorman@ironicdesign.com', to => ['mdorman@ironicdesign.com'], body => 'This is a trivial body.', headers => {'X-Foo' => 'Baz'}}), 'Test sending with a body');

with_sent $transport, sub {
    my ($sent) = @_;
    envelope_is $sent, 'from', 'mdorman@ironicdesign.com';
    envelope_is $sent, 'to', ['mdorman@ironicdesign.com'];
    my $email = $sent->{email};
    body_is $email, 'This is a trivial body.';
    header_is $email, 'x-foo', 'Baz';
    header_is $email, 'from', 'mdorman@ironicdesign.com';
    header_is $email, 'to', 'mdorman@ironicdesign.com';
};

ok (sendemail ({'envelope-from' => 'adorman@ironicdesign.com', from => 'mdorman@ironicdesign.com', to => ['cdorman@ironicdesign.com'], body => 'This is a trivial body.'}), 'Test sending with an envelope-from');

with_sent $transport, sub {
    my ($sent) = @_;
    envelope_is $sent, 'from', 'adorman@ironicdesign.com';
    envelope_is $sent, 'to', ['cdorman@ironicdesign.com'];
    my $email = $sent->{email};
    body_is $email, 'This is a trivial body.';
    header_is $email, 'x-foo', 'Bar';
    header_is $email, 'from', 'mdorman@ironicdesign.com';
    header_is $email, 'to', 'cdorman@ironicdesign.com';
};

my $email = Email::Simple->create (header => [
                                              From => 'jdorman@ironicdesign.com',
                                              To => 'sergey@google.com',
                                              Subject => 'Message in a bottle'],
                                   body => '...');

ok (sendemail ({email => $email, 'envelope-to' => 'mdorman@ironicdesign.com'}), 'Test sending an already constructed email');

with_sent $transport, sub {
    my ($sent) = @_;
    envelope_is $sent, 'from', 'jdorman@ironicdesign.com';
    envelope_is $sent, 'to', ['mdorman@ironicdesign.com'];
    my $email = $sent->{email};
    body_is $email, "...\r\n";
    header_is $email, 'x-foo', '';
    header_is $email, 'from', 'jdorman@ironicdesign.com';
    header_is $email, 'to', 'sergey@google.com';
};

my ($output);
my $fh = IO::File->new (\$output, '>');
ok (sendemail ({'envelope-from' => 'adorman@ironicdesign.com', from => 'mdorman@ironicdesign.com', to => ['cdorman@ironicdesign.com'], body => 'This is a trivial body.', transport => {class => 'Print', fh => $fh}}), 'Test sending with alternate transport');
ok ($output, 'Make sure there was some output');
ok (!with_sent ($transport, sub {}), 'Make sure the last email ran through Print transport');

done_testing;
