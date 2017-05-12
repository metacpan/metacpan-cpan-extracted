package CCCP::LiveMX;

use strict;
use warnings;

our $VERSION = '0.01';

# from Mail::CheckUser, I use only $Mail::CheckUser::NXDOMAIN
use Mail::CheckUser qw();
use Net::DNS;
use Net::Ping 2.24;

=head1 NAME

CCCP::LiveMX

=head1 DESCRIPTION

Getting a ip-list of living MX-records for hostname

=head1 SYNOPSIS

    use CCCP::LiveMX;
    
    my $lmx = CCCP::LiveMX->check_host('example.org');
    if ($lmx->success) {
        my @live_ip = $lmx->live_ip;
    } else {
        print $lmx->error,"\n";
        my @not_ping_ip = $lmx->not_ping;
        my @not_ask_ip  = $lmx->not_ask;
    }
    
=head1 PACKAGE VARIABLES

=head2 $CCCP::LiveMX::timeout

Timeout for ping, resolve and another.
By default 5 sec.

=head1 METHODS

=cut

$CCCP::LiveMX::timeout = 5;

my $resolver;
my $ping;

=head2 check_host($host_name)

Checking MX records for C<$host_name> and return instance.

=cut
sub check_host {
    my ($class, $host) = @_;
    
    my $self = bless {
        error => undef,
        mx => {}
    }, $class;
    
    # Net::DNS::Resolver as a singletone
    $resolver ||= Net::DNS::Resolver->new();
    
    # Net::Ping as a singletone
    unless ($ping) {
        $ping = Net::Ping->new("syn", $CCCP::LiveMX::timeout);
        $ping->{port_num} = getservbyname("smtp", "tcp");
        $ping->service_check(1);
    };
    
    # getting mx-records
    $resolver->udp_timeout($CCCP::LiveMX::timeout);
    my @mx = mx($resolver, $host);
    unless (@mx) {
        # if the mx record is not found, try to check the hostname as a mail-server
        $resolver->udp_timeout($CCCP::LiveMX::timeout);
        my $res = $resolver->search($host, 'A');
        if ($res) {
            my $ip;
            foreach my $rr ($res->answer) {
                  if ($rr->type eq "A") {
                    $ip = $rr->address;
                    last;
                  } elsif ($rr->type eq "CNAME") {
                    $ip = $rr->cname;
                  } else {
                    # should never happen!
                    $ip = "";
                  }
            }
            if ($Mail::CheckUser::NXDOMAIN->{lc $ip}) {
                $self->error('Wildcard gTLD: '.$host.' ('.(lc $ip || '').')');
                return $self;
            }
            $self->_mx_servers($host,0);
        } else {
            $self->error('DNS failure: '.$host.' ('.$resolver->errorstring.')');
            return $self;
        }        
    } else {
        # if there is a mx-records, they have always been ordered by "preference"
        $self->_mx_servers(map {$_->exchange,$_->preference} @mx);
    };
    
    foreach my $mserver ($self->_mx_servers) {
        if ($Mail::CheckUser::NXDOMAIN->{lc $mserver}) {
            $self->error('Wildcard gTLD: '.$host.' ('.(lc $mserver || '').')');
            return $self;
        };
        # getting ip from server-name
        my $ip;
        if ($mserver !~ /^\d+\.\d+\.\d+\.\d+$/) {
            # resolve server-name if we do not have ip
            $resolver->udp_timeout($CCCP::LiveMX::timeout);
            if (my $ans = $resolver->query($mserver)) {
                foreach my $rr_a ($ans->answer) {
                    if ($rr_a->type eq "A") {
                        $ip = $rr_a->address;
                        $self->_mx_ip($mserver,$ip);
                        last;
                    }
                }
            }
        } else {
            $ip = $mserver;
            $self->_mx_ip($mserver,$ip);
        }
        next unless $ip;
        
        # try ping
        my $succ_ping = $ping->ping($ip) ? 1 : 0;
        $self->_mx_ping($mserver, $succ_ping);
        next unless $succ_ping;
        
        # try to get an answer
        my $succ_ask = $ping->ack($ip) ? 1 : 0;
        $self->_mx_ask($mserver,$succ_ask);
        next unless $succ_ask;
    }    
    
    unless (@{$self->live_ip}) {
        $self->error('Not found live ip for: '.$host);
    }
    
    return $self;
}

=head2 success()

Return status of check (bool)

=cut
sub success {
    my $self = shift;
    
    return $self->error ? 0 : 1;
}

=head2 live_ip()

Return list avaliable ip for host, sorted by "preference" mx-records

=cut
sub live_ip {
    my $self = shift;
    if ($self->{live_ip}) {
        return wantarray ? @{$self->{live_ip}} : $self->{live_ip}
    } else {
        $self->{live_ip} = [$self->_mx_ask]; 
        return $self->live_ip; 
    };
}

=head2 not_ping()

Return list ip for host, that not ping

=cut
sub not_ping {
    my $self = shift;
    my @ret = map {$self->{mx}->{$_}->{ip}} grep {!$self->{mx}->{$_}->{ping}} keys %{$self->{mx}};
    return wantarray ? @ret : [@ret]; 
}

=head2 not_ask()

Return list ip for host, that ping but not ask

=cut
sub not_ask {
    my $self = shift;
    my @ret = map {$self->{mx}->{$_}->{ip}} grep {!$self->{mx}->{$_}->{ask}} keys %{$self->{mx}};
    return wantarray ? @ret : [@ret];
}

=head2 error()

Return error(string) or undef

=cut
sub error {
    my $self = shift;
    if (@_) {
        $self->{error} = shift;
        return;
    } else {
        return $self->{error};
    };
}

# добавляем сервак с весом в список известных нам
sub _mx_servers {
    my $self = shift;
    if (@_) {
        my %hash = @_;
        while (my ($mx_name, $order) = each %hash) {
            $self->{mx}->{$mx_name}->{order} = $order unless exists $self->{mx}->{$mx_name}->{order}; 
        }
    } else {
        return keys %{$self->{mx}};
    };
}

# добавляем ip для сервака
sub _mx_ip {
    my $self = shift;
    if (@_) {
        my %hash = @_;
        while (my ($mx_name, $ip) = each %hash) {
            $self->{mx}->{$mx_name}->{ip} = $ip unless exists $self->{mx}->{$mx_name}->{ip};  
        }
        return;
    } else {
        return map {$self->{mx}->{$_}->{ip}} grep {$self->{mx}->{$_}->{ip}} keys %{$self->{mx}};
    };
}

# добавляем стутус пинга
sub _mx_ping {
    my $self = shift;
    my $mx_name = shift;
    if ($mx_name and @_) {
        $self->{mx}->{$mx_name}->{ping} = $_[0];
        return;
    } else {
        return map {$self->{mx}->{$_}->{ip}} grep {$self->{mx}->{$_}->{ping}} keys %{$self->{mx}};
    };
}

# респонсим
sub _mx_ask {
    my $self = shift;
    my $mx_name = shift;
    if ($mx_name and @_) {
        $self->{mx}->{$mx_name}->{ask} = $_[0];  
        return;
    } else {
        return map {$self->{mx}->{$_}->{ip}} sort {$self->{mx}->{$a}->{order} <=> $self->{mx}->{$b}->{order}} grep {$self->{mx}->{$_}->{ask}} keys %{$self->{mx}};
    };
}

=head1 DEPENDS ON

=over 4

=item *

L<Mail::CheckUser> (used only package variables)

=item *

L<Net::DNS>

=item *

L<Net::Ping>

=back

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
