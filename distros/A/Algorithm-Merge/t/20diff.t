# `use' statements are after test definition

my $error_message = 'Algorithm::Diff::diff is not symmetric for second and third sequences';

my(@tests, $tests);

BEGIN {

# check sequences of equal length (1 element each)
my @results = (
    [ 'u', '', '', '' ],
    [ 'r', '', '', 'c' ],
    [ 'l', '', 'b', '' ],
    [ 'c', '', 'b', 'c' ],
    [ 'o', 'a', '', '' ],
    [ 'c', 'a', '', 'c' ],
    [ 'c', 'a', 'b', '' ],
    [ 'c', 'a', 'b', 'c' ],
);

foreach $i (0, 1) {
    foreach $j (0, 1) {
        foreach $k (0, 1) {
#my($i, $j, $k) = (1, 1, 0);  # for testing an individual combination
            push @tests, [
                [ $i ? 'a' : '' ],
                [ $j ? 'b' : '' ],
                [ $k ? 'c' : '' ],
                [ $results[$i*4 + $j*2 + $k], ],
            ];
        }
    }
}

# check sequences, some of which are empty/null sequences ( [] in diff3 call, undef in output)
@results = (
    [ ],  # no contents in any of the sequences
    [ 'r', undef, undef, 'c' ],
    [ 'l', undef, 'b', undef ],
    [ 'c', undef, 'b', 'c' ],
    [ 'o', 'a', undef, undef ],
    [ 'r', 'a', undef, 'c' ],  # still a problem
    [ 'l', 'a', 'b', undef ],  # still a problem
    [ 'c', 'a', 'b', 'c' ],
);

foreach $i (0, 1) {
   foreach $j (0, 1) {
        foreach $k (0, 1) {
#my($i, $j, $k) = (1, 1, 0);  # for testing an individual combination
            push @tests, [
                [ ($i ? 'a' : () ) ],
                [ ($j ? 'b' : () ) ],
                [ ($k ? 'c' : () ) ],
                [ $results[$i*4 + $j*2 + $k] ],
            ];
        }
    }
}

push @tests, [
  [ qw(1 2 3 4 5 6 7) ],
  [ qw(1 2       6 7) ],
  [ qw(1 2 3 0 5 6 7) ],
  [ [                                qw(u 1 1 1) ],
    [                                qw(u 2 2 2) ],
    [ map { $_ eq '-' ? undef : $_ } qw(l 3 - 3) ],
    [ map { $_ eq '-' ? undef : $_ } qw(r 4 - 0) ],
    [ map { $_ eq '-' ? undef : $_ } qw(l 5 - 5) ],
    [                                qw(u 6 6 6) ],
    [                                qw(u 7 7 7) ]
  ]
];

push @tests, [
  [ qw(1   3 4 5) ],
  [ qw(1 a 3 4 5) ],
  [ qw(1 b 3 4 5) ],
  [ [                                qw(u 1 1 1) ],
    [ map { $_ eq '-' ? undef : $_ } qw(c - a b) ],
    [                                qw(u 3 3 3) ],
    [                                qw(u 4 4 4) ],
    [                                qw(u 5 5 5) ],
  ]
];
    
push @tests, [
  [ qw(  o p p q r s) ],
  [ qw(n o p   q r  ) ],
  [ qw(N o p p q r  ) ],
  [ [ map { $_ eq '-' ? undef : $_ } qw(c - n N) ],
    [                                qw(u o o o) ],
    [ map { $_ eq '-' ? undef : $_ } qw(l p - p) ],
    [                                qw(u p p p) ],
    [                                qw(u q q q) ],
    [                                qw(u r r r) ],
    [ map { $_ eq '-' ? undef : $_ } qw(o s - -) ],
  ]
];

push @tests, [
  [ qw(  o p p q r s) ],
  [ qw(n o p   q r  ) ],
  [ qw(N o p P q r  ) ],
  [ [ map { $_ eq '-' ? undef : $_ } qw(c - n N) ],
    [                                qw(u o o o) ],
    [                                qw(u p p p) ],
    [ map { $_ eq '-' ? undef : $_ } qw(r p - P) ],
    [                                qw(u q q q) ],
    [                                qw(u r r r) ],
    [ map { $_ eq '-' ? undef : $_ } qw(o s - -) ],
  ]
];

push @tests, [
  [ qw(  o p p q r s) ],
  [ qw(n o p   q r  ) ],
  [ qw(  o p P q r  ) ],
  [ [ map { $_ eq '-' ? undef : $_ } qw(l - n -) ],
    [                                qw(u o o o) ],
    [                                qw(u p p p) ],
    [ map { $_ eq '-' ? undef : $_ } qw(r p - P) ],
    [                                qw(u q q q) ],
    [                                qw(u r r r) ],
    [ map { $_ eq '-' ? undef : $_ } qw(o s - -) ],
  ]
];


$tests = scalar(@tests) + 1;

} # END BEGIN

use Test::More tests => $tests;

require_ok('Algorithm::Merge');

my $out;

{ no warnings;
$Algorithm::Merge::DEBUG = $ENV{'DEBUG'};
}

foreach my $t (@tests) {
    if(UNIVERSAL::isa($t, 'CODE')) {
        eval { local $SIG{__DIE__}; $t -> (); };
        warn "$@\n" if $@ && $ENV{DEBUG};
        ok !$@;
    }
    else {
        eval {
            local $SIG{__DIE__};
            local $SIG{__WARN__} = sub { };
            $out = Algorithm::Merge::diff3(@{$t}[0, 1, 2]);
        };
        if($@ && $@ =~ m{^$error_message}o) {
            ok 1;
        }
        else {
            #my $sout = join(";", map { join(":", map { defined($_) ? "[$_]" : "" } @{$_}) } @{$out});
            #my $sexp = join(";", map { join(":", map { defined($_) ? "[$_]" : "" } @{$_}) } @{$t->[3]});

#            warn Data::Dumper -> Dump([$out, $t->[3]], [qw(Out Expected Diff)]); # if $ENV{DEBUG} && $sout ne $sexp;
            #ok $sout eq $sexp;
            is_deeply($out, $t->[3]);
        }
    }
}

exit 0;
