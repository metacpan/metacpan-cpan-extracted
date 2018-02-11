package Catmandu::Breaker;

our $VERSION = '0.11';

use Moo;
use Carp;
use Catmandu;
use Catmandu::Util;
use Catmandu;
use Data::Dumper;

has verbose  => (is => 'ro', default => sub { 0  });
has maxscan  => (is => 'ro', default => sub { -1 });
has tags     => (is => 'ro');
has _counter => (is => 'ro', default => sub { 0  });

sub counter {
	my ($self) = @_;
	$self->{_counter} = $self->{_counter} + 1;
	$self->{_counter};
}

sub to_breaker {
	my ($self,$identifier,$tag,$value) = @_;

	croak "usage: to_breaker(idenifier,tag,value)"
			unless defined($identifier)
					&& defined($tag) && defined($value);

	$value =~ s{\n}{\\n}mg;

	sprintf "%s\t%s\t%s\n"
    					, $identifier
    					, $tag
    					, $value;
}

sub from_breaker {
    my ($self,$line) = @_;

    my ($id,$tag,$value) = split(/\s+/,$line,3);

    croak "error line not in breaker format : $line"
    		unless defined($id) && defined($tag) && defined($value);

    return +{
    	identifier => $id ,
    	tag        => $tag ,
    	value      => $value
    };
}

sub parse {
    my ($self,$file) = @_;

    my $tags     = $self->tags // $self->scan_tags($file);

    my $importer = Catmandu->importer('Text', file => $file);
    my $exporter = Catmandu->exporter('Stat', fields => $tags);

    my $rec     = {};
    my $prev_id = undef;

    my $it = $importer;

    if ($self->verbose) {
        $it = $importer->benchmark();
    }

    $it->each(sub {
      my $line  = $_[0]->{text};

      my $brk   = $self->from_breaker($line);
      my $id    = $brk->{identifier};
      my $tag   = $brk->{tag};
      my $value = $brk->{value};

      if (defined($prev_id) && $prev_id ne $id) {
         $exporter->add($rec);
         $rec = {};
      }

      $rec->{_id} = $id;

      if (exists $rec->{$tag}) {
          my $prev = ref($rec->{$tag}) eq 'ARRAY' ? $rec->{$tag} : [$rec->{$tag}];
          $rec->{$tag} = [ @$prev , $value ];
      }
      else {
          $rec->{$tag} = $value;
      }

      $prev_id = $id;
    });
    $exporter->add($rec);

    $exporter->commit;
}

sub scan_tags  {
    my ($self,$file) = @_;

    my $tags = {};
    my $io = Catmandu::Util::io($file);

    print STDERR "Scanning:\n" if $self->verbose;
    my $n = 0;
    while (my $line = $io->getline) {
      $n++;
      chop($line);

      print STDERR "..$n\n" if ($self->verbose && $n % 1000 == 0);

      my $brk   = $self->from_breaker($line);
      my $tag   = $brk->{tag};
      $tags->{$tag} = 1 ;

      last if ($self->maxscan > 0 && $n > $self->maxscan);
    }

    $io->close;

    return join(",",sort keys %$tags);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Breaker - Package that exports data in a Breaker format

=head1 SYNOPSIS

  # From the command line

  # Using the default breaker
  $ catmandu convert JSON to Breaker < data.json

  # Break a OAI-PMH harvest
  $ catmandu convert OAI --url http://biblio.ugent.be/oai to Breaker

  # Using a MARC breaker
  $ catmandu convert MARC to Breaker --handler marc < data.mrc

  # Using an XML breaker plus create a list of unique record fields
  $ catmandu convert XML --path book to Breaker --handler xml --fields data.fields < t/book.xml > data.breaker

  # Find the usage statistics of fields in the XML file above
  $ catmandu breaker data.breaker

  # Use the list of unique fields in the report
  $ catmandu breaker --fields data.fields data.breaker

  # verbose output
  $ catmandu breaker -v data.breaker

  # The breaker commands needs to know the unique fields in the dataset to build statistics.
  # By default it will scan the whole file for fields. This can be a very
  # time consuming process. With --maxscan one can limit the number of lines
  # in the breaker file that can be scanned for unique fields
  $ catmandu breaker -v --maxscan 1000000 data.breaker

  # Alternatively the fields option can be used to specify the unique fields
  $ catmandu breaker -v --fields 245a,022a data.breaker

  $ cat data.breaker | cut -f 2 | sort -u > data.fields
  $ catmandu breaker -v --fields data.fields data.breaker

=head1 DESCRIPTION

Inspired by the article "Metadata Analysis at the Command-Line" by Mark Phillips in
L<http://journal.code4lib.org/articles/7818> this exporter breaks metadata records
into the Breaker format which can be analyzed further by command line tools.

=head1 BREAKER FORMAT

When breaking a input using 'catmandu convert {format} to Breaker' each metadata
fields gets transformed into a 'breaker' format:

   <record-identifier><tab><metadata-field><tab><metadata-value><tab><metadatavalue>...

For the default JSON breaker the input format is broken down into JSON-like Paths. E.g.
when give this YAML input:

    ---
    name: John
    colors:
       - black
       - yellow
       - red
    institution:
       name: Acme
       years:
          - 1949
          - 1950
          - 1951
          - 1952

the breaker command 'catmandu convert YAML to Breaker < file.yml' will generate:

    1 colors[]  black
    1 colors[]  yellow
    1 colors[]  red
    1 institution.name  Acme
    1 institution.years[] 1949
    1 institution.years[] 1950
    1 institution.years[] 1951
    1 institution.years[] 1952
    1 name  John

The first column is a counter for each record (or the content of the _id field when present).
The second column provides a JSON path to the data (with the array-paths translated to []).
The third column is the field value.

One can use this output in combination with Unix tools like C<grep>, C<sort>, C<cut>, etc to
inspect the breaker output:

    $ catmandu convert YAML to Breaker < file.yml | grep 'institution.years'

Some input formats, like MARC, the JSON-path format doesn't provide much information
which fields are present in the MARC because field names are part of the data. It is
then possible to use a special C<handler> to create a more verbose breaker
output.

For instance, without a special handler:

    $ catmandu convert MARC to Breaker < t/camel.usmarc
    fol05731351   record[][]  LDR
    fol05731351   record[][]  _
    fol05731351   record[][]  00755cam  22002414a 4500
    fol05731351   record[][]  001
    fol05731351   record[][]  _
    fol05731351   record[][]  fol05731351
    fol05731351   record[][]  082
    fol05731351   record[][]  0
    fol05731351   record[][]  0
    fol05731351   record[][]  a

With the special L<marc handler|Catmandu::Exporter::Breaker::Parser::marc>:

    $ catmandu convert MARC to Breaker --handler marc < t/camel.usmarc

    fol05731351   LDR 00755cam  22002414a 4500
    fol05731351   001 fol05731351
    fol05731351   003 IMchF
    fol05731351   005 20000613133448.0
    fol05731351   008 000107s2000    nyua          001 0 eng
    fol05731351   010a     00020737
    fol05731351   020a  0471383147 (paper/cd-rom : alk. paper)
    fol05731351   040a  DLC
    fol05731351   040c  DLC
    fol05731351   040d  DLC

For the L<Catmandu::PICA> tools a L<pica handler|Catmandu::Exporter::Breaker::Parser::pica> is available.

For the L<Catmandu::XML> tools an L<xml handler|Catmandu::Exporter::Breaker::Parser::xml> is available:

    $ catmandu convert XML --path book to Breaker --handler xml < t/book.xml

=head1 BREAKER STATISTICS

Statistical information can be calculated from a breaker output using the
'catmandu breaker' command:

    $ catmandu convert MARC to Breaker --handler marc < t/camel.usmarc > data.breaker
    $ catmandu breaker data.breaker

    | name | count | zeros | zeros% | min | max | mean | median | mode   | variance | stdev | uniq%| entropy |
    |------|-------|-------|--------|-----|-----|------|--------|--------|----------|-------|------|---------|
    | 001  | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 100  | 3.3/3.3 |
    | 003  | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 10   | 0.0/3.3 |
    | 005  | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 100  | 3.3/3.3 |
    | 008  | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 100  | 3.3/3.3 |
    | 010a | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 100  | 3.3/3.3 |
    | 020a | 9     | 1     | 10.0   | 0   | 1   | 0.9  | 1      | 1      | 0.09     | 0.3   | 90   | 3.3/3.3 |
    | 040a | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 10   | 0.0/3.3 |
    | 040c | 10    | 0     | 0.0    | 1   | 1   | 1    | 1      | 1      | 0        | 0     | 10   | 0.0/3.3 |
    | 040d | 5     | 5     | 50.0   | 0   | 1   | 0.5  | 0.5    | [0, 1] | 0.25     | 0.5   | 10   | 1.0/3.3 |

The output table provides statistical information on the usage of fields in the
original format. We see that the C<001> field was counted 10 times in the data set,
but the C<040d> value is only present 5 times. The C<020a> is empty in 10% (zeros%)
of the records. The C<001> has very unique values (entropy is maximum), but all C<040c>
fields contain the same information (entropy is minimum).

See L<Catmandu::Exporter::Stat> for more information about the statistical fields.

=head1 MODULES

=over

=item * L<Catmandu::Exporter::Breaker>

=item * L<Catmandu::Cmd::breaker>

=back

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::MARC>, L<Catmandu::XML>, L<Catmandu::Stat>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 CONTRIBUTORS

Jakob Voss, C<< nichtich at cpan.org >>

=cut
