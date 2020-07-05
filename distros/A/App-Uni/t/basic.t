#!perl
use v5.10.0;

use App::Uni;
use SelectSaver;
use Test::More;

{
  my $capture = q{};
  open my $fh, '>:encoding(UTF-8)', \$capture
    or die "error opening output string";

  {
    my $saver = SelectSaver->new($fh);
    App::Uni->run(qw(smiling face));
    close $fh or die "error closing capture string: $!";
  }

  my @lines = split /\n/, $capture;

  my $matches = @lines;
  ok($matches > 0, "we found $matches smiling faces");
}

done_testing;
