#!perl -T
use Data::Consumer::Dir;
use strict;
use warnings;
use DBI;
use File::Path;
use Data::Dumper;

my $debug = 0;

our %process_state;
if (!%process_state) {
    %process_state = (
        root => 't/dir-test',
        create => 1,   
    );
}
my $wrk='t/dir-test/unprocessed';
mkdir 't/dir-test' and mkdir $wrk if !-d $wrk;
for (1..50) {
    open my $fh,">","$wrk/$_" 
        or die "failed to create test file $wrk/$_:$!";
    # 0 byte file
    close $fh;
}

my $child;
my $procs = 4;
$debug  and Data::Consumer->debug_warn("Spawning children!\n");
my $pid = $$;
my @child;
do {
    $child = fork;
    if (!defined $child) {
        die "Fork failed!";
    } elsif ($child) {
        push @child,$child;
    }
} while $child and --$procs > 0;

if ( $child ) {
    $debug  and $debug and Data::Consumer->debug_warn("Using test more\n");
    eval 'use Test::More tests => 4; ok(1); 1;' 
        or die $@;
} else {
   sleep(1);
}

$child and diag("This will take around 30 seconds");
$debug and Data::Consumer->debug_warn(0,"starting processing\n");
$Data::Consumer::Debug=5 if $debug;

my $consumer = Data::Consumer::Dir->new(
    open_mode => '>>',    
    %process_state,
);

$consumer->consume(sub {
    my ($consumer,$spec,$fh,$file) = @_; 
    #die if $file == 25;
    $debug 
        and $consumer->debug_warn(0,"*** processing '$spec'"); 
    print $fh '1';
    sleep(1);
});


if ( $child ) {
    use POSIX ":sys_wait_h";
    while (@child) {
        @child = grep { waitpid($_,WNOHANG)==0 } @child;
        sleep(1);
    }
    # check files and file sizes here
    use File::Find; 
    my %type;
    my $error=0;
    find({
            wanted => sub{ 
                -f $_ or return;
                $File::Find::dir=~m!/([^/]+)$! or return;                
                ($type{$1}{$_} = -s $_) == 1 or ++$error;
            }, 
            untaint => 1, 
        },'t/dir-test');
    my @processed = sort {$a <=> $b} keys %{$type{processed}||{}};
    my @expect = ( 1..50 );
    my $ok = 0;

    # think of '!!' as the boolean cast operator.
    $ok += !!is( $error, 0, 'count of files that arent single byte should be 0');
    $ok += !!is( "@{[sort keys %type]}", "processed", 'should be only processed');
    $ok += !!is( "@processed", "@expect", 'expected processed files' );
    if ($ok != 3) {
        diag(Dumper(\%type));
    } else {
        rmtree 't/dir-test', $debug;
    }
} 

1;




