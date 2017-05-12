package TestDebugFilter::bb_dump;

use strict;
use warnings FATAL => 'all';

use Apache2::Connection ();
use APR::Socket ();
use APR::Bucket ();
use APR::Brigade ();
use APR::Util ();
use APR::Error ();

use Apache::TestTrace;

use Apache2::DebugFilter;

use APR::Const -compile => qw(SUCCESS EOF SO_NONBLOCK);
use Apache2::Const -compile => qw(OK MODE_GETLINE);

sub handler {
    my Apache2::Connection $c = shift;

    my $ba  = $c->bucket_alloc;
    my $ibb = APR::Brigade->new($c->pool, $ba);
    my $obb = APR::Brigade->new($c->pool, $ba);

    # starting from Apache 2.0.49 several platforms require you to set
    # the socket to a blocking IO mode
    $c->client_socket->opt_set(APR::Const::SO_NONBLOCK, 0);

    for (;;) {
        my $rv = $c->input_filters->get_brigade($ibb, Apache2::Const::MODE_GETLINE);
        if ($rv != APR::Const::SUCCESS or $ibb->is_empty) {
            my $error = APR::Error::strerror($rv);
            unless ($rv == APR::Const::EOF) {
                warn "[echo_filter] get_brigade: $error\n";
            }
            $ibb->destroy;
            last;
        }

        my $ra_data = Apache2::DebugFilter::bb_dump($ibb);
        debug $ra_data;

        $ibb->destroy;

        while (my($btype, $data) = splice @$ra_data, 0, 2) {
            my $data = "$btype => $data";
            $obb->insert_tail(APR::Bucket->new($ba, $data));
        }
        $obb->insert_tail(APR::Bucket::flush_create($ba));

        $c->output_filters->pass_brigade($obb);
    }

    Apache2::Const::OK;
}

1;
__END__
<NoAutoConfig>
  <VirtualHost TestDebugFilter::bb_dump>
      PerlProcessConnectionHandler TestDebugFilter::bb_dump
  </VirtualHost>
</NoAutoConfig>

