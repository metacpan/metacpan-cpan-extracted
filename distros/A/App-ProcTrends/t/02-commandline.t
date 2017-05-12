#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok( 'App::ProcTrends::Commandline' ) || print "Bail out!\n";
}

diag( "Testing App::ProcTrends::Commandline $App::ProcTrends::Commandline::VERSION, Perl $], $^X" );

test_new();
test_generate_table_data();
test_list();
test_img();
done_testing();

sub test_new {
    my $obj;
    lives_ok { $obj = App::ProcTrends::Commandline->new(); } "constructor without params";
}

sub test_generate_table_data {
    # command can be: list, img, help, or none (defaults to 'table' command)
    my $ref = {
        start       => "-1d",
        end         => "now",
        interval    => 30,
        procs       => "firefox,java_orgeclipseequi",
        rrd_dir      => "$Bin/test_data/commandline",
    };

    my $obj;
    lives_ok { $obj = App::ProcTrends::Commandline->new( $ref ); } "constructor for test_table";
    is( $obj->rrd_dir(), "$Bin/test_data/commandline", "checking rrd_dir" );
    is( $obj->procs(), "firefox,java_orgeclipseequi", "checking procs" );
    
    my $command = $obj->command();
    is( $command, "table", "table command is returned" );
    
    my $handler = "${command}_handler";
    can_ok( $obj, $handler );
    $obj->$handler();
}

sub test_list {
    my $ref = {
        command     => 'list',
        procs       => "firefox,java_orgeclipseequi", # dummy.  list command doesn't care
        rrd_dir      => "$Bin/test_data/commandline",
    };

    my $obj;
    lives_ok { $obj = App::ProcTrends::Commandline->new( $ref ); } "constructor for test_list";
    
    my $command = $obj->command();
    is( $command, "list", "list command is returned" );
    
    my $handler = "${command}_handler";
    can_ok( $obj, $handler ); # no comment allowed as it becomes an arg to can_ok
    $obj->$handler();
}

sub test_img {
     my $ref = {
        command     => 'img',
        procs       => "firefox,java_orgeclipseequi",
        rrd_dir      => "$Bin/test_data/commandline",
        out_dir      => "$Bin/test_data/commandline/img",
    };

    my $obj;
    lives_ok { $obj = App::ProcTrends::Commandline->new( $ref ); } "constructor for test_img";
    
    my $command = $obj->command();
    is( $command, "img", "img method is returned" );
    
    my $handler = "${command}_handler";
    can_ok( $obj, $handler );
    $obj->$handler();

    my $count = 0;
    opendir( my $dh, $ref->{ out_dir } );
    while( my $file = readdir $dh ) {
        $count++ if ( $file =~ /\.png$/ );
    }
    close $dh;
    
    cmp_ok( $count, ">=", 1, "testing if images are found" );
    system( "rm", "-rf", $ref->{ out_dir } );
    is( $?, 0, "cleaning up" );
}
