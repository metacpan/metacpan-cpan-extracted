#!/usr/bin/env perl

package Daemon::Whois;
use warnings;
use strict;
use base qw(Net::Server);
use CDB_File;


=head1 NAME

Daemon::Whois - A WHOIS daemon

=head1 VERSION

Version 1.11

=cut

our $VERSION = '1.11';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Daemon::Whois;

    my $foo = Daemon::Whois->new();
    ...

=head1 VARIABLES

$database - The location of the database
$log_file - The location of the log file
$no_db    - The error message when there is no database
$copyright- The footnote
$no_domain_found - Another error condition
$string_replace  - Improving the error message 
$user     - The user that the daemon runs as
$group    - The group the daemon runs as
$proto    - You don't want to change this
$port     - Not a WHOIS server if it is not port 43
$template - A suggested layout

=cut

$|=1;
my %opt; #options
$opt{D}=0; #debug level
my $database = '/var/lib/whois/whois.cdb';
my $log_file = '/var/log/whois.log';
my $no_db =qq |The database is being updated, please try again later\n(You could poke the sysadmin if this has been down for too long, but please be gentel)\n|;
my $copyright =qq |This is meant to be informative and give an approximate guide... and nothing more.|;
my $no_domain_found =qq |That domain is not found|;
my $string_replace =qq |That domain|;       #if we think that we have a domain we can s/// using this string
my $user = 'whois';
my $group= 'whois';
my $proto= 'tcp';
my $port = 43;
my $template = '
    Domain name:
        DOMAIN

    Registrant:
        <private>

    Registrant type:
        UK Individual

    Registrant\'s address:
        The registrant is a non-trading individual who has opted to have their
        address omitted from the WHOIS service.

    Registrar:
        That would be registry.alexx.net
        URL: http://registry.alexx.net

    Relevant dates:
        Registered on: 06-Jun-2XXX (Why does that matter?)
        Renewal date:  06-Jun-2XXX (Private)
        Last updated:  30-Jul-2XXX (None of your bees wax)

    Registration status:
        Registered until renewal date.

    Name servers:
        ns0.not.telling.you
        ns1.do.i.look.like.a.dns.server.2.you
        ns2.did.not.think.so

    WHOIS rebuilt NOW';

my $original_template =qq |
Domain name: DOMAIN
Registrant : REGISTRANT
Contact    : {
        CONTACT
}
Dates: {
        Registered on: REGISTERED
        Renewal date:  RENEWAL
        Last updated:  UPDATE
}
Status     : STATUS
Name servers: {
        NS
}

WHOIS  lookup  made at QUERY_DATE
WHOIS database rebuilt DB_DATE

--
COPYRIGHT
|;

=head1 METHOD

    If called with a file location that includes the database name this 
script will build an example database. (In the original version _build
accessed the database using Notice::DB Config::Auto DBIx::Class to 
collect the data and CDB_File to build the whois.cdb file.)

=cut

if($ARGV[0]){
    if($database=~m/$ARGV[0]/){ 
        &_build($ARGV[0]); 
    }else{ print "This is not a valid output for the database\n Try perldoc Daemon::Whois"; }
   exit;
}


=head1 SERVER

The server is called if invoked without any arguments.
The log output is disabled just to pass the make test; Once you create
the logfile with the user:group specified above, you can enable it.

=cut

my $daemon = Daemon::Whois->new({
    user    => $user,
    group   => $group,
    proto   => $proto,
    port    => $port,
    background=>1,
    # log_file=> $log_file,
});

$daemon->run;

=head1 process_request

The real meat of the server

=cut

sub process_request {
    my $self = shift;
    eval {
        local $SIG{'ALRM'} = sub { die "Timed Out!\n" };
        my $timeout = 30; # give the user 30 seconds to type some lines
        my $previous_alarm = alarm($timeout);
        warn ("HERE: $previous_alarm") if $opt{"D"}>=2;
        while (my $query = <STDIN>) {
                last if $query =~ /^\s$/;
                chomp $query;
        my $domain = $query;
        $domain=~s/\s.*//;
        $domain=~s/[^\w\.-]//;
         if(-f "$database"){
            tie my %whoisdb, 'CDB_File', $database or die "can't open $database: $!\n";
            warn "tieing to $database" if $opt{D}>=2;
            my $now = `date +%Y%m%d%H%M%S`; chomp($now);
            if ($whoisdb{$domain}){
                my $reply = $whoisdb{$domain};
                $reply=~s/\$now/$now/;
                $reply=~s/QUERY_DATE/$now/;
                print $reply . "\n";
                print STDERR "$domain is known\n" if $opt{D}>=1;  #ths is a log message
            }else{
                if('bandwidth to burn' eq 'yes'){
                    my $reply = $no_domain_found;
                    $reply=~s/$string_replace/$domain/;
                    print $reply . "\nQuery recieved: $now\n";
                }else{
                    print "No\n";
                }
                # NOTE probably need a rate-limiter to prevent a DDoS filling up the logs.
                print STDERR "$now $domain is not known here \n" if $opt{D}>=1;
            }
            last;
            warn ("THERE: $timeout");
         }else{
            print $no_db;
            print STDERR "DB ERROR: $database is not a file\n";
            last;
         }
         alarm($timeout);
        }
        alarm($previous_alarm);
        if ($@=~m/timed out/i) { print STDERR "DIED Out.\n"; print STDERR "We have zero bananas today\n"; return; }
    };
    if ($@=~m/timed out/i) { print STDERR "Timed Out.\n"; print STDERR "We have no bananas today\n"; return; }
    elsif ($@) { print STDERR "NB: $@.\n"; return; }
    else{ print STDERR "end of process\n" if $opt{D}>=2; }
}



=head1 SUBROUTINES/METHODS

=head2 _build

This will build an example database.

=cut

sub _build {
    use DateTime;
    my $t = new CDB_File ($ARGV[0], "t.$$") or die "can't create file $ARGV[0]";
    my @domains = ('test.example.com','this.example.com','example.com','alexx.net');
    foreach my $d (@domains){
        my $v = $template;
        if($v=~s/DOMAIN/$d/){
            my $now = DateTime->now();
            $v=~s/NOW/$now/;
            $t->insert($d,$v);
        }
    }
    $t->finish;
#    rename("t.$$",$database);

}

=head1 AUTHOR

Alexx Roche, C<< <notice-dev at alexx.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-daemon-whois at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Daemon-Whois>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Daemon::Whois


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Daemon-Whois>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Daemon-Whois>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Daemon-Whois>

=item * Search CPAN

L<http://search.cpan.org/dist/Daemon-Whois/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Alexx Roche

This program is free software; you can redistribute it and/or modify it
under the Eclipse Public License, Version 1.0

See http://www.opensource.org/licenses/ for more information.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of Daemon::Whois
