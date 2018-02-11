package Catmandu::Cmd::breaker;

use Catmandu::Sane;

our $VERSION = '0.11';

use parent 'Catmandu::Cmd';
use Catmandu;

use Catmandu::Breaker;
use Path::Tiny;
use namespace::clean;

sub command_opt_spec {
    (
        ["verbose|v","verbose output"],
        ["maxscan=i","maximum number of lines to scan for uniq fields (default -1 = unlimited)"],
        ["fields=s","a file or comma delimited string of unique fields to use"],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    unless (@$args == 1) {
        say STDERR "usage: $0 breaker file\n";
        exit 1;
    }

    my $file = $args->[0];

    my $maxscan = $opts->maxscan // -1;

    my $tags;

    if ($opts->fields) {
        if (-r $opts->fields) {
            $tags = join "," , path($opts->fields)->lines_utf8({chomp =>1});
        }
        else {
            $tags = $opts->tags;
        }
    }
    my $breaker = Catmandu::Breaker->new(
                    verbose => $opts->verbose,
                    maxscan => $maxscan,
                    tags    => $tags
                    );

    $breaker->parse($file);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::breaker - Parse Catmandu::Breaker exports

=head1 EXAMPLES

  catmandu breaker [<OPTIONS>] <BREAKER.FILE>

  $ catmandu convert XML --path book to Breaker --handler xml < t/book.xml > data.breaker
  $ catmandu breaker data.breaker

  # verbose output
  $ catmandu breaker -v data.breaker

  # The breaker command needs to know the unique fields in the dataset to build statistics
  # By default it will scan the whole file for fields. This can be a very
  # time consuming process. With --maxscan one can limit the number of lines
  # in the breaker file that can be scanned for unique fields
  $ catmandu breaker -v --maxscan 1000000 data.breaker

  # Alternatively the fields option can be used to specify the unique fields
  $ catmandu breaker -v --fields 245a,022a data.breaker

  $ cat data.breaker | cut -f 2 | sort -u > fields.txt
  $ catmandu breaker -v --fields fields.txt data.breaker

=cut
