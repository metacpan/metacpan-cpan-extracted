#!/bin/perl -w

use strict;

use Test::More ( tests=>22 );
use Data::Tabular::Dumper;

pass( 'loaded' );

my %params=(CSV=>["t/test.csv", {eol=>"\n", binary=>1}], 
            XML=>["t/test.xml", "table", "record" ],
            Excel=>["t/test.xls"]);

my $allowed=Data::Tabular::Dumper->available();

# no way this would happen ... :)
ok( (grep {$allowed->{$_}} keys %$allowed), "Got a list of data sinks" );

foreach my $w (qw(CSV XML Excel)) {
    my $dumper='';

    $dumper=Data::Tabular::Dumper->open($w=>$params{$w}) if $allowed->{$w};
    SKIP: {
        skip "$w support not available", 6 unless $dumper;

        pass( $w );
        ok( (-f $params{$w}[0]), "Created $params{$w}[0]" );

        ok( $dumper->fields([qw(one two three)]), "fields" );

        ok( $dumper->write([1..3]), "write" );

        $dumper->write([4..6]);
        $dumper->write([7..9]);
        
        ok( $dumper->write(["one,un","<b>deux</b>","+@[123]"]), 
                "write complex" );

        ok( $dumper->close, "close");
    }
}

SKIP: {
    skip "t/test.csv", 1 unless -f "t/test.csv";
    my @csv = eval {
        local @ARGV = "t/test.csv";
        <>;
    };
    is_deeply( \@csv, 
        [ qq(one,two,three\n), 
          qq(1,2,3\n),
          qq(4,5,6\n),
          qq(7,8,9\n),
          qq("one,un",<b>deux</b>,+@[123]\n)], 
        "t/test.csv good" );
}

SKIP: {
    skip "t/test.xml", 1 unless -f "t/test.xml";
    my @xml = eval {
        local @ARGV = "t/test.xml";
        <>;
    };
    is_deeply( \@xml, [
qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
qq(<table>\n),
qq(  <record>\n),
qq(    <one>1</one>\n),
qq(    <two>2</two>\n),
qq(    <three>3</three>\n),
qq(  </record>\n),
qq(  <record>\n),
qq(    <one>4</one>\n),
qq(    <two>5</two>\n),
qq(    <three>6</three>\n),
qq(  </record>\n),
qq(  <record>\n),
qq(    <one>7</one>\n),
qq(    <two>8</two>\n),
qq(    <three>9</three>\n),
qq(  </record>\n),
qq(  <record>\n),
qq(    <one>one,un</one>\n),
qq(    <two>&lt;b&gt;deux&lt;/b&gt;</two>\n),
qq(    <three>+@[123]</three>\n),
qq(  </record>\n),
qq(</table>\n) ], "t/test.xml good" );
}

foreach my $ext ( qw( csv xml xls ) ) {
    unlink( "t/test.$ext" );
}
