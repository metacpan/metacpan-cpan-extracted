#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-channel.t 32 2017-11-22 16:05:22Z abalama $
#
#########################################################################
use feature qw/say/;
use utf8;
use Test::More tests => 21;
use lib qw(inc);
use FakeCTK;
use IO::File;
use App::MonM::Notifier::Util;
use App::MonM::Notifier::Const;
use App::MonM::Notifier::Channel;

# Test data
my $data = {
        id      => 1,
        to      => "anonymous",
        from    => "root",
        subject => "Test message",
        message => "Content of the test message",
    };

# Create channel object
my $channel = new App::MonM::Notifier::Channel(
        timeout => 15,
    );

is($channel->channels("DeFaUlT"), "default", "Check channels(default)");
ok(scalar($channel->channels) > 2, "Check channels list");

# Check default (SCALAR)
{
    my $testname = "Check default (SCALAR)";
    my $ret;
    if ($channel->send( default => $data, {io => \$ret} )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    ok($ret && length($ret) && $ret =~ /^MIME/m, "Return pool (as scalar)");
}

# Check default (IO::File)
{
    my $testname = "Check default (IO::File)";
    my $fn = "03-channel.tmp";
    my $fh = IO::File->new();
    $fh->open("> $fn");
    if ($channel->send( default => $data, {io => $fh} )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    $fh->close;
    ok((-e $fn and -s $fn > 100), "Return pool (as file)");
    unlink $fn if -e $fn;
}

# Check file
{
    my $testname = "Check file";
    my $fn = "03-channel.tmp";

    if ($channel->send( file => $data, {
        signature => 1,
        dir => '.',
        filemask => $fn,
        encoding => 'base64', # For Email::MIME testing
    } )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    ok((-e $fn and -s $fn > 100), "Result file");
    unlink $fn if -e $fn;
}

# Check file via AUTOLOAD
{
    my $testname = "Check file via AUTOLOAD";
    my $fn = "03-channel.tmp";

    if ($channel->file($data, {
        dir => '.',
        filemask => $fn,
    } )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    ok((-e $fn and -s $fn > 100), "Result file");
    unlink $fn if -e $fn;
}

# Check file via AUTOLOAD #2
{
    my $testname = "Check file via file() method";
    my $fn = "03-channel.tmp";

    if ($channel->file($data, {
        dir => '.',
        filemask => $fn,
    } )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    ok((-e $fn and -s $fn > 100), "Result file");
    unlink $fn if -e $fn;
}

# Email parser
{
    my $testname = "Email parser";
    my $ret;

    local $data->{message} = "Foo"; # Rm9v
    local $data->{headers} = {
            "X-Mailer" => "monotifier/1.00",
            #"bcc"      => "***\@***",
            #"to"       => "***\@***",
            "X-Id"     => $data->{id},
        };

    if ($channel->default( $data, {io => \$ret, encoding => "base64"} )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    ok($ret && length($ret) && $ret =~ /^MIME/m, "Return pool (before parsing)");

    #print $ret,"\n";
    my $parsed = Email::MIME->new($ret);
    my %headers = $parsed->header_str_pairs;
    #print Dumper(\%headers);

    $headers{message} = $parsed->body_str;
    $headers{message_raw} = $parsed->body_raw;
    $headers{message} //= '';
    is(trim($headers{message}), $data->{message}, "Message consistency");
    $headers{message_raw} //= '';
    is(trim($headers{message_raw}), "Rm9v", "RAW Message consistency");
    $headers{"X-Id"} //= 0;
    is($headers{"X-Id"}, $data->{id}, "X-ID consistency");
}

# No output (no return value, but {email} property is set)
{
    my $testname = "No output";
    if ($channel->default( $data, {encoding => "base64"} )) {
        pass($testname);
    } else {
        fail($testname);
        diag($channel->error);
    }
    my $email = $channel->{email};
    ok($email && $email->isa("Email::MIME"), "Email::MIME object");
    #print Dumper($email);
}

# Renew class
{
    my $got = $channel->channels("email");
    is($got, "email", "Renew class (before)");
    $channel = new App::MonM::Notifier::Channel;
    $got = $channel->channels("email");
    is($got, "email", "Renew class (after)");
}

1;
