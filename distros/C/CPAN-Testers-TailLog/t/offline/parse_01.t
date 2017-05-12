use strict;
use warnings;

use Test::More;
use lib 't/lib';

use HTTP::Tiny::Mock;
use CPAN::Testers::TailLog;
my $tail =
  CPAN::Testers::TailLog->new(
    _ua => HTTP::Tiny::Mock->new('t/files/01-log.txt') );

my $results = $tail->get_all();

cmp_ok( ref $results,       'eq', 'ARRAY', 'ArrayRef returned' );
cmp_ok( scalar @{$results}, '>',  0,       'Some results' );
cmp_ok( scalar @{$results}, '==', 1000,    '1000 results parsed' );

sub as_unicode {
    my $text = $_[0];
    utf8::decode($text);
    return $text;
}

sub as_bytes {
    my $text = $_[0];
    utf8::encode($text);
    return $text;
}

# note, when extracting manually from log
# remember to offset 1 for the header, and then another
# if using 1-based ordering with `cat -n`
my %expected = (
    0 => [
        '2016-08-19T11:05:01Z',
        'Chris Williams (BINGOS)',
        'fail',
        'LTHEISEN/Footprintless-1.08.tar.gz',
        'x86_64-gnukfreebsd',
        'perl-v5.12.1',
        'c618d39e-65fc-11e6-ab41-c893a58a4b8c',
        '2016-08-19T11:05:01Z'
    ],
    ( 4 - 2 ) => [
        '2016-08-19T11:04:54Z',
        as_unicode('Andreas J. König (ANDK)'),
        'pass',
        'MELEZHIK/Outthentic-0.2.7.tar.gz',
        'x86_64-linux',
        'perl-v5.8.8',
        'c2367b28-65fc-11e6-85ad-35d858b9f28c',
        '2016-08-19T11:04:54Z',
    ],
    ( 244 - 2 ) => [
        '2016-08-19T10:45:36Z',
        'Alexandr Ciornii (CHORNY)',
        'pass',
        'EXODIST/Test-Simple-1.302053-TRIAL.tar.gz',
        'MSWin32-x86-multi-thread',
        'perl-v5.16.0',
        'cb93861e-6bfb-1014-acc6-614d6ef4f252',
        '2016-08-19T10:45:36Z'
    ],
);
my @fields = (
    'submitted', 'reporter',     'grade', 'filename',
    'platform',  'perl_version', 'uuid',  'accepted'
);

for my $row ( sort { $a <=> $b } keys %expected ) {
    note "Comparing row $row";
    for my $col ( 0 .. $#{ $expected{$row} } ) {
        my $field = $fields[$col];
        cmp_ok(
            as_bytes( $results->[$row]->$field() ),
            'eq',
            as_bytes( $expected{$row}->[$col] ),
            "Row $row\'s $field($col) was expected value: "
              . as_bytes( $expected{$row}->[$col] )
        );
    }
}

cmp_ok(
    $results->[0]->{reporter},
    'eq',
    'Chris Williams (BINGOS)',
    'Got first author ok'
);

for my $result ( 0 .. $#{$results} ) {
    ok(
        defined $results->[$result]->submitted,
        "Item $result has defined submission time"
    );
}

done_testing;

