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
        block => {
            name => 'restart',
            desc => 'restart the server',
        },
        block_path  => [ qw( server restart ) ],
        title       => 'Ensure we find the correct block',
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
    cmp_deeply $app->resolve_block( $test->{block_path} ), $test->{block}, sprintf( "line %d: %s", $test->{line}, $test->{title} ); 
}

done_testing();
