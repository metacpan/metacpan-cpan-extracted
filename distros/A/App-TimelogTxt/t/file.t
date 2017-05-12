#!/usr/bin/perl

use Test::Most tests => 47;
use Test::NoWarnings;

use App::TimelogTxt::File;

throws_ok { App::TimelogTxt::File->new(); } qr/required file handle/, 'Handles missing file handle';
throws_ok { App::TimelogTxt::File->new( 'file', ); } qr/required start/, 'Handles missing start marker';
throws_ok { App::TimelogTxt::File->new( 'file', '2012/06/07' ); } qr/required end/, 'Handles missing end';

my $filebuffer = <<EOF;
2012/05/30  junk
2012/05/30  junk
2012/05/30  junk
2012/05/30  junk
2012/05/30  junk
2012/05/30  junk
2012/05/30  junk
2012/06/01  friday 1
2012/06/01  friday 2
2012/06/04  monday 1
2012/06/04  monday 2
2012/06/05  tuesday 1
2012/06/05  tuesday 2
2012/06/06  wednesday 1
2012/06/06  wednesday 2
2012/06/07  thursday 1
2012/06/07  thursday 2
2012/06/08  final
EOF

{
    my $label = 'before';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2011/06/01', '2011/06/05' );

    ok( !defined $file->readline, "$label: Report file end on end tag" );
}

{
    my $label = 'after';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/07/01', '2012/07/05' );

    ok( !defined $file->readline, "$label: Report file end on end tag" );
}

{
    my $label = 'friday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/01', '2012/06/02' );

    is( $file->readline, "2012/06/01  friday 1\n", "$label: Correct first line" );
    is( $file->readline, "2012/06/01  friday 2\n", "$label: Correct second line" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'friday-monday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/01', '2012/06/05' );

    is( $file->readline, "2012/06/01  friday 1\n", "$label: Correct first line" );
    is( $file->readline, "2012/06/01  friday 2\n", "$label: Correct second line" );
    is( $file->readline, "2012/06/04  monday 1\n", "$label: Not on first tag" );
    is( $file->readline, "2012/06/04  monday 2\n", "$label: Still not on first tag" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'saturday-monday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/02', '2012/06/05' );

    is( $file->readline, "2012/06/04  monday 1\n", "$label: After first tag" );
    is( $file->readline, "2012/06/04  monday 2\n", "$label: Still after first tag" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'saturday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/02', '2012/06/03' );

    is( $file->readline, undef, "$label: Report file end on end tag" );
}

{
    my $label = 'sunday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/03', '2012/06/04' );

    is( $file->readline, undef, "$label: Report file end on end tag" );
}

{
    my $label = 'monday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/04', '2012/06/05' );

    is( $file->readline, "2012/06/04  monday 1\n", "$label: After first tag" );
    is( $file->readline, "2012/06/04  monday 2\n", "$label: Still after first tag" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'tuesday-wednesday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/05', '2012/06/07' );

    is( $file->readline, "2012/06/05  tuesday 1\n", "$label: Tuesday 1" );
    is( $file->readline, "2012/06/05  tuesday 2\n", "$label: Tuesday 2" );
    is( $file->readline, "2012/06/06  wednesday 1\n", "$label: Wednesday 1" );
    is( $file->readline, "2012/06/06  wednesday 2\n", "$label: Wednesday 2" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'monday-thursday';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/04', '2012/06/08' );

    is( $file->readline, "2012/06/04  monday 1\n", "$label: Monday 1" );
    is( $file->readline, "2012/06/04  monday 2\n", "$label: Monday 2" );
    is( $file->readline, "2012/06/05  tuesday 1\n", "$label: Tuesday 1" );
    is( $file->readline, "2012/06/05  tuesday 2\n", "$label: Tuesday 2" );
    is( $file->readline, "2012/06/06  wednesday 1\n", "$label: Wednesday 1" );
    is( $file->readline, "2012/06/06  wednesday 2\n", "$label: Wednesday 2" );
    is( $file->readline, "2012/06/07  thursday 1\n", "$label: Thursday 1" );
    is( $file->readline, "2012/06/07  thursday 2\n", "$label: Thursday 2" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

{
    my $label = 'thursday-end';
    open( my $fh, '<', \$filebuffer ) or die "Failed to make fake filehandle\n";
    my $file = App::TimelogTxt::File->new( $fh, '2012/06/07', '2012/06/10' );

    is( $file->readline, "2012/06/07  thursday 1\n", "$label: Thursday 1" );
    is( $file->readline, "2012/06/07  thursday 2\n", "$label: Thursday 2" );
    is( $file->readline, "2012/06/08  final\n", "$label: Friday 2" );
    ok( !defined $file->readline, "$label: Report file end on end tag" );
    ok( !defined $file->readline, "$label:  ... For ever after" );
}

