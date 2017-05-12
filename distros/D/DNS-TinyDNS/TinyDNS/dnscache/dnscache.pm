###
#  by Anarion
#  anarion@7a69ezine.org
package DNS::TinyDNS::dnscache;

our @ISA = qw(DNS::TinyDNS);
our $VERSION = '0.22';

=head1 NAME

DNS::TinyDNS::dnscache - Perl extension for manipulating dnscache from djbdns

=head1 SYNOPSIS

        use DNS::TinyDNS;

        # First create the object
        my $dnscache = DNS::TinyDNS->new(type => 'dnscache',
                                         dir  => '/service/dnscachex');

        # Manage the allowed ips to use this cache
        my @ips=$dnscache->list_ips;
        $dnscache->add_ip('10.0.0.1');
        $dnscache->del_ip('10.0.0');

        # Manage root servers
        my @root_servers=$dnscache->list_servers;
        $dnscache->add_server('10.0.0.1');
        $dnscache->del_server('10.0.0.1');

        # Manage the enviroment
        $dnscache->set_env(     cachesize   => 100000,
                                ip          => '10.0.0.1');
        my ($cache,$ip) = $dnscache->get_env( 'cachesize', 'ip' );

=head1 DESCRIPTION

This module will allow you to manipulate djbdns dnscache files.

=head1 FUNCTIONS

=over 4

=head2 list_ips

=back

Returns a list/reference of all the ips/nets allowed to use this cache server

        # Returns a list
        my @ips = $dnscache->list_ips;

        # Returns an array ref
        my $ips = $dnscache->list_ips;

=over 4

=head2 add_ip

=back

Adds an ips/nets to use this cache server

        $dnscache->add_ip('10.0.0');

This let all 10.0.0.0/24 to use this dnsserver.

=over 4

=head2 del_ip

=back

Remove an ips/nets of the list of allowed ips

        $dnscache->del_ip('10.0.0');

This deletes C<All entries> of 10.0.0.0/24 allowed to use this dnscache.

=over 4

=head2 lists_servers

=back

Returns a list/reference of the root servers

        # Returns a list
        my @root_servers = $dnscache->list_servers;

        # Returns an array ref
        my $root_servers = $dnscache->list_servers;

=over 4

=head2 add_server

=back

Add a root server

        $dnscache->add_server('10.0.0.1')
                or warn "Cant add server";

=head2 del_server


Deletes a root server

        $dnscache->del_server('10.0.0.1')
                or warn "Cant del server";

=over 4

=head2 get_env set_env

=back

You can set/get this vars:

    IP
    IPSEND
    CACHESIZE
    DATALIMIT
    ROOT

For further information about every var, consult djbdns cache documentation at
C<http://cr.yp.to/>

=head1 AUTHOR

Anarion: anarion@7a69ezine.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DNS::TinyDNS>.
L<DNS::TinyDNS::dnsserver>.

=cut

use Carp;
use Fcntl qw(:DEFAULT :flock);

sub new
{
        my ($clase,$dir) = @_;
        my $self = {    dir     => $dir,
                        t_env   => {    IP              => '',
                                        IPSEND          => '',
                                        CACHESIZE       => '',
                                        DATALIMIT       => '',
                                        ROOT            => ''
                                        },
                        svc     => '/usr/local/bin/svc'
                };
        return bless $self,$clase;
}


sub add_ip
{
        my ($self,$ip) = @_;
        my $dir = $self->{dir} . "/root/ip";
        local *FILE;

        unless($self->{dir} and -d $dir)
        {
                carp "ERROR: dnscache directory not set";
                return 0;
        }

        unless(defined $ip)
        {
                carp "ERROR: You must supply an ip ($ip)";
                return 0;
        }

        open(FILE,">$dir/$ip")
                or carp "ERROR: Cant create $dir/$ip";
        close(FILE);
}

sub del_ip
{
        my ($self,$ip) = @_;
        my $dir = $self->{dir} . "/root/ip";

        unless($self->{dir} and -d $dir)
        {
                carp "ERROR: dnscache directory not set";
                return 0;
        }

        unlink("$dir/$ip")
                or carp "Warning: That ip wasn't in the db";#'
}

sub list_ips
{
        my $self = shift;
        my $dir = $self->{dir} . "/root/ip";
        my @ips;
        local *FILE;

        unless($self->{dir} and -d $dir)
        {
                carp "ERROR: dnscache directory not set";
                return 0;
        }

        opendir(FILE,$dir)
            or carp "ERROR: Cant read $dir";
        @ips = grep { index($_,".") != 0 } readdir(FILE);
        closedir(FILE);
        return wantarray ? @ips : \@ips;
}

sub add_server
{
        my ($self,$ip) = @_;
        my $file = $self->{dir} . '/root/servers/@';
        my @array;
        local *FILE;

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnscache directory not set";
                return 0;
        }

        open(FILE, ">>$file")
            or carp "ERROR: Cant write to $file" and return;
        flock(FILE,LOCK_EX)
            or carp "ERROR: Cant lock $file";
        seek(FILE,0,2)
            or carp "ERROR: Cant seek $file";
        print FILE "$ip\n";
        close(FILE)
                or carp "ERROR: Cant close $file";
}

sub del_server
{
        my ($self,$ip) = @_;
        my $file = $self->{dir} . '/root/servers/@';
        my @array;
        local (*FILENEW,*FILEOLD);

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: $self->{dir} isn't a dnscache directory";#'
                return 0;
        }

        open(FILENEW, ">$self->{dir}/root/servers/new")
                or carp "ERROR: Cant write to $self->{dir}/root/servers/new" and return;
        flock(FILENEW,LOCK_EX)
            or carp "ERROR: Cant lock $self->{dir}/root/servers/new";
        open(FILEOLD,$file)
            or carp "ERROR: Cant read from $file" and return;
        flock(FILEOLD,LOCK_EX)
            or carp "ERROR: Cant lock $file";
        seek(FILEOLD,0,0)
            or carp "ERROR: Cant seek $file";
        seek(FILENEW,0,0)
                or carp "ERROR: Cant seek $self->{dir}/root/servers/new";
        while(my $line = <FILEOLD>)
        {
                syswrite(FILENEW,$line) if index($line,$ip) == -1;
        }
        close(FILENEW)
                or carp "ERROR: Cant close $self->{dir}/root/servers/new";
        close(FILEOLD)
            or carp "ERROR: Cant close $self->{dir}/root/servers/new";
        unlink($file)
            or carp "ERROR: Cant unlink $self->{dir}/root/servers/new";
        rename($self->{dir} . '/root/servers/new',$file)
            or carp "ERROR: Cant rename new to $file";
}

sub list_servers
{
        my $self = shift;
        my $file = $self->{dir} . '/root/servers/@';
        my @root_servers;
        local *FILE;

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnscache directory not set ($file)";
                return 0;
        }

        open(FILE,$file)
            or carp "ERROR: Cant read from $file";
        flock(FILE,LOCK_EX)
            or carp "Cant lock $file";
        seek(FILE,0,0)
            or carp "ERROR: Cant seek $file";
        chomp(@root_servers=<FILE>);
        close(FILE)
            or carp "ERROR: Cant close $file";
        return wantarray ? @root_servers : \@root_servers;
}

1;
