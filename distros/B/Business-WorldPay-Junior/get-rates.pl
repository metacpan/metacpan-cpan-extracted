#!/usr/bin/perl -w
#
# Copyright 2002, Jason Clifford <jason@jasonclifford.com>
# License: GPL v.2 - See COPYING file for details.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    A copy of the GNU General Public License is in the accompanying
#    COPYING file.
# 
# This script grabs the next days currency rates from WorldPay for a given
# account and updates the wprates table with them. It is needed for the 
# Business::OnlinePayment::WorldPay::Junior module.
#
# Note that the rates are not available until 18:00 hrs (GMT/BST).
# Set up a crontab to run this script at some point between 18:00 and
# 23:59.
# 
use LWP::UserAgent;
use DBI;

my $wpinst = '';	# Insert your WorldPay Install ID here.
my $host="localhost";	# MySQL database host
my $database= '';	# Database name
my $user= '';		# MySQL user
my $password='';	# MySQL password


my $ua = LWP::UserAgent->new();

my $rates_url = 'https://select.worldpay.com/wcc/info?op=rates-tomorrow&instId=' . $wpinst;

my $ret = $ua->get($rates_url);

if ( ! $ret )
    {
    die "Could not get URL\n";
    }
else
    {
    die "Query failed\n" if $ret->{'_msg'} ne "OK";
    my @r = split(/\n/, $ret->{'_content'});
    my %data = ();
    foreach ( @r )
        {
        next if $_ !~ /=/;
        my ($k, $v) = split /=/;
        $data{$k} = $v;
        }
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($data{rateDateMillis}/1000);
    $mon += 1;
    $year += 1900;
    my $date = $year . '-' . $mon . '-' . $mday;

    my $dbh = &db_connect;
    die "Unable to connect to database" if ! $dbh;
    
    my $error = undef;
    
    foreach (keys %data)
        {
        next if /^(allRatesCurrent|rateDateMillis|rateDateString)$/;
        if ( /^([A-Z]{3})_([A-Z]{3})$/ )
            {
            $base = $1;
            $cur = $2;
            next if $base eq $cur;
            my $sql = sprintf "insert into wprates (date, base, cur, rate) values (%s, %s, %s, %s)", $dbh->quote($date), $dbh->quote($base), $dbh->quote($cur), $dbh->quote($data{$_});
            print $sql . "\n";
            eval ( $dbh->do($sql) );
            if ( $@ )
                {
                $error .= "Failed to complete insert SQL query: $sql \n";
                }
            }
        }
    $dbh->disconnect;
    print $error if $error;
    }

sub db_connect
    {
    # Defines for connection to database backend
    my $driver = "mysql";

    my $dsn ="DBI:$driver:database=$database;host=$host";

    my $dbh = DBI->connect($dsn, $user, $password)
              || die "Cannot connect to database Error: $!";
    return $dbh;

    }
    