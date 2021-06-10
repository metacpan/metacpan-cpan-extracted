#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Test::Deep;
use App::Dex;
use File::Temp;


my $tests = [
    {
        content => [
            '---',
            '- name: hello',
            '  desc: this is a command description',
        ],
        menu => [
            {
                name  => "hello",
                desc  => "this is a command description",
                depth => 0,
            },

        ],
        title       => 'Test a single name/desc entry for the menu.',
        line        => __LINE__,
    },
    {
        content => [
            '---',
            '- name: server',
            '  desc: control the server',
            '  children:',
            '  - name: start',
            '    desc: start the server',
            '  - name: stop',
            '    desc: stop the server',
            '  - name: restart',
            '    desc: restart the server',
        ],
        menu => [
            {
                name  => "server",
                desc  => "control the server",
                depth => 0,
            },
            {
                name  => "start",
                desc  => "start the server",
                depth => 1,
            },
            {
                name  => "stop",
                desc  => "stop the server",
                depth => 1,
            },
            {
                name  => "restart",
                desc  => "restart the server",
                depth => 1,
            },

        ],
        title       => 'Test a single name/desc entry with three children',
        line        => __LINE__,
    },
];

foreach my $test ( @{$tests} ) {
    my $file = File::Temp->new( unlink => 1 );

    foreach my $line ( @{$test->{content}} ) {
        print $file "$line\n";
    }
    close($file); # Write the file

    ok my $app = App::Dex->new( config_file_names => [ $file->filename ] ), sprintf( "line %d: %s", $test->{line}, "Object Construction" );

    cmp_deeply $app->menu, $test->{menu}, sprintf( "line %d: %s", $test->{line}, $test->{title} );
}

done_testing();
