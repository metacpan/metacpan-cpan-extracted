package t::lib::helper;

use strict;
use warnings;

use Test::More;

use DateTime::Format::Flexible;

my $dff = 'DateTime::Format::Flexible';

sub run_tests
{
    my $opts = [];
    if ( ref( $_[0] ) eq 'ARRAY' )
    {
        $opts = shift @_;
    }
    foreach ( @_ )
    {
        my ( $line ) = $_ =~ m{([^\n]+)};
        next if not $line;
        next if $line =~ m{\A\#}mx; # skip comments
        next if $line =~ m{\A\z}mx; # skip blank lines
        my ( $given , $wanted , $tz ) = split m{\s+=>\s+}mx , $line;
        compare( $given , $wanted , $tz, $opts );
    }
}

sub run_tests_time_parse_date
{
    my $opts = [];
    if ( ref( $_[0] ) eq 'ARRAY' )
    {
        $opts = shift @_;
    }

    TEST: while ( @_ )
    {
        my $wanted = shift;
        my $ar = shift;
        my $given = shift @$ar;

        my %setup_opts = @$ar;

        # don't support subsecond tests
        next TEST if (defined $setup_opts{SUBSECOND});

        if (defined $setup_opts{NOW})
        {
            my $base_dt = DateTime->from_epoch(epoch => $setup_opts{NOW});
            $dff->base( $base_dt );
        }
        if (defined $setup_opts{UK})
        {
            push @$opts, european => 1;
        }

        my $wanted_dt = DateTime->from_epoch(epoch => $wanted);

        my $dt = $dff->parse_datetime( $given, @$opts );
        if (defined $setup_opts{ZONE})
        {
            if ($setup_opts{ZONE} eq 'EDT')
            {
                $setup_opts{ZONE} = 'America/New_York';
            }
            if ($setup_opts{ZONE} =~ m{PDT|PST})
            {
                $setup_opts{ZONE} = 'America/Los_Angeles';
            }
            $dt->set_time_zone($setup_opts{ZONE});
        }
        else
        {
            $dt->set_time_zone('America/Los_Angeles');
        }

        is ($dt->epoch, $wanted, "$given => $wanted (given: $dt => wanted: $wanted_dt)");
    }
}

sub compare
{
    my ( $given , $wanted , $tz, $opts ) = @_;
    my $dt = $dff->parse_datetime( $given, @$opts );
    is( $dt->datetime , $wanted , "$given => $wanted" );
    if ( $tz )
    {
        is( $dt->time_zone->name , $tz , "timezone => $tz" );
    }
}

1;
