use strict;
use warnings;
use Test::More;
use constant HAVE_DIFF => eval {
  require Test::Differences;
  Test::Differences::unified_diff();
  1;
};

use CPAN::Changes::Parser;
use Getopt::Long qw(:config gnu_getopt no_auto_abbrev no_ignore_case);
use Data::Dumper ();
use File::Spec;

sub _dump {
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Useqq = 1;
  Data::Dumper::Dumper(@_);
}

sub _eq {
  if (HAVE_DIFF) {
    Test::Differences::eq_or_diff(_dump($_[0]), _dump($_[1]), $_[2], { context => 5 });
  }
  elsif (ref $_[0] && ref $_[1]) {
    goto &Test::More::is_deeply;
  }
  else {
    goto &Test::More::is;
  }
}

GetOptions(
  'update' => \(my $update),
) or die "Bad command line arguments.\n";

my $parser = CPAN::Changes::Parser->new(version_like => qr/\{\{\s*\$NEXT\s*\}\}/);

for my $log (@ARGV ? @ARGV : glob('corpus/dists/*.changes')) {
  my $content = do {
    open my $fh, '<:raw', $log
      or die "can't read $log: $!";
    local $/;
    <$fh>;
  };
  my $parsed_file = $log;
  $parsed_file =~ s/\.changes$/.parsed/;
  my $parsed = $parser->_parse($content);

  if ($update) {
    open my $fh, '>', $parsed_file
      or die "can't write $parsed_file: $!";
    print { $fh } _dump($parsed);
    close $fh;
    pass "updated $parsed_file";
  }
  else {
    my $wanted = do File::Spec->rel2abs($parsed_file) or die $@||$!;
    _eq $parsed, $wanted, "$log parsed into expected form";
  }
}

done_testing;
