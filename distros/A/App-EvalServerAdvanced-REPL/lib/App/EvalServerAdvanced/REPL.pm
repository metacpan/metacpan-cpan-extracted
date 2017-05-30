package App::EvalServerAdvanced::REPL;

use strict;
use warnings;
use Data::Dumper;
use Term::ReadLine;
use IO::Async::Loop;
use IO::Async::Stream;

use App::EvalServerAdvanced::Protocol;
use Exporter 'import';
our @EXPORT = qw/start_repl/;

# ABSTRACT: Example client for App::EvalServerAdvanced

sub fake_prompt {
    my $prompt = shift;
    my @rl_term_set = @Term::ReadLine::TermCap::rl_term_set;
    print $rl_term_set[3], $rl_term_set[0], $prompt, $rl_term_set[1], $rl_term_set[2];
}

sub start_repl {
  my (@args) = @_;

  my $loop = IO::Async::Loop->new();
  my $term = Term::ReadLine->new("Erepl");
  my $seq = 1;

  my $connect_future = $loop->new_future();

  $loop->connect(
      addr => {
         family   => "inet",
         socktype => "stream",
         port     => 14401,
         ip       => "localhost",
      },
      on_stream => sub {
          my $stream = shift;

          $stream->configure(
              on_read => sub {
                  my ($self, $bufref, $eof) = @_;

                  if ($eof) {
                      print "Disconnected\n";
                      exit(1);
                  }

                  my ($res, $message, $nbuf) = decode_message($$bufref);
                  if ($res) {
                      $$bufref = $nbuf;
                      my @rl_term_set = @Term::ReadLine::TermCap::rl_term_set;

                      $|++;
                      if (ref($message) =~ /EvalResponse$/) {
                          print "\n"; # go to a new line
                          my $eseq = $message->sequence;  
                          if (!$message->{canceled}) {
                              my $lines = $message->contents;
                              $lines =~ s/^/$eseq < /gm;
                              print $rl_term_set[3], $lines, "\n\n";
                              fake_prompt("$seq> ");
                          } else {
                              print $rl_term_set[3],"\n$eseq was canceled\n";
                              fake_prompt("$seq> ");
                          }
                      } elsif (ref($message) =~ /Warning$/) {
                          my $eseq = $message->sequence;
                          print $rl_term_set[3],"\nWARN <$eseq> ", $message->message, "\n";
                          fake_prompt("$seq> ");
                      } else {
                          die "Unhandled message: ". Dumper($message);
                      }
                  }

                  return 1;
              }
          );

          $loop->add($stream);
          $connect_future->done($stream);
      },
      on_connect_error => sub {die "no connect"}
   );

  my $stream = $connect_future->get;

  $term->event_loop(sub {
    my $data = shift;
    $data->[1] = $loop->new_future;
    $data->[1]->get;
  }, sub {
    my $fh = shift;
    my $data = [];
    $data->[0] = $loop->watch_io(handle => $fh, on_read_ready => sub { $data->[1]->done });
    $data;
  });

  my $lang = $args[0] // "perl";

  while (my $line = $term->readline("$seq> ")) {
    my $eval = {language => $lang, sequence => $seq, prio => {pr_realtime => {}}, files => [{filename => "__code", contents => $line}, {filename => "mf.txt", contents=>"What did you just call me?"}]};

    my $message = encode_message(eval => $eval);
    $seq++;
    $stream->write($message);
  }

}

;
