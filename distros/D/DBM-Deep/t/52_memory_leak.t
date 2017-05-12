use strict;
use warnings FATAL => 'all';

use Test::More;

use_ok( 'DBM::Deep' );

use t::common qw( new_dbm );

# RT #77746
my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    $db->{foo} = {};
    my $data = $db->{foo};

    use Scalar::Util 'weaken';
    weaken $db;
    weaken $data;

    is $db, undef, 'no $db after weakening';
    is $data, undef, 'hashes returned from db contain no circular refs';
}
    


# This was discussed here:
# http://groups.google.com/group/DBM-Deep/browse_thread/thread/a6b8224ffec21bab
# brought up by Alex Gallichotte

SKIP: {
    skip "Need to figure out what platforms this runs on", 1;
}

done_testing;
exit;

$dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    my $todo  = 1000;
    my $allow = $todo*0.02; # NOTE: a 2% fail rate is hardly a failure

    $db->{randkey()} = 1 for 1 .. 1000;

    my $error_count = 0;
    my @mem = (mem(0), mem(1));
    for my $i (1 .. $todo) {
        $db->{randkey()} = [@mem];

        ## DEBUG ## print STDERR " @mem     \r";

        my @tm = (mem(0), mem(1));

        skip( not($mem[0]), ($tm[0] <= $mem[0] or --$allow>0) );
        skip( not($mem[1]), ($tm[1] <= $mem[1] or --$allow>0) );

        $error_count ++ if $tm[0] > $mem[0] or $tm[1] > $mem[1];
        die " ERROR: that's enough failures to prove the point ... " if $error_count > 20;

        @mem = @tm;
    }
}

sub randkey {
    our $i ++;
    my @k = map { int rand 100 } 1 .. 10;
    local $" = "-";

    return "$i-@k";
}

sub mem {
    open my $in, "/proc/$$/statm" or return 0;
    my $line = [ split m/\s+/, <$in> ];
    close $in;

    return $line->[shift];
}

__END__
/proc/[number]/statm

      Provides information about memory status in pages.  The columns are:

          size       total program size
          resident   resident set size
          share      shared pages
          text       text (code)
          lib        library
          data       data/stack
          dt         dirty pages (unused in Linux 2.6)
