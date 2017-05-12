package DateTime::Format::Bork;

use strict;

use vars qw( $VERSION );
$VERSION = '0.02';

use DateTime::Format::Builder(
    parsers => {
        debork => [
        {
            regex => qr/^
               ( -? (?:Bork\s*){0,9} , (?:Bork\s*){0,9}
                  , (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
                - ( (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
                - ( (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
                T ( (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
                : ( (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
                : ( (?:Bork\s*){0,9} , (?:Bork\s*){0,9} )
            $/ix,
            params => [ qw( year month day hour minute second ) ],
            postprocess => \&_unbork,
            extra => { time_zone => 'UTC' },
        },
        ],
    }
);

sub bork {
    my( $self, $dt ) = @_;

    $dt = $dt->clone->set_time_zone( 'UTC' );

    my $borking;
    $borking .= _bork( sprintf( "%04d", $dt->year ) ) . "-";
    $borking .= _bork( sprintf( "%02d", $dt->month ) ) . "-";
    $borking .= _bork( sprintf( "%02d", $dt->day ) ) . "T";
    $borking .= _bork( sprintf( "%02d", $dt->hour ) ) . ":";
    $borking .= _bork( sprintf( "%02d", $dt->minute ) ) . ":";
    $borking .= _bork( sprintf( "%02d", $dt->second ) );

    return $borking;
}

sub _unbork {
    my %p = @_;

    foreach my $key ( keys %{ $p{ parsed } } ) {
        $p{ parsed }{ $key } = _count_bork( $p{ parsed }{ $key } );
    }

    return 1;
}

sub _count_bork {
    my $borked = shift;
    
    my $neg;
    if ( $borked =~ s/-// ) {
        $neg = 1;    
    }    

    my @digits = split( /,/, $borked );

    my $n;
    foreach ( @digits ) {
        $n .= my @count = $_ =~ /(Bork)/ig;
    }

    if( $neg ) {
        $n *= -1;
    }

    if ( defined $n ) {
        return $n;
    } else {
        return 0;
    }
}

sub _bork {
    my $prebork = shift;

    my $neg;
    if ( $prebork =~ s/-// ) {
        $neg = "-";    
    }    

    my @digits = split( //, $prebork );

    my( $postbork, $i ) = $neg;
    foreach ( @digits ) {
        if ( $_ ) {
            $postbork .= "Bork " x ( $_ - 1 ) . "Bork";
        }

        $i++;
    } continue {
        if ( $i < @digits ) {
            $postbork .= ",";
        }
    } 

    return $postbork;
}

1;

__END__
