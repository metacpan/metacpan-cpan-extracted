use Test::More tests => 4;

use DateTime::Format::Bork;

{
    my $str = 
    "Bork Bork,,,Bork Bork Bork".
    "-,Bork Bork Bork Bork Bork Bork".
    "-Bork Bork,Bork Bork Bork".
    "T,".
    ":Bork Bork,Bork Bork Bork Bork Bork".
    ":Bork Bork,Bork";

    my $dt = DateTime::Format::Bork->debork( $str );
    is( $dt->iso8601, '2003-06-23T00:25:21' );
}

{
    my $str =
    "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
    "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
    "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
    "Bork Bork Bork Bork Bork Bork Bork Bork Bork".
    "-Bork,Bork Bork".
    "-Bork Bork Bork,Bork".
    "TBork Bork,Bork Bork Bork".
    ":Bork Bork Bork Bork Bork,Bork Bork Bork Bork Bork Bork Bork Bork Bork".
    ":Bork Bork Bork Bork Bork,Bork Bork Bork Bork Bork Bork Bork Bork Bork";

    my $dt = DateTime::Format::Bork->debork( $str );
    is( $dt->iso8601, '9999-12-31T23:59:59' );
}

{
    my $str =
        "-Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork,".
        "Bork Bork Bork Bork Bork Bork Bork Bork Bork".
        "-,Bork-,BorkT,:,:,";

    my $dt = DateTime::Format::Bork->debork( $str );
    is( $dt->iso8601, '-9999-01-01T00:00:00' );
}

{
    my $str = ",,,-,Bork-,BorkT,:,:,";

    my $dt = DateTime::Format::Bork->debork( $str );
    is( $dt->iso8601, '0000-01-01T00:00:00' );
}
