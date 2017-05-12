
use lib qw(lib);

use constant IOBUFSIZE => 8192;

use Apache2::Const -compile => qw(MODE_READBYTES);
use APR::Const    -compile => qw(SUCCESS BLOCK_READ);

use APR::Brigade ();
use APR::Bucket ();
use Apache2::Filter ();

# to enable debug start with: (or simply run with -trace=debug)
# t/TEST -trace=debug -start
sub ModPerl::Test::read_post {
    my $r = shift;
    my $debug = shift || 0;

    my $bb = APR::Brigade->new($r->pool,
                               $r->connection->bucket_alloc);

    my $data = '';
    my $seen_eos = 0;
    my $count = 0;
    do {
        $r->input_filters->get_brigade($bb, Apache2::Const::MODE_READBYTES,
                                       APR::Const::BLOCK_READ, IOBUFSIZE);

        $count++;

        warn "read_post: bb $count\n" if $debug;

        for (my $b = $bb->first; $b; $b = $bb->next($b)) {
            if ($b->is_eos) {
                warn "read_post: EOS bucket:\n" if $debug;
                $seen_eos++;
                last;
            }

            if ($b->read(my $buf)) {
                warn "read_post: DATA bucket: [$buf]\n" if $debug;
                $data .= $buf;
            }

            $b->remove; # optimization to reuse memory
        }

    } while (!$seen_eos);

    $bb->destroy;

    return $data;
}

package ModPerl::TestFilterDebug;

use strict;
use warnings FATAL => 'all';

use base qw(Apache2::Filter);
use APR::Brigade ();
use APR::Bucket ();
use APR::BucketType ();

use Apache2::Const -compile => qw(OK DECLINED);
use APR::Const -compile => ':common';

# to use these functions add any or all of these filter handlers
# PerlInputFilterHandler  ModPerl::TestFilterDebug::snoop_request
# PerlInputFilterHandler  ModPerl::TestFilterDebug::snoop_connection
# PerlOutputFilterHandler ModPerl::TestFilterDebug::snoop_request
# PerlOutputFilterHandler ModPerl::TestFilterDebug::snoop_connection
#

sub snoop_connection : FilterConnectionHandler { snoop("connection", @_) }
sub snoop_request    : FilterRequestHandler    { snoop("request",    @_) }

sub snoop {
    my $type = shift;
    my($filter, $bb, $mode, $block, $readbytes) = @_; # filter args

    # $mode, $block, $readbytes are passed only for input filters
    my $stream = defined $mode ? "input" : "output";

    # read the data and pass-through the bucket brigades unchanged
    if (defined $mode) {
        # input filter
        my $rv = $filter->next->get_brigade($bb, $mode, $block, $readbytes);
        return $rv unless $rv == APR::Const::SUCCESS;
        bb_dump($type, $stream, $bb);
    }
    else {
        # output filter
        bb_dump($type, $stream, $bb);
        my $rv = $filter->next->pass_brigade($bb);
        return $rv unless $rv == APR::Const::SUCCESS;
    }
    #if ($bb->is_empty) {
    #    return -1;
    #}

    return Apache2::Const::OK;
}

sub bb_dump {
    my($type, $stream, $bb) = @_;

    my @data;
    for (my $b = $bb->first; $b; $b = $bb->next($b)) {
        $b->read(my $bdata);
        push @data, $b->type->name, $bdata;
    }

    # send the sniffed info to STDERR so not to interfere with normal
    # output
    my $direction = $stream eq 'output' ? ">>>" : "<<<";
    print STDERR "\n$direction $type $stream filter\n";

    unless (@data) {
        print STDERR "  No buckets\n";
        return;
    }

    my $c = 1;
    while (my($btype, $data) = splice @data, 0, 2) {
        print STDERR "    o bucket $c: $btype\n";
        print STDERR "[$data]\n";
        $c++;
    }
}

1;
