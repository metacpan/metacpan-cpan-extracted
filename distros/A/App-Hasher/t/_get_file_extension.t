use strict;
use warnings FATAL => 'all';
use feature 'say';
use utf8;
use open qw(:std :utf8);

use Test::More;

require './bin/hasher';

sub main_in_test {

    pass 'Loaded ok';

    my %tests = (
        'a.txt' => '.txt',
        'b.tXt' => '.txt',
        'c' => '',
        '/root/d.JPG' => '.jpg',
        '/root/e' => '',
        '/root/f.f.f' => '.f',
        './g' => '',
    );

    foreach my $file_name (sort keys %tests) {
        is(
            _get_file_extension($file_name),
            $tests{$file_name},
            sprintf("%s => '%s'", $file_name, $tests{$file_name}),
        );
    }

    done_testing();
}
main_in_test();
