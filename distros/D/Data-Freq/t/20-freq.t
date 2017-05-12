#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Data::Freq;

my $root_value = $Data::Freq::ROOT_VALUE;

subtest single => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new();
    
    $data->add('foo');
    $data->add('bar');
    $data->add('foo');
    $data->add('baz');
    $data->add('foo');
    $data->add('bar');
    $data->add('foo');
    
    my @result;
    $data->output(sub {push @result, $_[0]});
    
    is_deeply([map {$result[0]->$_} qw(value count depth)], [$root_value, 7, 0]);
    is_deeply([map {$result[1]->$_} qw(value count depth)], ['foo', 4, 1]);
    is_deeply([map {$result[2]->$_} qw(value count depth)], ['bar', 2, 1]);
    is_deeply([map {$result[3]->$_} qw(value count depth)], ['baz', 1, 1]);
};

subtest number => sub {
    plan tests => 5;
    
    my $data = Data::Freq->new({type => 'number', sort => 'value'});
    
    $data->add(1);
    $data->add(10);
    $data->add(11);
    $data->add(2);
    
    my @result;
    $data->output(sub {push @result, $_[0]});
    my $i = 0;
    
    is_deeply([map {$result[$i]->$_} qw(value count depth)], [$root_value, 4, 0]); $i++;
    {
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [1, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [2, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [10, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [11, 1, 1]); $i++;
    }
};

subtest text => sub {
    plan tests => 5;
    
    my $data = Data::Freq->new({type => 'text', sort => 'value'});
    
    $data->add(1);
    $data->add(10);
    $data->add(11);
    $data->add(2);
    
    my @result;
    $data->output(sub {push @result, $_[0]});
    my $i = 0;
    
    is_deeply([map {$result[$i]->$_} qw(value count depth)], [$root_value, 4, 0]); $i++;
    {
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [1, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [10, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [11, 1, 1]); $i++;
        is_deeply([map {$result[$i]->$_} qw(value count depth)], [2, 1, 1]); $i++;
    }
};

subtest date => sub {
    plan tests => 10;
    
    my $data = Data::Freq->new({type => 'month'}, {pos => 1});
    
    $data->add("a b [2012-01-01 00:00:00] c\n");
    $data->add("a b [2012-01-02 01:00:00] c\n");
    $data->add("a b [2012-02-03 02:00:00] d\n");
    $data->add("a b [2012-02-04 03:00:00] d\n");
    $data->add("a c [2012-02-05 04:00:00] d\n");
    $data->add("a c [2012-02-06 05:00:00] d\n");
    $data->add("a c [2012-02-07 06:00:00] d\n");
    $data->add("b d [2012-01-08 07:00:00] e\n");
    $data->add("b d [2012-02-09 08:00:00] e\n");
    $data->add("b e [2012-01-10 09:00:00] e\n");
    $data->add("b e [2012-01-11 10:00:00] f\n");
    $data->add("b f [2012-02-12 11:00:00] f\n");
    
    my @result;
    $data->output(sub {push @result, $_[0]});
    my $i = 0;
    
    is_deeply([map {$result[$i]->$_} qw(value count depth)], [$root_value, 12, 0]); $i++;
    {
        is_deeply([map {$result[$i]->$_} qw(value count depth)], ['2012-01', 5, 1]); $i++;
        {
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['b', 2, 2]); $i++;
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['e', 2, 2]); $i++;
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['d', 1, 2]); $i++;
        }
        is_deeply([map {$result[$i]->$_} qw(value count depth)], ['2012-02', 7, 1]); $i++;
        {
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['c', 3, 2]); $i++;
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['b', 2, 2]); $i++;
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['d', 1, 2]); $i++;
            is_deeply([map {$result[$i]->$_} qw(value count depth)], ['f', 1, 2]); $i++;
        }
    }
};

SKIP: {
    eval {require IO::String} or skip 'IO::String is not installed', 2;
    
    subtest output_1 => sub {
        plan tests => 4;
        
        my $data = Data::Freq->new({type => 'month'});
        
        $data->add("[2012-01-01 00:00:00] abc\n") foreach 1..10;
        $data->add("[2012-01-02 01:00:00] def\n") foreach 1..5;
        $data->add("[2012-01-03 02:00:00] ghi\n") foreach 1..45;
        $data->add("[2012-02-04 03:00:00] abc\n") foreach 1..1;
        $data->add("[2012-02-05 04:00:00] ghi\n") foreach 1..1;
        $data->add("[2012-02-06 05:00:00] jkl\n") foreach 1..2;
        $data->add("[2012-02-07 06:00:00] mno\n") foreach 1..1;
        $data->add("[2012-03-08 07:00:00] abc\n") foreach 1..2;
        $data->add("[2012-03-09 08:00:00] def\n") foreach 1..115;
        $data->add("[2012-03-10 09:00:00] ghi\n") foreach 1..3;
        
        my $result;
        $data->output(IO::String->new($result));
        my @chunks = split /\n/, $result;
        
        my $i = 0;
        is $chunks[$i++], ' 60: 2012-01';
        is $chunks[$i++], '  5: 2012-02';
        is $chunks[$i++], '120: 2012-03';
        is scalar(@chunks), $i;
    };
    
    subtest output_2 => sub {
        plan tests => 2;
        
        my $data = Data::Freq->new({type => 'month'}, {pos => 1});
        
        $data->add("[2012-01-01 00:00:00] abc\n") foreach 1..10;
        $data->add("[2012-01-02 01:00:00] def\n") foreach 1..5;
        $data->add("[2012-01-03 02:00:00] ghi\n") foreach 1..45;
        $data->add("[2012-02-04 03:00:00] abc\n") foreach 1..1;
        $data->add("[2012-02-05 04:00:00] ghi\n") foreach 1..1;
        $data->add("[2012-02-06 05:00:00] jkl\n") foreach 1..2;
        $data->add("[2012-02-07 06:00:00] mno\n") foreach 1..1;
        $data->add("[2012-03-08 07:00:00] abc\n") foreach 1..2;
        $data->add("[2012-03-09 08:00:00] def\n") foreach 1..115;
        $data->add("[2012-03-10 09:00:00] ghi\n") foreach 1..3;
        
        subtest no_opts => sub {
            plan tests => 14;
            
            my $result;
            $data->output(IO::String->new($result));
            my @chunks = split /\n/, $result;
            
            my $i = 0;
            is $chunks[$i++], ' 60: 2012-01';
            is $chunks[$i++], '     45: ghi';
            is $chunks[$i++], '     10: abc';
            is $chunks[$i++], '      5: def';
            is $chunks[$i++], '  5: 2012-02';
            is $chunks[$i++], '      2: jkl';
            is $chunks[$i++], '      1: abc';
            is $chunks[$i++], '      1: ghi';
            is $chunks[$i++], '      1: mno';
            is $chunks[$i++], '120: 2012-03';
            is $chunks[$i++], '    115: def';
            is $chunks[$i++], '      3: ghi';
            is $chunks[$i++], '      2: abc';
            is scalar(@chunks), $i;
        };
        
        subtest with_opts => sub {
            plan tests => 15;
            
            my $result;
            
            $data->output(IO::String->new($result), {
                with_root => 1, no_padding => 1,
                indent => '   ', prefix => '- ', separator => ' => ',
            });
            
            my @chunks = split /\n/, $result;
            
            my $i = 0;
            is $chunks[$i++], '- 185 => Total';
            is $chunks[$i++], '   - 60 => 2012-01';
            is $chunks[$i++], '      - 45 => ghi';
            is $chunks[$i++], '      - 10 => abc';
            is $chunks[$i++], '      - 5 => def';
            is $chunks[$i++], '   - 5 => 2012-02';
            is $chunks[$i++], '      - 2 => jkl';
            is $chunks[$i++], '      - 1 => abc';
            is $chunks[$i++], '      - 1 => ghi';
            is $chunks[$i++], '      - 1 => mno';
            is $chunks[$i++], '   - 120 => 2012-03';
            is $chunks[$i++], '      - 115 => def';
            is $chunks[$i++], '      - 3 => ghi';
            is $chunks[$i++], '      - 2 => abc';
            is scalar(@chunks), $i;
        };
    };
}
