#!/usr/bin/perl
package App::ipchgmon;

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use DateTime;
use DateTime::Format::Strptime;
use Data::Dumper;
use Data::Validate::Email qw(is_email);
use Data::Validate::IP;
use Email::Sender::Transport::SMTP;
use Email::Stuffer;
use LWP::Online 'online';
use LWP::UserAgent;
use Socket qw(:addrinfo SOCK_RAW);
use Text::CSV qw(csv);
use feature 'say';
our $VERSION = '1.0.7';

my $TIMEFORMAT = '%FT%T%z';
my $strp = DateTime::Format::Strptime->new(on_error => 'croak',
                                           pattern  => $TIMEFORMAT,
                                          );

our ($opt_help, $opt_man, $opt_versions,
     $opt_debug, $opt_singleemail, $opt_4, $opt_6,
     $opt_email, $opt_file, $opt_mailserver, $opt_mailport, $opt_leeway,
     $opt_mailfrom, $opt_mailsubject, $opt_server, $opt_dnsname,
);

GetOptions(
    'help!'           => \$opt_help,
    'man!'            => \$opt_man,
    'versions!'       => \$opt_versions,
  
    'debug!'          => \$opt_debug,
    'singleemail!'    => \$opt_singleemail,
    '4!'              => \$opt_4,
    '6!'              => \$opt_6,
  
    'email|mailto=s@' => \$opt_email,
    'file=s'          => \$opt_file,
    'server=s'        => \$opt_server,
    'mailserver=s'    => \$opt_mailserver,
    'mailport=i'      => \$opt_mailport,
    'leeway=i'        => \$opt_leeway,
    'mailfrom=s'      => \$opt_mailfrom,
    'mailsubject=s'   => \$opt_mailsubject,
    'dnsname=s'       => \$opt_dnsname,
) or pod2usage(-verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if defined $opt_help;
pod2usage(-verbose => 2) && exit if defined $opt_man;

unless (caller()) {
    if (!defined $opt_file and !$opt_debug) {
        pod2usage(-verbose => 1);
        exit;
    }
    if (!defined $opt_server and !$opt_debug) {
        pod2usage(-verbose => 1);
        exit;
    }
    main();
}

sub main {
    dump_options()       if $opt_debug;
    validate_email()     if defined $opt_email and scalar @$opt_email;
    validate_transport() if defined $opt_mailport or defined $opt_mailserver;
    $opt_4 ||= 0;
    $opt_6 ||= 0;
    unless (online) {
        $opt_mailsubject = "Internet connection lost for $opt_server";
        send_email($opt_server, 'No internet connection');
        exit;
    }
    my $aoaref;
    $aoaref = read_file() if -e $opt_file;
    my $ip4 = get_ip4();
    check_changes($ip4, $aoaref) if $ip4 and ($opt_4 or !$opt_6);
    my $ip6 = get_ip6();
    check_changes($ip6, $aoaref) if $ip6 and ($opt_6 or !$opt_4);
    $aoaref = read_file();
    check_dns($opt_dnsname, $aoaref) if $opt_dnsname;
    exit;
}

sub check_dns {
    my ($dnsname, $aoaref) = @_;
    my ($ip4, $ip6) = nslookup($dnsname);
    my @list;
    if ($opt_4 == $opt_6) {
        push @list, $ip4, $ip6;
    } elsif ($opt_4) {
        push @list, $ip4;
    } else {
        push @list, $ip6;
    }
    for my $ip (@list) {
        my ($latest, $overdue) = last_ip($ip, $aoaref);
        if (!$latest or $overdue) {
            send_email($ip, "$dnsname has moved to $ip")
                if defined $opt_email and scalar @$opt_email;
        }
    }
}

sub check_changes {
    my ($ip, $aoaref) = @_;
    my ($latest, $overdue) = last_ip($ip, $aoaref);
    new_ip($ip) if !$latest;
}

# Returns two booleans. The first indicates whether the IP address passed in
# is the latest of its type in the AoA. The second indicates whether the leeway
# has passed.
sub last_ip {
    my ($ip, $aoaref) = @_;
    return 0, 0 unless defined $aoaref;
    my $v4 = valid4($ip);
    my ($lastip, $lasttime);
    for my $line (reverse @$aoaref) {
        if ((valid4($$line[0]) and  $v4)
        or  (valid6($$line[0]) and !$v4)) {
            $lastip   = $$line[0];
            $lasttime = $strp->parse_datetime($$line[1]);
            last;
        }
    }
    if ($lastip eq $ip) {
        # This is the latest IP address of its type
        $opt_leeway //= 0;
        my $dt = DateTime->now;
        my $overdue = $dt->epoch > ($lasttime->epoch + $opt_leeway);
        return 1, $overdue;
    } else {
        return 0, 0;
    }
}

sub new_ip {
    my ($ip) = @_;
    open my $fh, '>>:encoding(utf8)', $opt_file 
        or die "Unable to append to $opt_file: $!";
    my $dt = DateTime->now;
    my $timestamp = $dt->rfc3339;
    my $csv = Text::CSV->new();
    my @fields = ($ip, $timestamp);
    $csv->say($fh, \@fields);
    close $fh or die "Unable to close $opt_file: $!";
    send_email($ip) if defined $opt_email and scalar @$opt_email;
}

sub read_file {
    return csv (in => $opt_file);
}

sub dump_options {
    no warnings 'uninitialized';
    say "Help:         >$opt_help<";
    say "Man:          >$opt_man<";
    say "Versions:     >$opt_versions<";
    say "Single email: >$opt_singleemail<";
    say "4:            >$opt_4<";
    say "6:            >$opt_6<";
    say "File:         >$opt_file<";
    say "Server:       >$opt_server<";
    say "DNS name:     >$opt_dnsname<";
    say "Mail Server:  >$opt_mailserver<";
    say "Mail Port:    >$opt_mailport<";
    say "Mail From:    >$opt_mailfrom<";
    say "Mail Subject: >$opt_mailsubject<";
    say "Leeway:       >$opt_leeway<";
    print "Email addresses: ";
    print Dumper $opt_email;
    use warnings 'uninitialized';
}

sub validate_email {
    for my $address (@$opt_email) {
        die "Invalid email address: $address" unless is_email($address);
    }
}

sub validate_transport {
    die "Invalid option combination - mailport is $opt_mailport but mailserver is unspecified" 
        if defined $opt_mailport and !defined $opt_mailserver;
}

sub build_transport {
    $opt_mailport ||= 25;
    my $transport = Email::Sender::Transport::SMTP->new({
        host => $opt_mailserver,
        port => $opt_mailport,
    });
    return $transport;
}

sub send_email {
    my ($ip, $body) = @_;
    my $transport;
    $transport = build_transport if defined $opt_mailserver;
    $opt_server ||= '';
    $opt_mailsubject ||= $opt_server . ' has a new address';
    $body ||= "$opt_server is now at $ip";
    my %params;
    $params{'from'} = $opt_mailfrom;
    $params{'subject'} = $opt_mailsubject;
    $params{'text_body'} = $body;
    $params{'transport'} = $transport if defined $transport;
    if ($opt_singleemail or 1 == scalar(@$opt_email)) {
        for my $address (@$opt_email) {
            $params{'to'} = $address;
            my $stuffer = Email::Stuffer->new(\%params);
            $stuffer->send;
        }
    } else {
        $params{'to'} = $opt_email;
        my $stuffer = Email::Stuffer->new(\%params);
        $stuffer->send;
    }
}

sub valid4 {
    my $ip = shift;
    return 0 if is_unroutable_ipv4($ip);
    return 0 if is_private_ipv4($ip);
    return 0 if is_loopback_ipv4($ip);
    return 0 if is_linklocal_ipv4($ip);
    return 0 if is_testnet_ipv4($ip);
    return 0 if is_anycast_ipv4($ip);
    return 0 if is_multicast_ipv4($ip);
    return 1 if is_ipv4($ip);
}

sub valid6 {
    my $ip = shift;
    return 0 if is_private_ipv6($ip);
    return 0 if is_loopback_ipv6($ip);
    return 0 if is_linklocal_ipv6($ip);
    return 0 if is_multicast_ipv6($ip);
    return 0 if is_ipv4_mapped_ipv6($ip);
    return 0 if is_discard_ipv6($ip);
    return 0 if is_special_ipv6($ip);
    return 0 if is_documentation_ipv6($ip);
    return 1 if is_ipv6($ip);
}

sub get_ip6 {
    return get_ip('http://ip6only.me/api/');
}

sub get_ip4 {
    return get_ip('http://ip4only.me/api/');
}

sub get_ip {
    my $url = shift;
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    my $csv = $res->content;
    my $aoa = csv(in => \$csv);
    return $$aoa[0][1];
}

sub nslookup {
    my $hostname = shift;
    my ($err, $v1, $v2) = getaddrinfo($hostname, "", { socktype => SOCK_RAW });
    my (undef, $ip1) = getnameinfo($v1->{addr}, NI_NUMERICHOST, NIx_NOSERV);
    my (undef, $ip2) = getnameinfo($v2->{addr}, NI_NUMERICHOST, NIx_NOSERV);
    if (valid4($ip1)) {
        return $ip1, $ip2;
    } else {
        return $ip2, $ip1;
    }
}

END {
    if(defined $opt_versions){
        print
            "\nModules, Perl, OS, Program info:\n",
            "  Getopt::Long                   $Getopt::Long::VERSION\n",
            "  Pod::Usage                     $Pod::Usage::VERSION\n",
            "  Data::Dumper                   $Data::Dumper::VERSION\n",
            "  Data::Validate::Email          $Data::Validate::Email::VERSION\n",
            "  Data::Validate::IP             $Data::Validate::IP::VERSION\n",
            "  DateTime                       $DateTime::VERSION\n",
            "  DateTime::Format::Strptime     $DateTime::Format::Strptime::VERSION\n",
            "  Email::Sender::Transport::SMTP $Email::Sender::Transport::SMTP::VERSION\n",
            "  Email::Stuffer                 $Email::Stuffer::VERSION\n",
            "  LWP::Online                    $LWP::Online::VERSION\n",
            "  LWP::UserAgent                 $LWP::UserAgent::VERSION\n",
            "  Socket                         $Socket::VERSION\n",
            "  Text::CSV                      $Text::CSV::VERSION\n",
            "  strict                         $strict::VERSION\n",
            "  Perl                           $]\n",
            "  OS                             $^O\n",
            "  $0                    $VERSION\n",
            "\n\n";
    }
}

1;

=pod

=head1 NAME

ipchgmon.pm - Watches for changes to public facing IP addresses

=head1 SYNOPSIS

    perl ipchgmon.pm --file c:\data\log.txt --server example.com

Who knows? It might even work. More usually, in a cron job:

    perl ipchgmon --file ~/log.txt \
                  --server back_office_top_shelf \
                  --dnsname example.com \
                  --leeway 86400 \
                  --email serverchange@example.com \
                  --mailserver 192.168.0.2 \
                  --mailfrom ipchgmon@example.com \
                  --mailsubject 'Change of IP address'

=head1 BACKGROUND

I and friends run email and other servers at home. I pay for a static IP
address with the clause in my contract that force majeur may require a
change. Others are on dynamic addresses. Should the public facing address
change, we want to know. This modulino is intended to monitor the public
IP address and shout for help should the address change. One friend is
looking at code to change public DNS records automatically.

=head1 DESCRIPTION

This modulino is intended to be run automatically as a cron job. It should
check whether the server running it has changed its IP address. If so, 
messages should be sent to those specified.

Either IPv4 or IPv6 or both formats can be tested. It might well be that
different servers handle the different types.

There are three issues that may be checked. The first is connectivity. If
there is no connectivity, messages should be sent. No further issues will be
tested.

The second issue that will be tested is whether the IP address has changed.
The current public-facing IP address is established via internet use and
compared to a log file, specified by the "--file" option. If it is not the
last entry in the log, messages will be sent.

Finally and optionally, the DNS name of the server will be used to get 
another IP address from global DNS. If this is not the last address in the
log file, messages will be send unless a leeway has been specified and this 
has not expired.

If connectivity is lost, the number of retries and the wait will both be
options in a later version. At present, or if the retries all fail, someone 
should be sent a message.

The design includes three forms of message, SMS, HTTP and email. It is 
reasonable to send an email if internet connectivity is lost; the server 
may be internal. SMS may be harder to justify. HTTP must depend on the 
location of the server.

There is currently no facility to send different classes of message to
different addresses. There is nothing inherently impossible about writing
code to do this if it proves desirable.

If the IP address has changed, messages should be sent without delay or retries.

=head1 ON ARGUMENTS AND OPTIONS

These are processed by Getopt::Long. This means that shorter versions may
be used. If the first letter of an argument or option is unique, the call
may be reduced to a single minus sign and the first letter. So the "email"
argument has an alias, "mailto". But the alias must be specified as
"--mailt" at least, while "email" can be reduced to "-e".

=head1 ARGUMENTS

    --file filename THIS OPTION IS COMPULSORY unless --debug is used.
                    The file "filename" will be created if it does not exist.
                    It may be preferable to use a fully qualified filename.
                    Attempting to write to a non-existent directory or without
                    the necessary permissions will cause an error. The file is
                    plain text containing the IPv4 and IPv6 addresses of the server.
    --server name   THIS OPTION IS COMPULSORY unless --debug is used.
                    It is the name that will be used to identify the machine
                    should internet connectivity be lost or the IP address
                    change. It is not used internally and should not be
                    confused with the dnsname.
    --dnsname name  The name of the server in global DNS.
    --leeway time   This option specifies how many seconds should elapse from
                    an IP address changing on DNS to a second email being sent.
                    It is used only in conjunction with dnsname. If dnsname
                    is unspecified, the value of this option is meaningless.
                    It isn't compulsory, but without it, messages will be sent
                    every time the modulino finds the IP address is not the
                    same as returned by DNS. This is fine if you like getting
                    up every hour during the night. Otherwise, use something
                    like 86400 (one day).
    --email address Multiple instances of this option are acceptable. An email
                    will be sent to each, if possible.
    --mailto        Synonym for --email.
    --mailserver    Must be followed by the name or ip address of the outbound
                    server. Some systems may have a default for this.
    --mailport      Must be numeric. Will default to 25 if omitted.
    --mailfrom      Most servers will insist on this, but some systems may
                    have a default.
    --mailsubject   Can be omitted if desired. A default would be created
                    which would be different for each message type. Subjects
                    that include spaces would need quoting. The quote character
                    can be OS dependent.

=head1 OPTIONS

    --help          Brief manual
    --man           Full manual
    --versions      Code info
    --debug         Debugging information
    --singleemail   Sends one email at a time. Prevents multiple email 
                    addresses appearing in each email and prevents server
                    confusion if different mechanisms are used for different
                    destinations. Yes, it can happen.
    --4             Check IPv4 addresses. Both will be checked if neither
                    or both options are used.
    --6             Check IPv6 addresses. Both will be checked if neither
                    or both options are used.

=head1 TO DO

=over

* Implement SMS messages

* Implement HTTP messages

* implement config file

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by John Davies

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CREDITS

https://www.perlmonks.org/?node_id=155288 for the getopt/usage model.

Fergus McMenemie for the talk on modulinos (https://www.youtube.com/watch?v=wCW4tpMgdHs).

Corion (https://www.perlmonks.org/?node=Corion) for solving a naming blunder of mine.

Slaven Rezic of the CPAN testers for taking the trouble to raise an issue that was causing lots of tester reports and suggesting a solution I would never have found alone.

Pryrt (https://www.perlmonks.org/?node=pryrt) for spotting that I was ignoring the real cause of the problem Slaven had reported.

Hv (https://www.perlmonks.org/?node=hv) for patiently, despite my stupidity, showing me how to emulate the testers' issue on my local machine.

