use v5.40;
use blib;
use Acme::Parataxis qw[:all];
$|++;

# Set threshold to 100 opcodes (very low for demo)
Acme::Parataxis::set_preempt_threshold(100);
Acme::Parataxis::run(
    sub {
        say 'Starting cooperative preemption demo...';
        my @futures;
        push @futures, Acme::Parataxis->spawn(
            sub {
                my $count = 0;
                while ( $count < 5 ) {
                    say '  [A] iteration ' . ++$count;

                    # busy loop
                    for ( 1 .. 50 ) {
                        my $x = $_ * 2;
                        maybe_yield();
                    }
                }
                say '  [A] finished';
            }
        );
        push @futures, Acme::Parataxis->spawn(
            sub {
                my $count = 0;
                while ( $count < 5 ) {
                    say '  [B] iteration ' . ++$count;
                    for ( 1 .. 50 ) {
                        my $x = $_ * 2;
                        maybe_yield();
                    }
                }
                say '  [B] finished';
            }
        );
        say 'Main spawned both, waiting...';
        $_->await for @futures;
        say 'Main finished waiting.';
    }
);
