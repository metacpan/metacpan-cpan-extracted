package App::DNS::Zonewalk;

use strict;
use warnings;
use feature qw(switch);

use parent 'Net::DNS::Resolver';

our $VERSION = 0.05;

=head1 NAME

App::DNS::Zonewalk - helper library for recursive DNS zone walks.

=head1 ABSTRACT

Helper library for B<zonewalk>. Adds a B<raxfr()> method to Net::DNS::Resolver.

=head1 SYNOPSIS

    use App::DNS::Zonewalk;

    my $resolver = App::DNS::Zonewalk->new();
    my @net_dns_rrs = $resolver->raxfr($start_zone)
    ...

=head1 DESCRIPTION

See the B<zonewalk> documentation for more details, a cli program included in this distribution for recusive DNS zonewalks.

=head1 METHODS

=head2 raxfr($start_zone)

  my @resource_records = $resolver->raxfr($start_zone);

Walks the $start_zone recursively and returns all DNS resource records. The DNS server from $resolver must be authoritative for the zone und sub-zones and the client must be allowed to fetch the zones via AXFR.

=cut

sub raxfr {
    my ( $self, $start_zone ) = @_;

    unless ($start_zone) {
        print ";; ERROR: raxfr: no zone specified\n" if $self->{'debug'};
        $self->errorstring('no zone');
        return;
    }

    # housekeeping for recursion
    my $dyn_zone_list = {};
    my $zones_done    = {};
    my @zone;

    $dyn_zone_list->{$start_zone}++;

  ZONE:
    while ( my ($zone) = sort keys %$dyn_zone_list ) {

        print ";; processing '$zone' ...\n" if $self->{'debug'};

        delete $dyn_zone_list->{$zone};
        next ZONE if exists $zones_done->{$zone};

        # mark current zone as done
        $zones_done->{$zone}++;

        # skip zone if resolvers nameserver isn't autoritative
        next ZONE unless $self->_check_is_auth($zone);

        my @zone_records = $self->axfr($zone);

        unless (@zone_records) {
            print ";; skipping $zone: ", $self->errorstring, "\n"
              if $self->{'debug'};
            next ZONE;
        }

        foreach my $rr (@zone_records) {
            push @zone, $rr;

            if ( $rr->type eq 'NS' ) {

                my $new_zone = lc $rr->name;

                # push to dyn_zone_list when index('foo.bar.baz', 'bar.baz')
                # not already handled and not already stored for handling
                if (   index( $new_zone, $zone )
                    && not exists $zones_done->{$new_zone}
                    && not exists $dyn_zone_list->{$new_zone} )
                {
                    $dyn_zone_list->{$new_zone}++;
                }

            }
        }

    }

    return wantarray ? @zone : \@zone;
}

###############################################
# check if nameserver is authoritative for zone
###############################################

sub _check_is_auth {
    my ( $self, $zone ) = @_;

    # get the nameservers for this zone
    my $ans = $self->send( $zone, 'NS' );

    # uups, something bad happened
    unless ( defined $ans ) {
        print ';; ERROR: ', $self->errorstring, "\n"
          if $self->{'debug'};
        return;
    }

    # store the nameserver FQDN names
    my @ns_names;
    foreach my $rr ( $ans->answer ) {
        push @ns_names, $rr->nsdname;
    }

    # but we need the addresses for comparison, sigh
    my @ns_addresses;
    foreach my $ns_name (@ns_names) {
        my $any_packet = $self->query( $ns_name, 'ANY' );

        next unless defined $any_packet;

        foreach my $rr ( $any_packet->answer ) {
            next unless defined $rr;
            next unless ( $rr->type eq 'A' || $rr->type eq 'AAAA' );
            push @ns_addresses, $rr->address;
        }
    }

    # now compare the resolvers nameserver with the authoritattive
    # nameservers for this zone
    my ($resolvers_ns) = $self->nameservers;

    unless ( $resolvers_ns ~~ @ns_addresses ) {
        $self->errorstring("NS $resolvers_ns is nonauth for $zone");
        print ';; ERROR: ', $self->errorstring, "\n"
          if $self->{'debug'};
        return;
    }

    # our resolvers first nameserver is authoritative
    return 1;

}

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai(at)cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-dns-zonewalk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-DNS-Zonewalk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::DNS::Zonewalk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-DNS-Zonewalk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-DNS-Zonewalk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-DNS-Zonewalk>

=item * Search CPAN

L<http://search.cpan.org/dist/App-DNS-Zonewalk/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Karl Gaissmaier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of App::DNS::Zonewalk

# vim: sw=4 ft=perl
