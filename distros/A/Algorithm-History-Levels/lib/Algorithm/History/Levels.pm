package Algorithm::History::Levels;

our $DATE = '2017-06-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(group_histories_into_levels);

our %SPEC;

sub _pick_history {
    my ($histories, $min_time, $max_time) = @_;
    for my $i (0..$#{$histories}) {
        #say "D:$histories->[$i][1] between $min_time & $max_time?";
        if ($histories->[$i][1] >= $min_time &&
                $histories->[$i][1] <= $max_time) {
            return splice(@$histories, $i, 1);
        }
    }
    undef;
}

$SPEC{group_histories_into_levels} = {
    v => 1.1,
    summary => 'Group histories into levels',
    description => <<'_',

This routine can group a single, linear histories into levels. This is be better
explained by an example. Suppose you produce daily database backups. Your backup
files are named:

    mydb.2017-06-13.sql.gz
    mydb.2017-06-12.sql.gz
    mydb.2017-06-11.sql.gz
    mydb.2017-06-10.sql.gz
    mydb.2017-06-09.sql.gz
    ...

After a while, your backups grow into tens and then hundreds of dump files. You
typically want to keep certain number of backups only, for example: 7 daily
backups, 4 weekly backups, 6 monthly backups (so you practically have 6 months
of history but do not need to store 6*30 = 180 dumps, only 7 + 4 + 6 = 17). This
is the routine you can use to select which files to keep and which to discard.

You provide the list of histories either in the form of Unix timestamps:

    [1497286800, 1497200400, 1497114000, ...]

or in the form of `[name, timestamp]` pairs, e.g.:

    [
      ['mydb.2017-06-13.sql.gz', 1497286800],
      ['mydb.2017-06-12.sql.gz', 1497200400],
      ['mydb.2017-06-11.sql.gz', 1497114000],
      ...
    ]

Duplicates of timestamps are allowed, but duplicates of names are not allowed.
If list of timestamps are given, the name is assumed to be the timestamp itself
and there must not be duplicates.

Then, you specify the levels with a list of `[period, num-in-this-level]` pairs.
For example, 7 daily + 4 weekly + 6 monthly can be specified using:

    [
      [86400, 7],
      [7*86400, 4],
      [30*86400, 6],
    ]

Subsequent level must have greater period than its previous.

This routine will return a hash. The `levels` key will contain the history
names, grouped into levels. The `discard` key will contain list of history names
to discard:

    {
      levels => [

        # histories for the first level
        ['mydb.2017-06-13.sql.gz',
         'mydb.2017-06-12.sql.gz',
         'mydb.2017-06-11.sql.gz',
         'mydb.2017-06-10.sql.gz',
         'mydb.2017-06-09.sql.gz',
         'mydb.2017-06-08.sql.gz',
         'mydb.2017-06-07.sql.gz'],

        # histories for the second level
        ['mydb.2017-06-06.sql.gz',
         'mydb.2017-05-30.sql.gz',
         'mydb.2017-05-23.sql.gz',
         'mydb.2017-05-16.sql.gz'],

        # histories for the third level
        ['mydb.2017-06-05.sql.gz',
         'mydb.2017-05-06.sql.gz',
         'mydb.2017-04-06.sql.gz',
         ...],

      discard => [
        'mydb.2017-06-04.sql.gz',
        'mydb.2017-06-03.sql.gz',
        ...
      ],
    }

_
    args => {
        histories => {
            schema => ['array*', {
                of=>['any*', {
                    of=>[
                        'int*',
                        ['array*', elems=>['str*', 'float*']],
                    ],
                }],
            }],
            req => 1,
        },
        levels => {
            schema => ['array*', {
                of => ['array*', elems => ['float*', 'posint*']],
                min_len => 1,
            }],
            req => 1,
        },
        now => {
            schema => 'int*',
        },
        discard_old_histories => {
            schema => ['bool*'],
            default => 0,
        },
        discard_young_histories => {
            schema => ['bool*'],
            default => 0,
        },
    },
    result_naked => 1,
};
sub group_histories_into_levels {
    require Array::Sample::Partition;

    my %args = @_;

    my $now = $args{now} // time();

    my $histories0 = $args{histories} or die "Please specify histories";
    my @histories;
    {
        my %seen;
        for my $h (@$histories0) {
            my ($name, $time);
            if (ref $h eq 'ARRAY') {
                ($name, $time) = @$h;
            } else {
                $name = $h;
                $time = $h;
        }
            $seen{$name}++ and die "Duplicate history name '$name'";
            push @histories, [$name, $time];
        }
    }

    my $levels = $args{levels} or die "Please specify levels";
    @$levels > 0 or die "Please specify at least one level";
    my $i = 0;
    my $min_period;
    for my $l (@$levels) {
        ref($l) eq 'ARRAY' or die "Level #$i: not an array";
        @$l == 2 or die "Level #$i: not a 2-element array";
        $l->[0] > 0  or die "Level #$i: period must be a positive number";
        $l->[1] >= 1 or die "Level #$i: number of items must be at least 1";
        if (defined $min_period) {
            $l->[0] > $min_period  or die "Level #$i: period must be larger than previous ($min_period)";
        }
        $min_period = $l->[0];
        $i++;
    }

    # first, we sort the histories by timestamp (newer first)
    @histories = sort { $b->[1] <=> $a->[1] } @histories;

    my $res = {
        levels => [ map {[]} @$levels],
        discard => [],
    };

  LEVEL:
    for my $l (0..$#{$levels}) {
        my ($period, $num_per_level) = @{ $levels->[$l] };

        # first, fill the level with histories that fit the time frame for each
        # level's slot
        for my $slot (0..$num_per_level-1) {
            my $min_time = $now-($slot+1)*$period;
            my $max_time = $now-($slot  )*$period;
            if ($l > 0) {
                my ($lower_period, $lower_num_per_level) = @{ $levels->[$l-1] };
                $min_time -= $lower_num_per_level*$lower_period;
                $max_time -= $lower_num_per_level*$lower_period;
            }
            my $h = _pick_history(\@histories, $min_time, $max_time);
            push @{ $res->{levels}[$l] }, $h if $h;
        }

        # if the level is not fully filled yet, fill it with young or old
        # histories
        my $num_filled = @{ $res->{levels}[$l] };
        #say "D:level=$l, num_filled=$num_filled";
        unless ($num_filled >= $num_per_level) {
            my @filler = @histories;
            if ($args{discard_young_histories} // 0) {
                my $time = $now-$num_per_level*$period;
                if ($l > 0) {
                    my ($lower_period, $lower_num_per_level) =
                        @{ $levels->[$l-1] };
                    $time -= $lower_num_per_level*$lower_period;
                }
                @filler = grep { $_->[1] <= $time }
                    @filler;
            }
            if ($args{discard_old_histories} // 0) {
                my $time = $now-$num_per_level*$period;
                if ($l > 0) {
                    my ($lower_period, $lower_num_per_level) =
                        @{ $levels->[$l-1] };
                    $time -= $lower_num_per_level*$lower_period;
                }
                @filler = grep { $_->[1] >= $time }
                    @filler;
            }
            my @sample = Array::Sample::Partition::sample_partition(
                \@filler, $num_per_level - $num_filled);
            $res->{levels}[$l] = [
                sort { $b->[1] <=> $a->[1] }
                    (@{ $res->{levels}[$l] }, @sample),
            ];
            for my $i (reverse 0..$#histories) {
                for my $j (0..$#sample) {
                    if ($histories[$i] eq $sample[$j]) {
                        splice @histories, $i, 1;
                        last;
                    }
                }
            }
        }

        # only return names
        $res->{levels}[$l] = [ map {$_->[0]} @{ $res->{levels}[$l] } ];
    }

    push @{ $res->{discard} }, $_->[0] for @histories;

  END:
    $res;
}

1;
# ABSTRACT: Group histories into levels

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::History::Levels - Group histories into levels

=head1 VERSION

This document describes version 0.001 of Algorithm::History::Levels (from Perl distribution Algorithm-History-Levels), released on 2017-06-14.

=head1 SYNOPSIS

 use Algorithm::History::Levels qw(group_history_into_levels);

=head1 FUNCTIONS


=head2 group_histories_into_levels

Usage:

 group_histories_into_levels(%args) -> any

Group histories into levels.

This routine can group a single, linear histories into levels. This is be better
explained by an example. Suppose you produce daily database backups. Your backup
files are named:

 mydb.2017-06-13.sql.gz
 mydb.2017-06-12.sql.gz
 mydb.2017-06-11.sql.gz
 mydb.2017-06-10.sql.gz
 mydb.2017-06-09.sql.gz
 ...

After a while, your backups grow into tens and then hundreds of dump files. You
typically want to keep certain number of backups only, for example: 7 daily
backups, 4 weekly backups, 6 monthly backups (so you practically have 6 months
of history but do not need to store 6*30 = 180 dumps, only 7 + 4 + 6 = 17). This
is the routine you can use to select which files to keep and which to discard.

You provide the list of histories either in the form of Unix timestamps:

 [1497286800, 1497200400, 1497114000, ...]

or in the form of C<[name, timestamp]> pairs, e.g.:

 [
   ['mydb.2017-06-13.sql.gz', 1497286800],
   ['mydb.2017-06-12.sql.gz', 1497200400],
   ['mydb.2017-06-11.sql.gz', 1497114000],
   ...
 ]

Duplicates of timestamps are allowed, but duplicates of names are not allowed.
If list of timestamps are given, the name is assumed to be the timestamp itself
and there must not be duplicates.

Then, you specify the levels with a list of C<[period, num-in-this-level]> pairs.
For example, 7 daily + 4 weekly + 6 monthly can be specified using:

 [
   [86400, 7],
   [7*86400, 4],
   [30*86400, 6],
 ]

Subsequent level must have greater period than its previous.

This routine will return a hash. The C<levels> key will contain the history
names, grouped into levels. The C<discard> key will contain list of history names
to discard:

 {
   levels => [
 
     # histories for the first level
     ['mydb.2017-06-13.sql.gz',
      'mydb.2017-06-12.sql.gz',
      'mydb.2017-06-11.sql.gz',
      'mydb.2017-06-10.sql.gz',
      'mydb.2017-06-09.sql.gz',
      'mydb.2017-06-08.sql.gz',
      'mydb.2017-06-07.sql.gz'],
 
     # histories for the second level
     ['mydb.2017-06-06.sql.gz',
      'mydb.2017-05-30.sql.gz',
      'mydb.2017-05-23.sql.gz',
      'mydb.2017-05-16.sql.gz'],
 
     # histories for the third level
     ['mydb.2017-06-05.sql.gz',
      'mydb.2017-05-06.sql.gz',
      'mydb.2017-04-06.sql.gz',
      ...],
 
   discard => [
     'mydb.2017-06-04.sql.gz',
     'mydb.2017-06-03.sql.gz',
     ...
   ],
 }

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<discard_old_histories> => I<bool> (default: 0)

=item * B<discard_young_histories> => I<bool> (default: 0)

=item * B<histories>* => I<array[int|array]>

=item * B<levels>* => I<array[array]>

=item * B<now> => I<int>

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Algorithm-History-Levels>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Algorithm-History-Levels>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-History-Levels>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
