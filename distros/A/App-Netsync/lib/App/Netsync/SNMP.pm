package App::Netsync::SNMP;

=head1 NAME

App::Netsync::SNMP - SNMP framework

=head1 DESCRIPTION

This package contains functions for handling SNMP communications.

=head1 SYNOPSIS

 use App::Netsync::SNMP;

 App::Netsync::SNMP::configure({
     'SecName'   => 'your username here',
     'SecLevel'  => 'AuthPriv',
     'AuthProto' => 'SHA',
     'AuthPass'  => 'your password here',
     'PrivProto' => 'AES',
     'PrivPass'  => 'your key here',
 },[
     'IF-MIB','ENTITY-MIB',  # standard
     'CISCO-STACK-MIB',      # Cisco
     'FOUNDRY-SN-AGENT-MIB', # Brocade
     'SEMI-MIB',             # HP
 ]);

 my $ip      = '93.184.216.119';
 my $session = App::Netsync::SNMP::Session $ip;

 my $info1   = App::Netsync::SNMP::Info $ip;
 my $info2   = App::Netsync::SNMP::Info $session;

 my ($ifNames,$ifIIDs) = App::Netsync::SNMP::get1 ([
     ['.1.3.6.1.2.1.31.1.1.1.1' => 'ifName'],
     ['.1.3.6.1.2.1.2.2.1.2'    => 'ifDescr'],
 ],$session);

 App::Netsync::SNMP::set ('ifAlias',$_,'Vote for Pedro',$session) foreach @$ifIIDs;

=cut


use 5.006;
use strict;
use warnings FATAL => 'all';
use autodie; #XXX Is autodie adequate?

use File::Basename;
use Scalar::Util 'blessed';
use SNMP;
use SNMP::Info;
use version;

our ($SCRIPT,$VERSION);
our %config;

BEGIN {
    ($SCRIPT)  = fileparse ($0,"\.[^.]*");
    ($VERSION) = version->declare('v4.0.0');
}

INIT {
    $config{'AuthPass'}        = undef;
    $config{'AuthProto'}       = 'MD5';
    $config{'Community'}       = 'public';
    $config{'Context'}         = undef;
    $config{'ContextEngineId'} = undef;
    $config{'DestHost'}        = undef;
    $config{'PrivPass'}        = undef;
    $config{'PrivProto'}       = 'DES';
    $config{'RemotePort'}      = 161;
    $config{'Retries'}         = 5;
    $config{'RetryNoSuch'}     = 0;
    $config{'SecEngineId'}     = undef;
    $config{'SecLevel'}        = 'noAuthNoPriv';
    $config{'SecName'}         = 'initial';
    $config{'Timeout'}         = 1000000;
    $config{'Version'}         = 3;

    $config{'MIBdir'}          = '/usr/share/'.$SCRIPT.'/mib';
    SNMP::addMibDirs($config{'MIBdir'});
}


=head1 METHODS

=head2 configure

configure the operating environment

B<Arguments>

I<( \%environment , \@MIBs )>

=over 3

=item environment

key-value pairs of environment configurations

B<Available Environment Settings>

=over 4

=item MIBdir

the location of necessary MIBs

default: F</usr/share/E<lt>script nameE<gt>/mib>

=back

See SNMP::Session documentation for more acceptable settings.

=item MIBs

a list of MIBs to load

=back

=cut

sub configure {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($environment,$MIBs) = @_;

    $config{$_} = $environment->{$_} foreach keys %$environment;

    my $success = 1;
    foreach my $MIB (@$MIBs) {
        if (defined $MIB) {
            $success = 0 unless defined SNMP::loadModules($MIB);
        }
    }
    SNMP::initMib();

    $config{'ContextEngineId'} //= $config{'SecEngineId'};
    unless (($config{'Version'} < 3) or
            ($config{'SecLevel'} eq 'noAuthNoPriv') or
            ($config{'SecLevel'} eq 'authNoPriv' and defined $config{'AuthPass'}) or
            (defined $config{'AuthPass'} and defined $config{'PrivPass'})) {
        warn 'SNMPv3 configuration is inadequate.';
        $success = 0;
    }
    return $success;
}


=head2 Session

returns an SNMP::Session object.

I<Note: configure needs to be run first!>

B<Arguments>

I<( $ip )>

=over 3

=item ip

an IP address to connect to

=back

=cut

sub Session {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 1;
    my ($ip) = @_;

    return SNMP::Session->new(
        'AuthPass'        => $config{'AuthPass'},
        'AuthProto'       => $config{'AuthProto'},
        'Community'       => $config{'Community'},
        'Context'         => $config{'Context'},
        'ContextEngineId' => $config{'ContextEngineId'},
        'DestHost'        => $ip,
        'PrivPass'        => $config{'PrivPass'},
        'PrivProto'       => $config{'PrivProto'},
        'RemotePort'      => $config{'RemotePort'},
        'Retries'         => $config{'Retries'},
        'RetryNoSuch'     => $config{'RetryNoSuch'},
        'SecEngineId'     => $config{'SecEngineId'},
        'SecLevel'        => $config{'SecLevel'},
        'SecName'         => $config{'SecName'},
        'Timeout'         => $config{'Timeout'},
        'Version'         => $config{'Version'},
    );
}


=head2 Info

returns an SNMP::Info object

I<Note: configure needs to be run first!>

B<Arguments>

I<( $ip )>

=over 3

=item ip

an IP address to connect to OR an SNMP::Session

=back

I<Note: The following snippets are equivalent:>

=over 3

=item C<App::Netsync::SNMP::Info $ip;>

=item C<App::Netsync::SNMP::Info App::Netsync::SNMP::Session $ip;>

=back

=cut

sub Info {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 1;
    my ($ip) = @_;

    my $session = Session $ip;
    my $info = SNMP::Info->new(
        'AutoSpecify' => 1,
        'Session'     => $session,
    );
    return ($session,$info);
}


=head2 get1

attempt to retrieve an OID from a provided list, stopping on success

B<Arguments>

I<( \@OIDs , $ip )>

=over 3

=item OIDs

a prioritized list of OIDs to try and retreive

=item ip

an IP address to connect to or an SNMP::Session

=back

=cut

sub get1 {
    warn 'too few arguments'  if @_ < 2;
    warn 'too many arguments' if @_ > 2;
    my ($OIDs,$ip) = @_;

    my $session = $ip;
    unless (blessed $session and $session->isa('SNMP::Session')) {
        return undef if ref $session;
        $session = SNMP $session;
        return undef unless defined $session;
    }

    my (@objects,@IIDs);
    foreach my $OID (@$OIDs) {
        my $query = SNMP::Varbind->new([$OID->[0]]);
        while (my $object = $session->getnext($query)) {
            last unless $query->tag eq $OID->[1] and not $session->{'ErrorNum'};
            last if $object =~ /^ENDOFMIBVIEW$/;
            $object =~ s/^\s*(.*?)\s*$/$1/;
            push (@IIDs,$query->iid);
            push (@objects,$object);
        }
        last if @objects != 0;
    }
    return undef if @objects == 0;
    return (\@objects,\@IIDs);
}


=head2 set

attempt to set a new value on a device using SNMP

B<Arguments>

I<( $OID , $IID , $value , $ip )>

=over 3

=item OID

the OID to write the value argument to

=item IID

the IID to write the value argument to

=item value

the value to write to OID.IID

=item ip

an IP address to connect to OR an SNMP::Session

=back

=cut

sub set {
    warn 'too few arguments'  if @_ < 4;
    warn 'too many arguments' if @_ > 4;
    my ($OID,$IID,$value,$ip) = @_;

    my $session = $ip;
    unless (blessed $session and $session->isa('SNMP::Session')) {
        return undef if ref $session;
        $session = SNMP $session;
        return undef unless defined $session;
    }

    my $query = SNMP::Varbind->new([$OID,$IID,$value]);
    $session->set($query);
    return ($session->{'ErrorNum'}) ? $session->{'ErrorStr'} : 0;
}


=head1 AUTHOR

David Tucker, C<< <dmtucker at ucsc.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-netsync at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Netsync>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc App::Netsync

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Netsync>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Netsync>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Netsync>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Netsync/>

=back

=head1 LICENSE

Copyright 2013 David Tucker.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


1;
