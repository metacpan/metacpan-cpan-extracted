#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

use Data::Freq::Record qw(logsplit);
use POSIX qw(strftime);

subtest logsplit => sub {
    plan tests => 6;
    
    is_deeply [logsplit ''], [];
    is_deeply [logsplit 'test'], ['test'];
    is_deeply [logsplit 'test1 test2'], ['test1', 'test2'];
    
    is_deeply [logsplit qq(ab [cd ef] "gh ij" kl [mn] op\n)],
            ['ab', '[cd ef]', '"gh ij"', 'kl', '[mn]', 'op'];
    
    my ($date, $time) = split ' ', strftime('%F %T', localtime);
    
    is_deeply [logsplit qq([$date $time] - 123 {ab "cd" (ef-4.56 gh)} - -)],
            ["[$date $time]", '-', '123', '{ab "cd" (ef-4.56 gh)}', '-', '-'];
    
    is_deeply [logsplit qq([ \\] ] " \\" " { \\} } ' \\' ')],
            ['[ \\] ]', '" \\" "', '{ \\} }', "' \\' '"];
};

subtest text => sub {
    plan tests => 3;
    
    my $record = Data::Freq::Record->new('test');
    
    is $record->text, 'test';
    is_deeply $record->array, ['test'];
    is $record->hash, undef;
};

subtest array => sub {
    plan tests => 3;
    
    my $record = Data::Freq::Record->new(['foo', 'bar', 'baz']);
    
    is $record->text, 'foo';
    is_deeply $record->array, ['foo', 'bar', 'baz'];
    is $record->hash, undef;
};

subtest hash => sub {
    plan tests => 3;
    
    my $record = Data::Freq::Record->new({foo => 123, bar => 456, baz => 789});
    
    is $record->text, undef;
    is $record->array, undef;
    is_deeply $record->hash, {foo => 123, bar => 456, baz => 789};
};

subtest date => sub {
    plan tests => 3;
    
    my $record;
    
    # Apache
    $record = Data::Freq::Record->new(qq(12.34.56.78 - user1 [01/Jan/2012:01:02:03 +0000] "GET / HTTP/1.1" 200 44\n));
    is $record->date, 1325379723;
    
    # Custom
    $record = Data::Freq::Record->new(qq([2012-01-01 01:02:03] DEBUG - Test debug message\n));
    is(strftime('%Y-%m-%d %H:%M:%S', localtime $record->date), '2012-01-01 01:02:03'); # 1325379723 if tz is gmt;
    
    # Log4J (or Log4perl etc) with %d{dd MMM yyyy HH:mm:ss,SSS}
    $record = Data::Freq::Record->new(qq(01 Jan 2012 01:02:03,456 INFO  [main] foo.bar.Baz:123 - test test test\n));
    is(strftime('%Y-%m-%d %H:%M:%S', localtime int($record->date([0..3]))), '2012-01-01 01:02:03'); # 1325379723.456 if tz is gmt
};
