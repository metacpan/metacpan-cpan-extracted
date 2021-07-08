package DateTime::Format::Flexible::lang;

use strict;
use warnings;

use List::MoreUtils 'any';

sub new
{
    my ( $class , %params ) = @_;
    my $self = bless \%params , $class;

    if ($self->{lang} and not ref($self->{lang}) eq 'ARRAY')
    {
        $self->{lang} = [$self->{lang}];
    }

    $self->{_plugins} = [
        'DateTime::Format::Flexible::lang::de',
        'DateTime::Format::Flexible::lang::en',
        'DateTime::Format::Flexible::lang::es',
    ];

    foreach my $plugin (@{$self->{_plugins}}) {
        my $path   = $plugin . ".pm";
        $path =~ s{::}{/}g;
        require $path;
    }
    return $self;
}

sub plugins {return @{$_[0]->{_plugins}}}

sub _cleanup
{
    my ( $self , $date , $p ) = @_;
    foreach my $plug ( $self->plugins )
    {
        if ( $self->{lang} )
        {
            my ( $lang ) = $plug =~ m{(\w{2}\z)}mx;
            if ( not any { $_ eq $lang } @{ $self->{lang} } )
            {
                printf( "# skipping %s\n", $plug ) if $ENV{DFF_DEBUG};
                next;
            }
        }
        printf( "# not skipping %s\n", $plug ) if $ENV{DFF_DEBUG};

        printf( "#   before math: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_do_math( $plug , $date );
        printf( "#   before string_dates: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_string_dates( $plug , $date );
        printf( "#   before fix_alpha_month: %s\n", $date ) if $ENV{DFF_DEBUG};
        ( $date , $p ) = $self->_fix_alpha_month( $plug , $date , $p );
        printf( "#   before remove_day_names: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_remove_day_names( $plug , $date );
        printf( "#   before fix_hours: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_fix_hours( $plug , $date );
        printf( "#   before remove_strings: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_remove_strings( $plug , $date );
        printf( "#   before locate_time: %s\n", $date ) if $ENV{DFF_DEBUG};
        $date = $self->_locate_time( $plug , $date );
        printf( "#   before fix_internal_tz: %s\n", $date ) if $ENV{DFF_DEBUG};
        ( $date , $p ) = $self->_fix_internal_tz( $plug , $date , $p );
        printf( "#   finished: %s\n", $date ) if $ENV{DFF_DEBUG};
    }
    return ( $date , $p );
}

sub _fix_internal_tz
{
    my ( $self , $plug , $date , $p ) = @_;
    my %tzs = $plug->timezone_map;
    while( my( $orig_tz , $new_tz ) = each ( %tzs ) )
    {
        if( $date =~ m{$orig_tz}mxi )
        {
            $p->{ time_zone } = $new_tz;
            $date =~ s{$orig_tz}{}mxi;
            $date =~ s{\(\)}{}g; # remove empty parens
            return ( $date , $p );
        }
    }
    return ( $date , $p );
}

sub _do_math
{
    my ( $self , $plug , $date ) = @_;

    my %relative_strings = $plug->relative;
    my $day_strings = $plug->days;
    my %month_strings = $plug->months;

    my $instructions = {
        ago  => {direction => 'past', units => 1},
        from => {direction => 'future', units => 1},
        last => {direction => 'past'},
        next => {direction => 'future'},
    };

    foreach my $keyword (keys %relative_strings)
    {
        my $rx = $relative_strings{$keyword};

        next if not (exists $instructions->{$keyword});

        my $has_units = $instructions->{$keyword}->{units};
        my $direction = $instructions->{$keyword}->{direction};

        if ( $date =~ m{$rx}mix )
        {
            $date =~ s{$rx}{}mix;
            if ($has_units)
            {
                $date = $self->_set_units( $plug , $date, $direction );
            }
            else
            {
                foreach my $set (@{$day_strings})
                {
                    foreach my $day (keys %{$set})
                    {

                        if ($date =~ m{$day}mix)
                        {
                            $date = $self->_set_day( $plug , $date , $day , $direction );
                            $date =~ s{$day}{}mix;
                        }
                    }
                }
                foreach my $month (keys %month_strings)
                {
                    if ($date =~ m{$month}mix)
                    {
                        $date = $self->_set_month( $plug , $date , $month , $direction );
                        $date =~ s{$month}{}mix;
                    }
                }
            }
            printf("#  after removing rx (%s): [%s]\n", $rx, $date) if $ENV{DFF_DEBUG};

            $date =~ s{$keyword}{}mx;
            $date =~ s{\s+}{ }gm;
            $date =~ s{\s+\z}{}gm;
            printf("#  after removing keyword (%s): [%s]\n", $keyword, $date) if $ENV{DFF_DEBUG};
        }

    }

    return $date;
}

sub _set_units
{
    my ( $self , $plug , $date , $direction ) = @_;

    my %strings = $plug->math_strings;
    if ( my ( $amount , $unit ) = $date =~ m{(\d+)\s+([^\s]+)}mx )
    {
        printf( "#  %s => %s\n", $amount, $unit ) if $ENV{DFF_DEBUG};
        if ( exists( $strings{$unit} ) )
        {
            my $base_dt = DateTime::Format::Flexible->base->clone;

            if ( $direction eq 'past' )
            {
                $base_dt->subtract( $strings{$unit} => $amount );
            }
            if ( $direction eq 'future' )
            {
                $base_dt->add( $strings{$unit} => $amount );
            }
            $date =~ s{\s{0,}$amount\s+$unit\s{0,}}{}mx;

            if ($ENV{DFF_DEBUG})
            {
                printf("#  found: %s\n", $strings{$unit}) ;
                printf("#  after removing amount, unit: [%s]\n", $date);
            }

            $date = $base_dt->datetime . ' ' . $date;
        }
    }

    return $date;
}

sub _set_day
{
    my ( $self , $plug , $date , $day , $direction ) = @_;

    my $base_dt = DateTime::Format::Flexible->base->clone;
    my $dow = $base_dt->day_of_week;
    my $date_dow = $self->_alpha_day_to_int($plug, $day);

    if ( $direction eq 'past' )
    {
        my $amount = $dow - $date_dow;
        if ($amount < 1) {$amount = 7 + $amount}
        printf("#    subtracting %s days\n", $amount) if $ENV{DFF_DEBUG};

        my $ret = $base_dt->subtract( 'days' => $amount )->truncate( to => 'day' );
        $date = $ret->datetime . ' ' . $date;

    }
    if ( $direction eq 'future' )
    {
        my $amount = $date_dow - $dow;
        if ($amount < 1) {$amount = 7 + $amount}
        printf("#    adding %s days\n", $amount) if $ENV{DFF_DEBUG};

        my $ret = $base_dt->add( 'days' => $amount )->truncate( to => 'day' );
        $date = $ret->datetime . ' ' . $date;
    }


    return $date;
}

sub _set_month
{
    my ( $self , $plug , $date , $month , $direction ) = @_;

    my %month_strings = $plug->months;

    my $base_dt = DateTime::Format::Flexible->base->clone;
    my $mon = $base_dt->month;
    my $date_mon = $month_strings{$month};

    printf("#    setting month to: %s\n", $date_mon) if $ENV{DFF_DEBUG};

    $base_dt->set_month($date_mon);
    if ($direction eq 'past' and $date_mon >= $mon)
    {
        $base_dt->set_year($base_dt->year - 1);
    }
    if ($direction eq 'future' and $date_mon <= $mon)
    {
        $base_dt->set_year($base_dt->year + 1);
    }
    $base_dt->truncate( to => 'month' );
    printf("#    set year to: %s\n", $base_dt->year) if $ENV{DFF_DEBUG};

    $date = $base_dt->datetime . ' ' . $date;

    return $date;
}

sub _string_dates
{
    my ( $self , $plug , $date ) = @_;
    my %strings = $plug->string_dates;
    foreach my $key ( keys %strings )
    {
        if ( $date =~ m{\Q$key\E}mxi )
        {
            my $new_value = $strings{$key}->();
            $date =~ s{\Q$key\E}{$new_value}mix;
        }
    }

    my %day_numbers = $plug->day_numbers;
    foreach my $key ( keys %day_numbers )
    {
        if (index(lc($date), lc($key)) >= 0)
        {
            my $new_value = $day_numbers{$key};
            $date =~ s{$key}{n${new_value}n}mix;
        }
    }
    return $date;
}

# turn month names into month numbers with surrounding X
# Sep => X9X
sub _fix_alpha_month
{
    my ( $self , $plug , $date , $p ) = @_;
    my %months = $plug->months;
    while( my( $month_name , $month_number ) = each ( %months ) )
    {
        if( $date =~ m{\b$month_name\b}mxi )
        {
            $p->{ month } = $month_number;
            $date =~ s{\b$month_name\b}{X${month_number}X}mxi;

            return ( $date , $p );
        }
        elsif ( $date =~ m{\d$month_name}mxi )
        {
            $p->{ month } = $month_number;
            $date =~ s{(\d)$month_name}{$1X${month_number}X}mxi;

            return ( $date , $p );
        }

        elsif( $date =~ m{\b$month_name\d.*\b}mxi )
        {
            $p->{ month } = $month_number;
            $date =~ s{\b$month_name(\d.*)\b}{X${month_number}X$1}mxi;

            return ( $date , $p );
        }
    }
    return ( $date , $p );
}

# remove any day names, we do not need them
sub _remove_day_names
{
    my ( $self , $plug , $date ) = @_;
    my $days = $plug->days;
    foreach my $set (@{$days})
    {
        foreach my $day_name ( keys %{$set} )
        {
            # if the day name is by itself, make it the upcoming day
            # eg: monday = next monday
            if (( lc($date) eq lc($day_name)) or (index(lc($date), lc($day_name) . ' at') >= 0 ))
            {
                my $dt = $self->{base}->clone->truncate( to => 'day' );
                my $date_dow = $set->{$day_name};

                if ( $date_dow == $dt->dow )
                {
                    my $str = $dt->ymd;
                    $date =~ s{$day_name}{$str}i;
                    return $date;
                }
                elsif ( $date_dow > $dt->dow )
                {
                    $dt->add( days => $date_dow - $dt->dow );
                    my $str = $dt->ymd;
                    $date =~ s{$day_name}{$str}i;
                    return $date;
                }
                else
                {
                    $dt->add( days => $date_dow - $dt->dow + 7 );
                    my $str = $dt->ymd;
                    $date =~ s{$day_name}{$str}i;
                    return $date;
                }
            }
            # otherwise, just strip it out
            if ( $date =~ m{\b$day_name\b}mxi )
            {
                $date =~ s{$day_name,?}{}gmix;
                return $date;
            }
        }
    }
    return $date;
}

sub _alpha_day_to_int
{
    my ( $self, $plug, $day ) = @_;

    my $day_strings = $plug->days;
    foreach my $set (@{$day_strings})
    {
        foreach my $key (keys %{$set})
        {
            if (lc($key) eq lc($day))
            {
                return $set->{$key};
            }
        }
    }
    return;
}

# fix noon and midnight, named hours
sub _fix_hours
{
    my ( $self , $plug , $date ) = @_;
    my %hours = $plug->hours;
    foreach my $hour ( keys %hours )
    {
        if ( $date =~ m{$hour}mxi )
        {
            my $realtime = $hours{ $hour };
            $date =~ s{T[^\s]+}{};
            $date =~ s{$hour}{${realtime}}gmix;
            return $date;
        }
    }
    return $date;
}

sub _remove_strings
{
    my ( $self , $plug , $date ) = @_;
    my @rs = $plug->remove_strings;
    foreach my $rs ( @rs )
    {
        if ( $date =~ m{$rs}mxi )
        {
            printf( "#     removing string: %s\n", $rs ) if $ENV{DFF_DEBUG};

            $date =~ s{$rs}{ }gmix;
        }
    }
    $date =~ s{\A\s+}{};
    $date =~ s{\s+\z}{};

    return $date;
}

sub _locate_time
{
    my ( $self , $plug , $date ) = @_;
    $date = $plug->parse_time( $date );
    return $date;
}

1;

__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Flexible::lang - base language module to handle plugins for DateTime::Format::Flexible.

=head1 DESCRIPTION

You should not need to use this module directly

=head2 new

Instantiate a new instance of this module.

=head2 plugins

Returns a list of available language plugins.

=head1 AUTHOR

    Tom Heady
    CPAN ID: thinc
    Punch, Inc.
    cpan@punch.net
    http://www.punch.net/

=head1 COPYRIGHT & LICENSE

Copyright 2011 Tom Heady.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

=item * the Artistic License.

=back

=head1 SEE ALSO

F<DateTime::Format::Flexible>

=cut
