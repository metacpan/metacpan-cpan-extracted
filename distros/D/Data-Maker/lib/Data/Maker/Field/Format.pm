package Data::Maker::Field::Format;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.09';

has format => ( is => 'rw');

my @digits     = (0..9);
my @letters    = ('a'..'z', 'A'..'Z');
my @word_chars = (@digits, @letters);
my @hex_bytes  = map { sprintf("%02x", $_) } 0..255;

sub generate_value {
  my $this = shift;

  # force copy, in case the format overloads stringify
  my $out = $this->format . '';
  return unless length($out);

  my %map = (
    d => sub { $digits[rand @digits]            },
    l => sub { $letters[rand @letters]          },
    L => sub { uc $letters[rand @letters]       },
    w => sub { $word_chars[rand @word_chars]    },
    W => sub { uc $word_chars[rand @word_chars] },
    x => sub { $hex_bytes[rand @hex_bytes]      },
    X => sub { uc $hex_bytes[rand @hex_bytes]   },
  );

  $out =~ s/\\([dlLwWxX])/ $map{$1}->() /eg;

  return $out;
}


1;
