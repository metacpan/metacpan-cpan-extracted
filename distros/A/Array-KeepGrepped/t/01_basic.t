use Test::More tests => 6;

use lib 'lib';
use Array::KeepGrepped qw/kgrep/;

NUMERIC: {
    my @numbers = 1..10;
    my ($evens, @odds) = kgrep { $_ % 2 } @numbers;
    is_deeply(\@odds, [1,3,5,7,9], 'Correct odd numbers');
    is_deeply($evens, [2,4,6,8,10], 'Correct even numbers');
    }

IN_PLACE: {
    my @good = qw/good bad good evil good wicked good/;
    my $bad;
    ($bad, @good) = kgrep { $_ =~ /good/ } @good;
    is_deeply($bad, [qw/bad evil wicked/], 'Correct bad values');
    is_deeply(\@good, [qw/good good good good/], 'Correct good values');
    }

CHECK_LOCAL: {
    $_ = 'foo';
    my @bar = qw/aaa bbb/;
    my ($aaa, @bbb) = kgrep { $_ =~ /a/ } @bar;
    is($_, 'foo', '$_ unchanged');
    }

LIKE_GREP: {
    my @test = qw/a b c d/;
    my @grep = grep { !$_ =~ m#a# } @test;
    my (undef, @kgrep) = kgrep { !$_ =~ m#a# } @test;
    is_deeply(\@grep, \@kgrep, 'kgrep matches grep filtering');
    }

done_testing();
