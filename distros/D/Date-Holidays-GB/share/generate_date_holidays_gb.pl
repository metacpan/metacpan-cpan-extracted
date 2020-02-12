#!/usr/bin/perl

# script to update Date::Holidays::GB with the latest bank holiday dates from
# http://www.gov.uk/bank-holidays

use strict;
use warnings;

use Cwd qw( realpath );
use DateTime;
use File::Spec::Functions qw( catfile splitpath updir );
use JSON qw(decode_json);
use List::Util qw( uniq );
use LWP::Simple qw/ get /;
use Time::Local ();

my $URL = 'http://www.gov.uk/bank-holidays.json';

my %CODE = (
    'england-and-wales' => 'EAW',
    'scotland'          => 'SCT',
    'northern-ireland'  => 'NIR',
);

write_file( get_dates( download_json() ) );

exit;

sub file {
    return catfile( ( splitpath( realpath __FILE__ ) )[ 0, 1 ],
        updir, qw(lib Date Holidays GB.pm) );
}

sub download_json {

    my $contents = get $URL or die "Can't download $URL";

    return decode_json($contents);
}

sub get_dates {

    my $data = shift;

    my %holiday;

    foreach my $region ( keys %{$data} ) {

        foreach my $event ( @{ $data->{$region}->{events} } ) {

            my ($year) = split /-/, $event->{date};

            $holiday{$year}->{ $event->{date} }->{ $CODE{$region} } = $event->{title};
        }
    }

    return \%holiday;
}

sub read_file {

    my $file = file();

    open my $READ, '<:encoding(utf-8)', $file
        or die "Unable to open $file for reading: $!";

    my $contents = do { local $/; <$READ> };

    close $READ;

    my ( $pm, $data ) = split /__DATA__/, $contents;

    return ( $pm, $data );
}
/usr/local/bin/bash: perltidy: command not found

sub parse_existing {
    my ($data) = @_;

    my %parsed;
    my @lines = split /\n/, $data;
    foreach my $line (@lines) {
        next unless $line && $line =~ /\w/;
        my ( $date, $code, $name ) = split /\t/, $line;

        my ($year) = split /-/, $date;

        $parsed{$year}->{$date}->{$code} = $name;
    }

    return \%parsed;
}

sub holiday_data {
    my ( $existing, $new ) = @_;

    my @years = uniq keys %{$existing}, keys %{$new};

    my $data;
    foreach my $year (sort @years) {

        # include old data, if removed from current download
        my $source = $new->{$year} ? $new->{$year} : $existing->{$year};

        foreach my $date ( sort keys %{$source} ) {
            foreach my $code ( sort keys %{ $source->{$date} } ) {
                $data
                    .= sprintf( "%s\t%s\t%s\n", $date, $code, $source->{$date}->{$code} );
            }
        }
    }

    return $data;
}

1;

