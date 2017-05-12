package Config::MVP::Reader::Test;
use Moose;
extends 'Config::MVP::Reader';
with qw(Config::MVP::Reader::Findable::ByExtension);

sub default_extension { 'mvp-test' }

sub read_into_assembler {
  my ($self, $location, $assembler) = @_;

  my $filename = $location;

  open my $fh, '<', $filename or die "can't read $filename: $!";

  LINE: while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ m{\A\s*(;.+)?\z}; # skip blanks, comments

    if ($line =~ m{\A(\S+)\s*=\s*(\S+)\z}) {
      $assembler->add_value($1, $2);
      next LINE;
    }

    if ($line =~ m{\A\[(\S+)(?:\s+(\S+?))?\]\z}) {
      $assembler->change_section($1, $2);
      next LINE;
    }

    die "don't know how to handle this line: $line\n";
  }

  return $assembler->sequence;
}

1;
