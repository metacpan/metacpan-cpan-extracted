use Test2::V0;
use Atomic::Pipe;
use Time::HiRes qw/sleep/;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

BEGIN {
    my $path = __FILE__;
    $path =~ s{[^/]+\.t$}{worker.pm};
    require "./$path";
}

my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
open(my $wh, '>&=', $w->wh) or die "Could not clone write handle: $!";
$wh->autoflush(1);

for my $rs (undef, 1, 256, PIPE_BUF) {
    subtest "read size: " . ($rs // 'slurp') => sub {
        my %params;
        $params{read_size} = $rs if defined($rs);

        worker {
            print $wh "A Line\n";
            print $wh "Line start ...";
            $wh->flush();

            $w->write_burst("Interrupting cow!\n\n\n");

            print $wh "... line end\n";
            $wh->flush;
        };

        my @got;
        while (@got != 3) {
            my ($type, $text) = $r->get_line_burst_or_data(%params);
            if (!$type) {
                sleep 0.2;
                next;
            }
            push @got => [$type, $text];
        }

        is(
            shift @got,
            [line => "A Line\n"],
            "Got the first line"
        );

        is(
            shift @got,
            [burst => "Interrupting cow!\n\n\n"],
            "Got the burst between line fragments"
        );

        is(
            shift @got,
            [line => "Line start ...... line end\n"],
            "Got the interrupted line"
        );

        is(
            [$r->get_line_burst_or_data(%params)],
            [],
            "No Data"
        );

        cleanup();

        worker {
            no warnings 'redefine';
            print $wh "A Line\n";
            $wh->flush();

            my $iter = 0;
            my $wb   = Atomic::Pipe->can('_write_burst');
            *Atomic::Pipe::_write_burst = sub {
                $iter++;
                print $wh "Line start ..." if $iter == 2;
                $wb->(@_);
            };

            $w->write_message("aa" x PIPE_BUF);

            print $wh "... line end\n";
        };

        @got = ();
        while (@got != 3) {
            my ($type, $text) = $r->get_line_burst_or_data(%params);
            if (!$type) {
                sleep 0.2;
                next;
            }
            push @got => [$type, $text];
        }

        is(
            shift @got,
            [line => "A Line\n"],
            "Got the first line"
        );

        is(
            shift @got,
            [message => ("aa" x PIPE_BUF)],
            "Got the message between line fragments"
        );

        is(
            shift @got,
            [line => "Line start ...... line end\n"],
            "Got the interrupted line"
        );

        is(
            [$r->get_line_burst_or_data(%params)],
            [],
            "No Data"
        );

        cleanup();
    };
}

done_testing;

