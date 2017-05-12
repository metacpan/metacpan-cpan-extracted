use Test::More tests => 4;

use DateTime::Format::Bork;

{
    my $dt = DateTime->new(
        year    => 2003,
        month   => 06,
        day     => 23,
        hour    => 00,
        minute  => 25,
        second  => 21,
    );

    my $str = DateTime::Format::Bork->bork( $dt );
    is(
        $str,
        "Bork Bork,,,Bork Bork Bork".
        "-,Bork Bork Bork Bork Bork Bork".
        "-Bork Bork,Bork Bork Bork".
        "T,".
        ":Bork Bork,Bork Bork Bork Bork Bork".
        ":Bork Bork,Bork"
    );
}

{
    my $dt = DateTime->new(
        year   => 9999,
        month  => 12,
        day    => 31,
        hour   => 23,
        minute => 59,
        second => 59,
    );

    my $str = DateTime::Format::Bork->bork( $dt );
    is(
        $str,
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork".
        "-Bork,Bork Bork".
        "-Bork Bork Bork,Bork".
        "TBork Bork,Bork Bork Bork".
        ":Bork Bork Bork Bork Bork,Bork Bork Bork Bork Bork Bork Bork Bork Bork".
        ":Bork Bork Bork Bork Bork,Bork Bork Bork Bork Bork Bork Bork Bork Bork"
    );
}

{
    my $dt = DateTime->new(
        year   => -9999,
        month  => 01,
        day    => 01,
        hour   => 00,
        minute => 00,
        second => 00,
    );

    my $str = DateTime::Format::Bork->bork( $dt );
    is(
        $str,
        "-Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork".
        "-,Bork-,BorkT,:,:,"
    );
}

{
    my $dt = DateTime->new(
        year   => 0000,
        month  => 01,
        day    => 01,
        hour   => 00,
        minute => 00,
        second => 00,
    );

    my $str = DateTime::Format::Bork->bork( $dt );
    is( $str, ",,,-,Bork-,BorkT,:,:," );
}
