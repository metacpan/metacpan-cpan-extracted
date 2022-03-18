#!/usr/bin/perl

use strict;
use warnings;

use API::MailboxOrg;
use Data::Printer;

my $api = API::MailboxOrg->new(
    user     => 'test@example.tld',
    password => 'a_password',
);

my $result = $api->videochat->list( mail => 'test@example.tld' );

p $result;

