#!/usr/bin/env perl

=head1 NAME

update-UPS-surcharge.pl

=head1 DESCRIPTION

Installed by Business::Shipping.

Updates the fuel surcharge (stored in C<config/fuel_surcharge.txt>) from the UPS web site.  It is 
recommended that this be run every first Monday of the month in the early AM.  Here is an example 
line to add to your crontab:

 01 4 * * 1 Business-Shipping-UPS_Offline-update-fuel-surcharge.pl

That causes cron to run this update program at 4:01 AM every Monday.  Another good cronjob to have
is one that will update your Business::Shipping::DataFiles:

 01 4 * * 1 perl -MCPAN -e 'install Business::Shipping::DataFiles'

 
 http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html
    
=head1 REQUIRED MODULES

LWP::UserAgent

=head1 METHODS

=cut

use strict;
use warnings;
use Business::Shipping;
use Business::Shipping::Logging;
use LWP::UserAgent;

#use POSIX ( 'strftime' );

#Business::Shipping->log_level( 'debug' );

&check_for_updates;

=head2 check_for_updates()

Stores the "Good Through" rate in config/fuel_surcharge.txt, with the date it was updated.

=cut

sub check_for_updates {
    my ($self) = @_;

    my $fuel_surcharge_filename
        = Business::Shipping::Config::config_dir() . '/fuel_surcharge.txt';

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy();
    my $request_param
        = 'http://www.ups.com/content/us/en/resources/find/cost/fuel_surcharge.html';
    my $response = $ua->get($request_param);
    die
        "Could not update fuel surchage: could not access ups fuel_surcharge page"
        unless $response->is_success;

    my $content    = $response->content;
    my @lines      = split("\n", $content);
    my $rates      = { ground => {}, air => {} };
    my %type_regex = (
        'ground' =>
            qr{<STRONG>Ground<BR></STRONG>Through(?:\s|&nbsp;)(\w+) (\d+), (\d+): (\d+\.?\d?\d?)%<BR>Effective(?:\s|&nbsp;)(\w+)(?:\s|&nbsp;)(\d+), (\d+): (\d+\.?\d?\d?)%},
        'air' =>
            qr{<STRONG>Air and International<BR></STRONG>Through(?:\s|&nbsp;)(\w+)(?:\s|&nbsp;)(\d+), (\d+): (\d+\.?\d?\d?)%<BR>Effective(?:\s|&nbsp;)(\w+) (\d+), (\d+): (\d+\.?\d?\d?)%},
    );

    foreach my $line (@lines) {
        while (my ($service_type, $regex) = each %type_regex) {
            if ($line =~ m|$regex|) {

                #print "Match!  line = $line";
                my %through;
                my %effective;
                @through{qw| month day year rate |}   = ($1, $2, $3, $4);
                @effective{qw| month day year rate |} = ($5, $6, $7, $8);
                $rates->{$service_type}->{through}    = \%through;
                $rates->{$service_type}->{effective} = \%effective;
            }
        }
    }

    #print "INFO: $gt_month, $gt_day, $gt_year, $gt_rate\n$at_month, ";
    #print "$at_day, $at_year, $at_rate\n\n";

    #print Dumper( $rates );

    # convert month names ('December') to the number
    my @month_names = qw(
        January February March April May June July
        August October September November December
    );

    #print "ground through month = $rates->{ground}{through}{month}\n";
    foreach my $service_type ('ground', 'air') {
        foreach my $date_type ('through', 'effective') {

            # cur = current date and rate hash.
            if (!defined $rates->{$service_type}) {
                die "Could not find '$service_type'.";
                next;
            }
            if (!defined $rates->{$service_type}{$date_type}) {
                die "Found '$service_type', but could not find '$date_type'";
                next;
            }

            my %cur = %{ $rates->{$service_type}{$date_type} };

            my $found_month;
            for my $c (0 .. $#month_names) {
                if ($cur{month} eq $month_names[$c]) {

                    $cur{month} = $c + 1
                        ; # Add one because we don't count months from 0 in real life.
                    $found_month = 1;
                    last;
                }
            }
            die
                "Could not convert month name ($cur{month}) into the month number."
                unless $found_month;

            # Add leading zeros to month and day:
            $cur{month} = "0" . $cur{month} if length $cur{month} == 1;
            $cur{day}   = "0" . $cur{day}   if length $cur{day} == 1;

            $rates->{$service_type}{$date_type} = \%cur;
        }
    }

    #print Dumper( $rates );

    my $ground_through_date
        = join('', @{ $rates->{ground}{through} }{qw| year month day |});
    my $ground_through_rate = $rates->{ground}{through}{rate};
    my $ground_effective_date
        = join('', @{ $rates->{ground}{effective} }{qw| year month day |});
    my $ground_effective_rate = $rates->{ground}{effective}{rate};
    my $air_through_date
        = join('', @{ $rates->{air}{through} }{qw| year month day |});
    my $air_through_rate = $rates->{air}{through}{rate};
    my $air_effective_date
        = join('', @{ $rates->{air}{effective} }{qw| year month day |});
    my $air_effective_rate = $rates->{air}{effective}{rate};

    my $new_rate_file
        = "Ground Fuel Surcharge: $ground_through_rate\n"
        . "Ground Good Through Date: $ground_through_date\n"
        . "Air and International Fuel Surcharge: $air_through_rate\n"
        . "Air and International Good Through Date: $air_through_date\n"
        . "Ground Effective Fuel Surcharge: $ground_effective_rate\n"
        . "Ground Effective Date: $ground_effective_date\n"
        . "Air and International Effective Fuel Surcharge: $air_effective_rate\n"
        . "Air and International Effective Date: $air_effective_date\n";

    print "Going to write new values:\n";
    print
        "==========================\n$new_rate_file==========================\n";

    writefile($fuel_surcharge_filename, $new_rate_file)
        or die "Could not write to $fuel_surcharge_filename";

    return;
}

=head2 * readfile( $file )

Note: this is not an object-oriented method.

=cut

sub readfile {
    my ($file) = @_;

    return undef unless open(READIN, "< $file");

    # TODO: Use English;

    undef $/;

    my $contents = <READIN>;
    close(READIN);

    return $contents;
}

=head2 * writefile( $filename, $filecontents )

Note: this is not an object-oriented method.

=cut

sub writefile {
    my ($filename, $contents) = @_;

    return unless open(OUT, "> $filename");

    # TODO: Use English;

    undef $/;

    print OUT $contents;

    return $contents;
}

1;

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
