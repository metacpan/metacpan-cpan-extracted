use strict;
use warnings;
use Test::More;
use constant HAVE_DIFF => eval {
  require Test::Differences;
  Test::Differences::unified_diff();
  1;
};

use CPAN::Changes::Parser;

sub _eq {
  if (HAVE_DIFF) {
    Test::Differences::eq_or_diff(@_[0..2], { context => 5 });
  }
  else {
    goto &Test::More::is;
  }
}

my $parser = CPAN::Changes::Parser->new(version_like => qr/\{\{\s*\$NEXT\s*\}\}/);

for my $log (@ARGV ? @ARGV : glob('corpus/dists/*.changes')) {
  my $content = do {
    open my $fh, '<:raw', $log
      or die "can't read $log: $!";
    local $/;
    <$fh>;
  };
  my $parsed = $parser->_parse($content);
  my $raw = $parsed->{raw_preamble};

  my @entries = @{ $parsed->{releases} || [] };

  while (my $entry = shift @entries) {
    $raw .= $entry->{raw};
    unshift @entries, @{ $entry->{entries} || [] };
  }

  _eq $raw, $content, "raw content properly preserved for $log";
}

done_testing;
