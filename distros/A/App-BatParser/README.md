# NAME

App::BatParser - Parse DOS .bat and .cmd files

# SYNOPSYS

```perl
use App::BatParser;
use Path::Tiny;
use Data::Dumper;

my $parser = App::BatParser->new;
my $bat_string = Path::Tiny::path('t/cmd/simple.cmd')->slurp;

say Dumper($parser->parse($bat_string));

```

# METHODS

## parse

Parses the text as a bat/cmd file

### Returns

Hash representation of file on success, empty list on fail

TODO: Exception on fail
