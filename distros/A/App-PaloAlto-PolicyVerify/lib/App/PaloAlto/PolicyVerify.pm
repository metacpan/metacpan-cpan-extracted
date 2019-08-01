use strict;
use warnings;
use 5.010;

package App::PaloAlto::PolicyVerify;
$App::PaloAlto::PolicyVerify::VERSION = '0.0.2';

# PODNAME
# ABSTRACT: Test firewall rules using log files.

use Device::Firewall::PaloAlto;
use Getopt::Long qw(GetOptionsFromArray);
use Text::CSV;

sub new {
    my $class = shift;
    my %obj;

# Set default arguments. Paloa Alto defaults are set by the Device::Firewall::PaloAlto module.
    my %arguments = (
        vr      => 'default',
        vsys    => 1,
        sepchar => ',',
        fields  => '0,1,2,3,4',
        @_
    );

    # Extract and check the fields
    $obj{fields} = [ split( ',', $arguments{fields} ) ];
    if ( ( my $nfields = @{ $obj{fields} } ) != 5 ) {
        die
"'fields' argument has $nfields comma-separated values; needs to be 5 - e.g. '2,4,7,8,9'";
    }

    # Set up the firewall object
    my %pa_args = %arguments{qw(uri username password insecure)};
    $pa_args{verify_hostname} = delete $pa_args{insecure};
    $obj{vr}                  = $arguments{vr};

    $obj{fw} = Device::Firewall::PaloAlto->new(%pa_args)->auth()
      or die $obj{fw}->error;

    # Set up the CSV object
    $obj{csv} =
      Text::CSV->new( { binary => 1, sep_char => $arguments{sepchar} } )
      or die Text::CSV->error_diag();

    # Open the logfile;
    open( $obj{fh}, '<:encoding(utf8)', $arguments{logfile} )
      or die "Could not open file '$arguments{logfile}'";

    return bless \%obj, $class;
}

sub sep {
    my $self = shift;
    my ($sep_char) = @_;

    $self->{csv}->sep_char($sep_char);

    return $self;
}

sub logfile {
    my $self     = shift;
    my $filepath = shift;

    open( $self->{fh}, '<:encoding(utf8)', $filepath )
      or die "Could not open file '$filepath'";

    return $self;
}

sub fields {
    my $self           = shift;
    my %column_numbers = @_;

    die "Five fields are required" unless ( keys %column_numbers == 5 );

    $self->{fields} =
      [ @column_numbers{qw(src_ip dst_ip src_port dst_port protocol)} ];

    return $self;
}

use constant {
    SRC_IP   => 0,
    DST_IP   => 1,
    SRC_PORT => 2,
    DST_PORT => 3,
    PROTO    => 4
};

{

    # Cache for src/dst IP, dst port, and proto flows.
    my %run_cache;

    sub run {
        my $self = shift;
        my $flow_cache_key;

        while ( my $row = $self->{csv}->getline( $self->{fh} ) ) {

            # Extract the flow fields
            my @flow_info = @{$row}[ @{ $self->{fields} } ];

            my $num_fields = grep { defined $_ } @flow_info;
            if ( $num_fields != 5 ) {
                die
"Only $num_fields fields extracted based on the separating character. We expect 5";
            }

            # Set up the cache key and return an entry if it exists
            # Note that we don't cache based on source port.
            $flow_cache_key =
              join( ':', @flow_info[ SRC_IP, DST_IP, DST_PORT, PROTO ] );

            # Pull the result out of cache, or we test
            # the security policy
            my $result =
              $run_cache{flow_cache_key} || $self->_test_sec_policy(@flow_info);
            next unless $result;

            # Add the result to the cache if needed.
            $run_cache{$flow_cache_key} //= $result;

            say $result->rulename . ','
              . $result->action . ','
              . $result->index . ',';
        }

    }

}

sub _test_sec_policy {
    my $self      = shift;
    my @flow_info = @_;

    # Find the zones for the source and dst IPs
    my $src_zone = $self->ip_to_zone( $flow_info[SRC_IP] ) or return;
    my $dst_zone = $self->ip_to_zone( $flow_info[DST_IP] ) or return;

    # Find the security policy
    my $result = $self->{fw}->test->sec_policy(
        from     => $src_zone,
        to       => $dst_zone,
        src_ip   => $flow_info[SRC_IP],
        dst_ip   => $flow_info[DST_IP],
        protocol => $flow_info[PROTO]
    );

    return $result;
}

{
    # Cache for FIB entries so we don't continuously make calls out to
    # fib_lookup
    my %fib_cache;

    # Cache the interfaces on the firewall
    my $interfaces;

    sub ip_to_zone {
        my $self = shift;
        my ($ip) = @_;

        # Find the egress interface from the FIB
        # We check if the entry exists because we want to know about
        # undefined routes that don't exist.
        my $fib_entry;
        if ( exists $fib_cache{$ip} ) {
            $fib_entry = $fib_cache{$ip};
        }
        else {
            $fib_entry = $fib_cache{$ip} = $self->{fw}->test->fib_lookup(
                ip             => $ip,
                virtual_router => $self->{vr}
            );
        }
        warn "No valid route for IP '$ip', skipping..." and return
          unless $fib_entry;

# FIXME: we're diving straight into the Device::Firewall::PaloAlto::Test::FIB's
# internal structure. Once its interface is better defined we'll go through that.
        my $fib_interface = $fib_entry->{entries}[0]{interface};

        # Find the zone the interface is tethered in
        $interfaces //= $self->{fw}->op->interfaces;
        warn $interfaces->error and return unless $interfaces;

        my $interface = $interfaces->interface($fib_interface);
        warn $interface->error unless $interface;

        my $zone = $interface->zone;
        warn
"Interface '$fib_interface' does not appear to be in a zone, skipping..."
          and return
          unless $zone;

        return $zone;
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PaloAlto::PolicyVerify - Test firewall rules using log files.

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

This is the supporting module for the L<pa_policy_verify> application.

=head1 DESCRIPTION

This module contains the methods used by the L<pa_policy_verify> application.
It takes in information allowing it to connect to a Palo Alto firewall, and a logfile containing
flows - source/destination IP & ports, and a protocol.

It then runs each flow in the log against the security rulebase currently installed on the Palo Alto firewall 
and returns a result. The result contains:

=over 2

=item Which rule the flow would have hit

=item The action the rule takes

=item The index of the rule.

=back

The main use case is when migrating from a different firewall to the Palo Alto. It allows for the 
qualification of the migrated rulebase prior to the cutover of production flows.

=head1 METHODS

=head2 new

    my $fw_tester = App::PaloAlto::PolicyVerify->new(
        uri => 'https://pa.localdomain',
        username => 'admin',
        password => 'redacted',
        insecure => 0,
        vr => 'default',
        vsys => 1,
        logfile => '/home/user/logs.csv',
        sepchar => ',',
        fields => '0,1,2,3,4'
    );

Contructs the object. Each argument maps to a command line switch in L<pa_policy_verify>. Please refer to its
documentation for information and default values.

The only argument without a default is C<logfile>.

=head2 sepchar

    $fw_tester->sepchar(';');

Sets the separating character between the fields in the logfile.

=head2 logfile 

    $fw_tester->logfile('/home/user/logfile.csv');

Sets the logfile containing flow information that will be run against the firewall.

=head2 fields

    $fw_tester->fields(
        src_ip => 3,
        dst_ip => 4,
        src_port => 8,
        dst_port => 9,
        protocol => 20
    );

Sets the column number in the logfile where each of the 5-tuple flow information resides.

=head2 run

    $fw_tester->run();

Runs the flows contained in the logfile against the firewall.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
