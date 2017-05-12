package App::Cerberus::Plugin::Throttle;
$App::Cerberus::Plugin::Throttle::VERSION = '0.11';
use strict;
use warnings;
use Carp;
use parent 'App::Cerberus::Plugin';
use Net::IP::Match::Regexp qw(create_iprange_regexp_depthfirst match_ip);
use DateTime();

my %Periods = (
    second => 5,
    minute => 4,
    hour   => 3,
    day    => 2,
    month  => 1
);

my %Expire = (
    second => 1,
    minute => 60,
    hour   => 3600,
    day    => 24 * 3600,
    month  => 31 * 24 * 3600
);

my @Days = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

my %Sleep;
%Sleep = (
    second => sub { shift->{second_penalty} },
    minute => sub { 60 - $_[6] },
    hour   => sub { ( 60 - $_[5] ) * 60 - $Sleep{minute}->(@_) },
    day    => sub { ( 24 - $_[4] ) * 3600 - $Sleep{hour}->(@_) },
    month  => sub {
        my ( undef, $y, $M, $d ) = @_;
        my $days = $Days[ $M - 1 ];
        $days++ if $M == 2 and !( $y % 4 ) && ( $y % 100 ) || !( $y % 400 );
        ( $days - $d ) * 24 * 3600 - $Sleep{day}->(@_);
    },
);

#===================================
sub init {
#===================================
    my ( $self, $conf ) = @_;

    $self->{store} = $self->_init_store( $conf->{store} );
    $self->{second_penalty} = $conf->{second_penalty} || 1;

    my $events = $conf->{events} || { default => $conf->{ranges} };
    croak "No (ranges) have been specified"
        unless %$events;

    for ( keys %$events ) {
        $self->{events}{$_} = $self->_parse_ranges( $_, $events->{$_} );
    }
}

#===================================
sub _parse_ranges {
#===================================
    my ( $self, $event, $conf ) = @_;

    my ( %range_limits, %group, @ips );

    for my $name ( keys %$conf ) {

        $group{$name} = 1
            if $conf->{$name}{group_ips};

        my $ips = $conf->{$name}{ips}
            or croak "No (ips) specified for event ($event) range ($name)";
        $ips = [$ips] unless ref $ips;
        push @ips, map { $_ => $name } @$ips;

        my $limits = $conf->{$name}{limit}
            or croak "No (limit) specified for event ($event) range ($name)";

        unless ( ref $limits eq 'ARRAY' ) {
            if ( $limits eq 'banned' or $limits eq 'none' ) {
                $range_limits{$name}{$limits} = 1;
                next;
            }
            $limits = [$limits];
        }

        for my $limit (@$limits) {
            $limit = '' unless defined $limit;
            my ( $max, $period ) = (
                $limit =~ /
                    ^
                    \s*
                    (\d+)       # Number
                    \s+
                    per         # 'per'
                    \s+
                    (\w+)       # $period
                    \s*
                    $/x
            );

            croak "Couldn't parse limit ($limit) in range ($name)"
                unless $period && $Periods{$period};

            next unless $max;
            $range_limits{$name}{$period} = $max;
        }
    }

    return {
        range_regex => create_iprange_regexp_depthfirst( {@ips} ),
        limits      => \%range_limits,
        group       => \%group
    };
}

#===================================
sub _init_store {
#===================================
    my ( $self, $conf ) = @_;
    $conf ||= 'Memory';

    my ( $class, $args )
        = ref $conf eq 'HASH'
        ? %$conf
        : ( $conf => {} );

    $class = __PACKAGE__ . '::' . $class;

    eval "require $class"
        or croak "Couldn't load Throttle store: $@";

    $class->new($args);
}
#===================================
sub request {
#===================================
    my ( $self, $req, $response ) = @_;

    $response->{throttle}{sleep} = 0;

    my $ip = $req->param('ip') or return;
    my $event = $req->param('event') || 'default';
    my $conf = $self->{events}{$event} or return;

    my $range = match_ip( $ip, $conf->{range_regex} ) or return;
    $response->{throttle}{range} = $range;

    my $limits = $conf->{limits}{$range};
    return if $limits->{none};

    if ( $limits->{banned} ) {
        $response->{throttle}{sleep}  = -1;
        $response->{throttle}{reason} = 'banned';
        return;
    }

    my @ts   = timestamp();
    my $name = $event . '_' . ( $conf->{group}{$range} ? $range : $ip );
    my %keys = map { $_ => $name . '_' . join '', @ts[ 0 .. $Periods{$_} ] }
        keys %$limits;

    my %counts = $self->{store}->counts(%keys);
    my $max    = 0;
    my $reason = '';
    my $count  = 0;
    for my $period ( keys %keys ) {
        next unless ( $counts{$period} || 0 ) >= $limits->{$period};
        my $sleep = $Sleep{$period}->( $self, @ts );
        next if $max >= $sleep;
        $count  = $counts{$period};
        $max    = $sleep;
        $reason = $period;
    }
    if ($max) {
        $response->{throttle}{sleep}         = $max;
        $response->{throttle}{reason}        = $reason;
        $response->{throttle}{request_count} = $count;
    }
    $self->{store}->incr( map { $keys{$_} => $Expire{$_} } keys %keys );
}

#===================================
sub timestamp {
#===================================
    my $self = shift;
    my ( $s, $m, $h, $d, $M, $y ) = gmtime();
    $y += 1900;
    $M++;
    return ( $y, map { sprintf "%02d", $_ } $M, $d, $h, $m, $s );
}

1;

# ABSTRACT: Throttle request rates based on IP ranges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus::Plugin::Throttle - Throttle request rates based on IP ranges

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This plugin allows you to throttle (rate limit) requests per second, per minute,
per hour, per day or per month.  Different limits can apply to different
network ranges, and to different events.

=head1 REQUEST PARAMS

Throttling information is returned when an IPv4 address is passed in:

    curl http://host:port/?ip=64.233.160.1

Optionally, an event name can be included, which defaults to C<'default'>.

    curl http://host:port/?ip=64.233.160.1;event=foo

=head1 CONFIGURATION

    plugins:
      - Throttle:
            store:
                Memcached:
                    namespace:  cerberus
                    servers:
                        -       localhost:11211

            second_penalty:     5
            ranges:
                default:
                    ips:        0.0.0.0/0
                    limit:
                                - 20 per second
                                - 100 per minute

                google_bot:
                    group_ips:  1
                    limit:      10 per second
                    ips:
                                - 64.233.160.0/19
                                - 66.102.0.0/20

                abusive:
                    limit:      banned
                    ips:
                                - 205.217.153.73
                                - 199.19.249.196

=head2 store

There are two C<store> backends available: C<Memory> and C<Memcached>.
The C<Memory> backend should NEVER be used in production.  It is for testing
purposes only:

    plugins:
        - Throttle:
            store:      Memory
            ranges:    ...

The C<Memcached> backend uses L<Cache::Memcached::Fast> and you can pass
whatever options you would pass to L<new()|Cache::Memcached::Fast/CONSTRUCTOR>.

  - Throttle:
        store:
            Memcached:
                namespace:  cerberus
                servers:
                    -       localhost:11211

=head2 ranges

The key for each range is its name, eg C<default>, C<google_bot> etc, which is
returned by Cerberus.

=over

=item ips

The C<ips> parameter is compiled into a regex using L<Net::IP::Match::Regexp>.
If two ranges interesect, then the more specific range matches.

=item group_ips

If you want any IP address in a range to be considered the same
user (eg all IPs from Google), then specify:

    group_ips: 1

Otherwise each IP address will be treated separately.

=item limit

The C<limit> parameter can be:

=over

=item C<none>

Impose no limits

=item C<banned>

Never allow

=item C<MAX per PERIOD>

For instance, C<5 per second> or C<10 per minute>.  C<MAX> can be any positive
integer and C<PERIOD> any of C<second>, C<minute>, C<hour>, C<day> or C<month>.

=back

If no IP is passed, or if the IP does not match any range, this plugin returns:

    "throttle": {
        "sleep": 0
    }

If a range is matched, but the limit is not exceeded, the plugin returns (eg):

    "throttle": {
        "range": "google",
        "sleep": 0
    }

If the limit has been exceeded, the plugin returns (eg):

    "throttle": {
        "range":         "google",
        "reason":        "second",
        "sleep":         10,
        "request_count": 12
    }

Or, if C<banned>:

    "throttle": {
        "range": "google",
        "sleep": -1,
        "reason": "banned"
    }

=back

=head2 events

If you want to use different limits per event, then the config should be as
follows:

    plugins:
      - Throttle:
        events:
            default:
                ranges:
                    default:
                        ips:        0.0.0.0/0
                        limit:
                                    - 20 per second
                                    - 100 per minute
            my_event:
                ranges:
                    default:
                        ips:        0.0.0.0/0
                        limit:      5 per second

=head2 second_penalty

The value for C<sleep> reflects the number of seconds that the requesting user
should wait until they try again.  If the limit that has been exceeded is the
number of request per second, this value will be 1.

If you want to impose a bigger penalty (I<"Woah, slow down cowboy!">) you can
specify a C<second_penalty>.  B<Note:> this is advisory only.  Only polite
robots will respect this value.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
