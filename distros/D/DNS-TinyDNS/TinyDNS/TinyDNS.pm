###
#  by Anarion
#  anarion@7a69ezine.org
package DNS::TinyDNS;

our $VERSION = '0.22';

=head1 NAME

DNS::TinyDNS - Perl extension for manipulating djbdns

=head1 SYNOPSIS

  use DNS::TinyDNS;

  # Create a dnsserver or a dnscache
  my $cache  = DNS::TinyDNS->new(type => 'dnscache');
  my $server = DNS::TinyDNS->new(type => 'dnsserver');


  # Set the config directory
  $server->dir('/service/tinydns');

  # start, stop and restart
  $cache->stop;
  $cache->start;
  $server->restart;

=head1 DESCRIPTION

This module will allow you to manipulate djbdns files. You can
configure the options of dnscache, list, add, remove, or modify
all the entrys of your dns server too.

Please check the documentation of L<DNS::TinyDNS::dnscache> or
L<DNS::TinyDNS::dnsserver> to see the details of each one.


=head1 FUNCTIONS

=over 4

=head2 new

=back

When you create a new object you have to specify if it's a dns server
or a dnscache.

        # Create a dnsserver
        my $server=DNS::TinyDNS->new(type => 'dnsserver');

        # Create a dnscache
        my $cache  = DNS::TinyDNS->new(type => 'dnscache');

You can specify the directory at this time or do it later.

        my $server = DNS::TinyDNS->new( type => 'dnsserver',
                                        dir  => '/service/tinydns');

=over 4

=head2 dir

=back

If you pass a parameter, it sets the directory, otherwise, it just
return the value of the directory.

        $server->dir('/etc/tinydns')
                or warn "Cant change dir to /etc/tinydns";

        my $dir = $server->dir;

=over 4

=head2 get_env

=back

This method depends on the type of the object.

=over 4

=head2 set_env

=back

This method depends on the type of the object.

=over 4

=head2 start,stop,restart

=back

This methods deppends on where are installed daemontools, by
default, they are at /usr/local/bin/svc but you can change
it with the svc method.

        $cache->restart or warn "Cant restart";
        $server->stop or warn "Cant stop";
        $server->start or warn "Cant start";

=over 4

=head2 svc

=back

If you pass a parameter, it sets the location of svc, otherways
it just return the current value.

        my $svc_location = $server->svc;
        $server->svc('/usr/bin/svc')
                or warn "Cant set svc to /usr/bin/svc";

=head1 AUTHOR

Anarion: anarion@7a69ezine.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DNS::TinyDNS::dnscache>.
L<DNS::TinyDNS::dnsserver>.

=cut

use strict;
use warnings;
use Carp;
use Fcntl qw(:DEFAULT :flock);


sub new
{
        my ($clase,%tipus) = @_;
        unless($tipus{type} eq "dnscache" or $tipus{type} eq "dnsserver")
        {
                carp "ERROR: Invalid type. You should use dnsserver or dnscache";
                return 0;
        }
        eval qq(require ${clase}::$tipus{type})
                or carp $@ and return 0;
        return "${clase}::$tipus{type}"->new( $tipus{dir} );
}

sub dir
{
        my ($self,$dir) = @_;
        if ($dir)
        {
                return 0 unless -d $dir;
                $self->{dir} = $dir
        }
        return $self->{dir}
}

sub get_env
{
        my ($self,@types) = @_;
        local *FILE;

        unless($self->{dir})
        {
                carp "ERROR: You must set the directory";
                return 0;
        }

        @types = map { uc } @types;

        for my $type (@types)
        {
                unless(exists $self->{t_env}->{$type})
                {
                        carp "ERROR: Invalid env type";
                        return 0;
                }

                # only check the fs if its not set
                unless($self->{t_env}->{$type})
                {
                        my $file = $self->{dir} . "/env/" . $type;
                        open(FILE,$file)
                                or carp "ERROR: Cant read from $file" and return;
                        flock(FILE,LOCK_EX)
                                or carp "ERROR: Cant flock $file";
                        seek(FILE,0,0)
                                or carp "ERROR: Cant seek $file";
                        chomp($self->{t_env}->{$type} = <FILE>);
                        close(FILE)
                                or carp "ERROR: Cant close $file";
                }
        }
        return @{$self->{t_env}}{@types};
}

sub set_env
{
        my ($self,%types) = @_;
        local *FILE;

        unless($self->{dir})
        {
                carp "ERROR: Directory not set";
                return 0;
        }


        for my $type (keys %types)
        {
                my $uctype = uc $type;
                unless(exists $self->{t_env}->{$uctype})
                {
                        carp "ERROR: Invalid env type";
                        return 0;
                }

                unless(defined $types{$type})
                {
                        carp "ERROR: You must supply a new value for $type";
                        return 0;
                }

                my $file = $self->{dir} . "/env/" . $uctype;
                sysopen(FILE, $file, O_RDWR | O_CREAT | O_TRUNC)
                        or carp "ERROR: Cant write to $file" and return;
                flock(FILE,LOCK_EX)
                        or carp "ERROR: Cant lock $file";
                seek(FILE,0,0)
                        or carp "ERROR: Cant seek $file";
                $self->{t_env}->{$uctype} = $types{$type};
                syswrite(FILE,$types{$type});
                close(FILE)
                        or carp "ERROR: Cant close $file";
        }
        return 1;
}

sub stop
{
        my $self = shift;
        system "$self->{svc} -d $self->{dir}";
        return !$?;
}

sub start
{
        my $self = shift;
        system "$self->{svc} -u $self->{dir}";
        return !$?;
}

sub restart
{
        my $self = shift;
        system "$self->{svc} -t $self->{dir}";
        return !$?;
}

sub svc
{
        my ($self,$svc) = @_;
        if ($svc)
        {
                return 0 unless -f $svc;
                $self->{svc} = $svc
        }
        return $self->{svc}
}

1;
