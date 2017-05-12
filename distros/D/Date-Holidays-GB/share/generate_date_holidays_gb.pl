#!/usr/bin/perl

# script to update Date::Holidays::GB with the latest bank holiday dates from
# http://www.gov.uk/bank-holidays

use strict;
use warnings;

use Cwd qw( realpath );
use DateTime;
use File::Spec::Functions qw( catfile splitpath updir );
use JSON;
use LWP::Simple qw/ get /;
use Time::Local();

my $URL = 'http://www.gov.uk/bank-holidays.json';

my %CODE = (
    'england-and-wales' => 'EAW',
    'scotland'          => 'SCT',
    'northern-ireland'  => 'NIR',
);

write_file( get_dates( download_json() ) );

exit;

sub download_json {

    my $contents = get $URL or die "Can't download $URL";

    return decode_json($contents);
}

sub get_dates {

    my $data = shift;

    my %holiday;

    foreach my $region ( keys %{$data} ) {

        foreach my $event ( @{ $data->{$region}->{events} } ) {

            $holiday{ $event->{date} }->{ $CODE{$region} } = $event->{title};

        }
    }

    return %holiday;
}

sub write_file {
    my %holiday = @_;

    my $file = catfile( ( splitpath( realpath __FILE__ ) )[ 0, 1 ],
        updir, qw(lib Date Holidays GB.pm) );

    open my $READ, '<:encoding(utf-8)', $file
        or die "Unable to open $file for reading: $!";

    my $contents = do { local $/; <$READ> };

    close $READ;

    open my $WRITE, '>:encoding(utf-8)', $file
        or die "Unable to open $file for writing: $!";

    # ditch __DATA__ section
    my ($pm,undef) = split /__DATA__/, $contents;

    my $now = DateTime->now->ymd;

    $pm =~ s/sub date_generated \{[^}]+\}/sub date_generated { '$now' }/;

    print $WRITE $pm;
    print $WRITE "__DATA__\n";
    print $WRITE holiday_data( %holiday );

    close $WRITE;
}

sub holiday_data {
    my %holiday = @_;

    my $data;
    foreach my $date ( sort keys %holiday ) {
        foreach my $code ( sort keys %{ $holiday{$date} } ) {
            $data .= sprintf( "%s\t%s\t%s\n",
                $date, $code, $holiday{$date}->{$code} );
        }
    }

    return $data;
}

1;

