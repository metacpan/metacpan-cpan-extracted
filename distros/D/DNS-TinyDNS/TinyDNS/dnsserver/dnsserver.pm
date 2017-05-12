# by Anarion
#  anarion@7a69ezine.org
package DNS::TinyDNS::dnsserver;

our @ISA = qw(DNS::TinyDNS);
our $VERSION = '0.22';

=head1 NAME

DNS::TinyDNS::dnsserver - Perl extension for manipulating dnsserver from djbdns

=head1 SYNOPSIS

        use DNS::TinyDNS;

        # First create the object
        my $dnsserver = DNS::TinyDNS->new(type => 'dnsserver',
                                          dir  => '/service/tinydns');

        # Get zones
        @zones = $dnsserver->list_zones;

        # Get one zone
        $zone = $dnsserver->get_zone($zones[0]);

        # Add entry
        $dnsserver->add(zone => $zones[0],
                        type => 'ns',
                        host => 'anarion.7a69ezine.org',
                        ttl  => 84500,
                        );

        # Modify ip where tinydns listens
        $dnsserver->set_env( IP => '10.0.0.1' );
        $dnsserver->restart;


=head1 DESCRIPTION

This module will allow you to manipulate djbdns dnsserver files.

=head1 FUNCTIONS

=over 4

=head2 get_env/set_env

=back

You can set/get the this vars:

    IP
    ROOT

For further information about every var, consult djbdns server documentation at
C<http://cr.yp.to/>

=over 4

=head2 list_zones

=back

This method returns a list of all the diferent zones configured

    my @zones = $dnsserver->list_zones;

=over 4

=head2 get_zone

=back

This method returns a list of hashes with all records of one zone.
The keys of the hash deppends on the type of the record

    my @zone_e = $dnsserver->get_zone('catalunya.cat');

The hash have the following keys:

        type            => String showing the type of the record
                        ('ns','host','mx','alias','reverse')
        ttl             => ttl of the record
        ip              => ip of the host
        host            => host is only set with ns or mx records
        priority        => is only set with mx records

=over 4

=head2 list

=back

This method return an array of hashes with all records of one type.
Posible types are: mx, ns, host, alias, reverse or all

    my @mxs = $dnsserver->list(type => 'mx' ,
                               zone => '7a69ezine.org');

=over 4

=head2 add

=back

This method adds a mx record

        $dnsserver->add(zone => '7a69ezine.org',
                        type => 'mx',
                        ip   => '10.0.0.1',
                        host => 'rivendel.7a69ezine.org',
                        pref => 10,
                        ttl  => 84500,
                        );


This method adds a ns record

        $dnsserver->add(zone => '7a69ezine.org',
                        type => 'ns',
                        ip   => '10.0.0.1',
                        host => 'rivendel.7a69ezine.org',
                        ttl  => 84500,
                        );


This method adds a host record

        $dnsserver->add(zone => '7a69ezine.org',
                        type => 'host',
                        ip   => '10.0.0.1',
                        host => 'rivendel',
                        ttl  => 84500,
                        );

This method adds a alias record

        $dnsserver->add(zone => '7a69ezine.org',
                        type => 'alias',
                        cname=> 'www.7a69ezine.org',
                        host => 'rivendel',
                        ttl  => 84500,
                        );

This method add a reverse dns record

        $dnsserver->add(zone => '7a69ezine.org',
                        type => 'reverse',
                        host => 'anarion',
                        ip   => '10.0.0.13',
                        );


=over 4

=head2 del

=back

This method delete a mx record

        $dnsserver->del(zone => '7a69ezine.org',
                        type => 'mx',
                        ip   => '10.0.0.1',
                        host => 'rivendel.7a69ezine.org',
                        pref => 10,
                        );


This method delete a ns record

        $dnsserver->del(zone => '7a69ezine.org',
                        type => 'ns',
                        ip   => '10.0.0.1',
                        host => 'rivendel.7a69ezine.org',
                        );


This method delete a host record

        $dnsserver->del(zone => '7a69ezine.org',
                        type => 'host',
                        host => 'rivendel',
                        ip   => '10.0.0.1',
                        );

This method delete a alias record

        $dnsserver->del(zone => '7a69ezine.org',
                        type => 'alias',
                        host => 'rivendel',
                        cname=> 'www.7a69ezine.org',
                        );

This method delete a reverse dns record

        $dnsserver->del(type => 'reverse',
                        ip   => '10.0.0.13',
                        );

=head1 NOTE

If you want to change from named to bind you can use to methods:

=over 4

Allow bind to transfer the zones from localhost:

perl -lne 'system "tcpclient 127.0.0.1 53 axfr-get $1 zona-$1 zona-$1.tmp" if /zone[^"]+"([^"]+)"/' /home/named/etc/named.conf

Use L<DNS::ZoneParse> and DNS::TinyDNS::dnsserver.

=back

=head1 AUTHOR

Anarion: anarion@7a69ezine.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DNS::TinyDNS::dnscache>.
L<DNS::TinyDNS>.

=cut

use Carp;
use Fcntl qw(:DEFAULT :flock);
use Cwd;

my %types = (   'ns'     => '[.&]',
                'host'   => '[=+]',
                'alias'  => 'C',
                'mx'     => '@',
                'reverse'=> '\^',
                'all'    => '[C.&=+@^]');

my %parse = (   'ns'     => \&_parse_ns,
                'host'   => \&_parse_host,
                'alias'  => \&_parse_alias,
                'mx'     => \&_parse_mx,
                'reverse'=> \&_parse_reverse,
                'all'    => \&_parse_all );


sub new
{
        my ($clase,$dir)=@_;
        my $self = {    dir        => $dir,
                        t_env      => { IP      => ''  ,
                                        ROOT    => '' },
                        svc        => '/usr/local/bin/svc'
                };
        return bless $self,$clase;
}

sub start
{
    my $self = shift;
    my $c_dir = getcwd;
    chdir($self->{dir} . '/root')
        or carp "Error cant chdir to $self->{dir}";
    system "/usr/bin/make"
        and carp "Error cant make database";

    chdir($c_dir);
    $self->SUPER::start();
}

sub restart
{
    my $self = shift;
    my $c_dir = getcwd;
    chdir($self->{dir} . '/root')
        or carp "Error cant chdir to $self->{dir}";
    system "/usr/bin/make"
        and carp "Error cant make database";

    chdir($c_dir);
    $self->SUPER::restart();
}

sub list
{
    my ($self,%options) = @_;
    my $file = $self->{dir} . "/root/data";
    my (@zone);
    local *FILE;

    unless($self->{dir} and -f $file)
    {
        carp "ERROR: dnsserver directory not set";
        return 0;
    }

    unless($options{type} and exists $types{$options{type}})
    {
        carp "ERROR: this type doesnt exists.";
        return 0;
    }

    open(FILE,$file)
        or carp "ERROR: Cant read from $file";
    flock(FILE,LOCK_EX)
        or carp "Cant lock $file";
    seek(FILE,0,0)
        or carp "ERROR: Cant seek $file";
    while(my $entrada=<FILE>)
    {
        chomp($entrada);
        if($entrada =~ /^$types{ $options{type} }/)
        {
                next if ! $options{zone} or
                        $entrada !~ /^.([\w\-]+\.)*\Q$options{zone}\E:/ and
                        $entrada !~ /^.[\w.]+\.in-addr.arpa:\Q$options{zone}\E:/;
                push(@zone,$parse{ $options{type} }->($entrada));
        }
    }
    close FILE
        or carp "Error: Cant Close File";
    return @zone;
}

sub list_zones
{
        my $self = shift;
        my $file=$self->{dir} . "/root/data";
        my %zones;
        local *FILE;

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnsserver directory not set";
                return 0;
        }

        open(FILE,$file)
                or carp "ERROR: Cant read from $file";
        flock(FILE,LOCK_EX)
                or carp "Cant lock $file";
        seek(FILE,0,0)
                or carp "ERROR: Cant seek $file";
        while(my $entrada=<FILE>)
        {
                $zones{$1}++ if $entrada=~/^.(?:\d{1,3}\.)([-\w.]+\.arpa):/ or
                                $entrada=~/^.(?:[\w\-]+\.)*([\w\-]+\.\w{2,4}):/
        }
        close FILE
                or carp "Error: Cant Close File";
        return keys %zones;
}

sub get_zone
{
        my ($self,$zone) = @_;
        my $file = $self->{dir} . "/root/data";
        my @zone;
        local *FILE;

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnsserver directory not set";
                return 0;
        }

        open(FILE,$file)
                or carp "ERROR: Cant read from $file";
        flock(FILE,LOCK_EX)
                or carp "Cant lock $file";
        seek(FILE,0,0)
                or carp "ERROR: Cant seek $file";
        while(my $entrada=<FILE>)
        {
                chomp($entrada);
                if ($entrada=~/^$types{all}(?:[\w\.\-]*\.)*\Q$zone\E:/ or
                    $entrada=~/^\^(?:\d{1,3}\.){4}in-addr.arpa:(?:[\w\-]+\.)*\Q$zone\E/)
                {
                        push(@zone,_parse_all->($entrada));
                }
        }
        close FILE
        or carp "Error: Cant Close File";
        return @zone;
}

sub add
{
        my ($self,%options) = @_;
        my $file = $self->{dir} . "/root/data";
        my $string;
        local *FILE;

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnsserver directory not set";
                return 0;
        }

        unless(exists $types{ $options{type} })
        {
                carp "ERROR: this type doesnt exists.";
                return 0;
        }

        open(FILE,">>$file")
                or carp "ERROR: Cant read from $file";
        flock(FILE,LOCK_EX)
                or carp "Cant lock $file";
        seek(FILE,0,2)
                or carp "ERROR: Cant seek $file";
        $options{ttl} ||= 86400;
        for($options{type})
        {
                $string =
                /ns/    && do { '.' . join":",@options{qw/zone ip host ttl/}                } ||
                /mx/    && do { '@' . join ":",@options{qw/zone ip host pref ttl/}          } ||
                /host/  && do { "+$options{host}." . join ":", @options{qw/zone ip ttl/}    } ||
                /alias/ && do { "C$options{host}." . join ":", @options{qw/zone cname ttl/} } ||
                /reverse/&&do { sprintf("^%d.%d.%d.%d.in-addr.arpa:%s.%s:%d",($options{ip} =~
                                /\d+/g)[3,2,1,0],@options{'host','zone','ttl'})             } or
                        carp "What type is ($_) ?";
        }
        return 0 unless $string;
        syswrite(FILE,"$string\n");
        close(FILE)
                or carp "Error: Cant close file";
}

sub del
{
        my ($self,%options) = @_;
        my $file = $self->{dir} . "/root/data";
        local (*FILE,*FILENEW);

        unless($self->{dir} and -f $file)
        {
                carp "ERROR: dnscache directory not set";
                return 0;
        }

        unless(exists $types{ $options{type} } and $options{zone})
        {
                carp "ERROR: not enougth arguments.";
                return 0;
        }

        open(FILENEW,">$file.new")
                or carp "ERROR: Cant write to $file.new";
        flock(FILENEW,LOCK_EX)
                or carp "Cant lock $file.new";

        open(FILE,"<$file")
                or carp "ERROR: Cant read from $file.new";
        flock(FILE,LOCK_EX)
                or carp "Cant lock $file";

        seek(FILE,0,0)
                or carp "ERROR: Cant seek $file";
        seek(FILENEW,0,0)
                or carp "ERROR: Cant seek $file.new";

        my $entry;
        for($options{type})
        {
                $entry = /host/ && do { "^[=+]\Q$options{host}.$options{zone}\E" .
                                        "\Q:$options{ip}$options{cname}\E"    } ||
                        /alias/ && do { "^C\Q$options{host}.$options{zone}\E"    .
                                        "\Q:$options{cname}\E"                } ||
                        /mx/    && do { "^\@\Q$options{zone}:$options{ip}\E"     .
                                        ":\Q$options{host}:$options{pref}\E"  } ||
                        /ns/    && do { "^[.&]\Q$options{zone}:$options{ip}\E"   .
                                        ":\Q$options{host}\E:"                } ||
                        /reverse/&&do { sprintf("^\\^%d.%d.%d.%d.in-addr.arpa:",
                                        ($options{ip} =~/\d+/g)[3,2,1,0])     } or
                        warn "Unknown option ($_)";
        }
        return 0 unless $entry;
        $entry = qr/$entry/;

        while(my $entrada=<FILE>)
        {
                next if $entrada=~/$entry/;
                syswrite(FILENEW,$entrada)
                        or carp "Cant write to file";
        }

        close(FILENEW)
                or carp "ERROR: Cant close $file.new";
        close(FILE)
            or carp "ERROR: Cant close $file";
        unlink($file)
            or carp "ERROR: Cant unlink $file";
        rename("$file.new",$file)
            or carp "ERROR: Cant rename $file.new to $file";
        return $trobat;
}

### PRIVATE SUBS
sub _parse_ns
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             type => 'ns',
             host => $data[2],
             ttl  => $data[3]  };
}

sub _parse_mx
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             type => 'mx',
             host => $data[2],
             ttl  => $data[4],
             pref => $data[3]  };
}

sub _parse_host
{
    my @data=split/:/,substr($_[0],1);
    my ($host,$zone) = split/\./,$data[0],2;
    return { zone => $zone,
             host => $host,
             type => 'host',
             ip   => $data[1],
             ttl  => $data[2]  };
}

sub _parse_alias
{
    my @data=split/:/,substr($_[0],1);
    my ($host,$zone) = split/\./,$data[0],2;
    return { zone => $zone,
             host => $host,
             type => 'alias',
             cname=> $data[1],
             ttl  => $data[2]  };
}

sub _parse_reverse
{
    my @data=split/:/,substr($_[0],1);
    my $ip = join ".", ($data[0]=~/\d+/g)[3,2,1,0];
    my ($host,$zone) = split/\./,$data[1],2;
    return { zone => $zone,
             ip   => $ip,
             type => 'reverse',
             host => $host,
             ttl  => $data[2] };
}

sub _parse_all
{
    my $tipus=substr($_[0],0,1);
    my %types = ( '.'    => \&_parse_ns,
                  '&'    => \&_parse_ns,
                  '='    => \&_parse_host,
                  '+'    => \&_parse_host,
                  'C'    => \&_parse_alias,
                  '^'    => \&_parse_reverse,
                  '@'    => \&_parse_mx );
    return exists $types{$tipus} ? $types{$tipus}->($_[0]) : 0
}

1;
