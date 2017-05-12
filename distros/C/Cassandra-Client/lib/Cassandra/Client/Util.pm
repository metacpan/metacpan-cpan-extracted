package Cassandra::Client::Util;
use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT= ('series', 'parallel', 'whilst');

use Sub::Current;

sub series {
    my $list= shift;
    my $final= shift;

    (shift @$list)->(sub {
        my $next= shift @$list;
        if ($next && !$_[0]) {
            splice @_, 0, 1, ROUTINE();
            goto &$next;
        }

        goto &$final;
    });

    return;
}

sub parallel {
    my ($list, $final)= @_;

    if (!@$list) {
        return $final->();
    }

    my $remaining= 0+@$list;
    my @result;
    for my $i (0..$#$list) {
        $list->[$i]->(sub {
            my ($error, $result)= @_;
            if ($error) {
                if ($remaining > 0) {
                    $remaining= 0;
                    $final->($error);
                }
                return;
            }

            $result[$i]= $result;

            $remaining--;
            if ($remaining == 0) {
                $final->(undef, @result);
            }
        });
    }

    return;
}

sub whilst {
    my ($condition, $iteratee, $callback)= @_;

    (sub {
        if (defined $_[0] || !($condition->())) {
            goto &$callback;
        }
        splice @_, 0, 1, ROUTINE();
        goto &$iteratee;
    })->();
}

1;
