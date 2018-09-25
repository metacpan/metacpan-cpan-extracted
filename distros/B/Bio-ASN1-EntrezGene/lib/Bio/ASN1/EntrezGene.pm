package Bio::ASN1::EntrezGene;
$Bio::ASN1::EntrezGene::VERSION = '1.73';
use utf8;
use strict;
use warnings;
use Carp qw(carp croak);

# ABSTRACT: Regular expression-based Perl Parser for NCBI Entrez Gene.
# AUTHOR:   Dr. Mingyi Liu <mingyiliu@gmail.com>
# OWNER:    2005 Mingyi Liu
# OWNER:    2005 GPC Biotech AG
# OWNER:    2005 Altana Research Institute
# LICENSE:  Perl_5



sub new
{
  my $class = shift;
  $class = ref($class) if(ref($class));
  my $self = { maxerrstr => 20, @_ };
  bless $self, $class;
  map { $self->input_file($self->{$_}) if($self->{$_}) } qw(file -file);
  map { $self->fh($self->{$_}) if($self->{$_}) } qw(fh -fh);
  return $self;
}


sub maxerrstr
{
  my ($self, $value) = @_;
  $self->{maxerrstr} = $value if $value > 0;
  return $self->{maxerrstr};
}



sub parse
{
  my ($self, $input, $compact, $noreset) = @_;
  $input || croak "must have input!\n";
  $self->{input} = $input;
  $self->{filename} = "input" unless $self->{filename};
  $self->{linenumber} = 1 unless $self->{linenumber} && $noreset;
  $self->{depth} = 0;
  my $result;
  eval
  {
    $result = $self->_parse(); # no need to reset $self->{depth} or linenumber
  };
  if($@)
  {
    if($@ !~ /^Data Error:/)
    {
      croak "non-conforming data broke parser on line $self->{linenumber} in $self->{filename}\n".
            "possible cause includes randomly inserted brackets in input file before line $self->{linenumber}\n".
            "first $self->{maxerrstr} (or till end of input) characters including the non-conforming data:\n" .
            substr($self->{input}, pos($self->{input}), $self->{maxerrstr}) . "\nRaw error mesg: $@\n";
    }
    else { die $@ }
  }
  trimdata($result, $compact);
  return $result;
}


sub input_file
{
  my ($self, $filename) = @_;
  # in case user's Perl system can't handle large file. Assuming Unix, otherwise raise error
  local *IN; # older styled code to enable module to work with perl 5.005_03
  open(*IN, $filename) ||
  ($! =~ /too large/i && open(*IN, "cat $filename |")) ||
    croak "can't open $filename! -- $!\n";
  $self->{fh} = *IN;
  $self->{filename} = $filename;
  $self->{linenumber} = 0; # reset line number
}


sub next_seq
{
  my ($self, $compact) = @_;
  $self->{fh} || croak "you must pass in a file name or handle through new() or input_file() first before calling next_seq!\n";
  local $/ = "Entrezgene ::= {"; # set record separator
  while($_ = readline($self->{fh}))
  {
    chomp;
    next unless /\S/;
    my $tmp = (/^\s*Entrezgene(-Set)? ::= (\{.*)/si)? $2 : "{" . $_; # get rid of the 'Entrezgene ::= ' at the beginning of Entrez Gene record
    return $self->parse($tmp, $compact, 1); # 1 species no resetting line number
  }
}


sub _parse
{
  my ($self, $flag) = @_;
  my $data;
  while(1)
  {
    # changing orders of regex if/elsif statements made little difference. current order is close to optimal
    if($self->{input} =~ /\G[ \t]*,?[ \t]*\n/cg) # cleanup leftover
    {
      $self->{linenumber}++;
      next;
    }
    if($self->{input} =~ /\G[ \t]*}/cg)
    {
      if(!($self->{depth}--) && $self->{input} =~ /\S/)
      {
        croak "Data Error: extra (mismatched) '}' found on line $self->{linenumber} in $self->{filename}!\n";
      }
      return $data
    }
    elsif($self->{input} =~ /\G[ \t]*{/cg)
    {
      $self->{depth}++;
      push(@$data, $self->_parse())
    }
    elsif($self->{input} =~ /\G[ \t]*([\w-]+)(\s*)/cg)
    {
      my ($id, $lines) = ($1, $2);
      # we're prepared for NCBI to make the format even worse:
      # note: to count line numbers right for text files on different OS, I'm sacrificing much speed (maybe I shouldn't worry so much)
      $self->{linenumber} += $lines =~ s/\n//g || $lines =~ s/\r//g; # count by *NIX/Win or Mac
      my $tmp;
      # we put \s* in lookahead for linenumber counting purpose (which slows things down)
      if(($self->{input} =~ /\G"((?:[^"]+|"")*)"(?=\s*[,}])/cg && ++$tmp) ||
         $self->{input} =~ /\G([\w-]+)(?=\s*[,}])/cg)
      {
        my $value = $1;
        if($tmp) # slight speed optimization, not really necessary since regex is fast enough
        {
          $value =~ s/""/"/g;
          $self->{linenumber} += $value =~ s/\n//g || $value =~ s/\r//g; # count by *NIX/Win or Mac
          $value =~ s/[\r\n]+//g; # in case it's Win format
        }
        if(ref($data->{$id})) { push(@{$data->{$id}}, $value) } # hash value is not a terminal (or have multiple values), create array to avoid multiple same-keyed hash overwrite each other
        elsif($data->{$id}) { $data->{$id} = [$data->{$id}, $value] } # hash value has a second terminal value now!
        else { $data->{$id} = $value } # the first terminal value
      }
      elsif($self->{input} =~ /\G\{/cg)
      {
        $self->{depth}++;
        push(@{$data->{$id}}, $self->_parse());
      }
      elsif($self->{input} =~ /\G(?=[,}])/cg) { push(@$data, $id) }
      else # must be "id value value" format
      {
        $self->{depth}++;
        push(@{$data->{$id}}, $self->_parse(1))
      }
      if($flag)
      {
        if(!($self->{depth}--) && $self->{input} =~ /\S/)
        {
          croak "Data Error: extra (mismatched) '}' found on line $self->{linenumber} in $self->{filename}!\n";
        }
        return $data;
      }
    }
    elsif($self->{input} =~ /\G[ \t]*"((?:[^"]+|"")*)"(?=\s*[,}])/cg)
    {
      my $value = $1;
      $value =~ s/""/"/g;
      $self->{linenumber} += $value =~ s/\n//g || $value =~ s/\r//g; # count by *NIX/Win or Mac
      $value =~ s/[\r\n]+//g; # in case it's Win format
      push(@$data, $value)
    }
    else # end of input
    {
      my ($pos, $len) = (pos($self->{input}), length($self->{input}));
      if($pos != $len && $self->{input} =~ /\G\s*\S/cg) # problem with parsing, must be non-conforming data
      {
        croak "Data Error: none conforming data found on line $self->{linenumber} in $self->{filename}!\n" .
              "first $self->{maxerrstr} (or till end of input) characters including the non-conforming data:\n" .
              substr($self->{input}, $pos, $self->{maxerrstr}) . "\n";
      }
      elsif($self->{depth} > 0)
      {
        croak "Data Error: missing '}' found at end of input in $self->{filename}!";
      }
      elsif($self->{depth} < 0)
      {
        croak "Data Error: extra (mismatched) '}' found at end of input in $self->{filename}!";
      }
      return $data;
    }
  }
}

# following copied directly from my Pipeline::Util::util just to make this module
# more self-sufficient. Changes should be made over in that module though.

# trims arrayrefs that points to one-element array to slims the
# data structure down (calls Pipeline::Util::util::trimdata)
# something like
#    'comments' => ARRAY(0x898be94)
#       0  ARRAY(0x883fc54)
#          0  ARRAY(0x886aef4)
#             0  HASH(0x884d554)
#                'heading' => 'LocusTagLink'
#                'source' => ARRAY(0x8810714)
#                   0  ARRAY(0x8a7df18)
#                      0  ARRAY(0x889f940)
#                         0  HASH(0x886ada4)
#                            'src' => ARRAY(0x88454fc)
#                               0  ARRAY(0x8845598)
#                                  0  HASH(0x898c0ec)
#                                     'db' => 'HGNC'
#                                     'tag' => ARRAY(0x898bfb4)
#                                        0  HASH(0x898c164)
#                                           'id' => 5
# becomes this if $flag == 1:
#    'comments' => ARRAY(0x8840014)
#       0  HASH(0x884d8a4)
#          'heading' => 'LocusTagLink'
#          'source' => HASH(0x8a9869c)
#             'src' => HASH(0x884534c)
#                'db' => 'HGNC'
#                'tag' => HASH(0x88453c4)
#                   'id' => 5
# so now  $hash->{comments}->[0]->[0]->[0]->{source}->[0]->[0]->[0]->{src}->[0]->[0]->{tag}->[0]->{id}
# becomes $hash->{comments}->[0]->{source}->{src}->{tag}->{id}
# this may create problem as array might suddenly change to hash depending on whether it
# has multiple elements or not.  So set $flag to 2 or 0/undef would disallow trimming that
# would lead to data type change, thus resulting in data structure like:
#    'comments' => ARRAY(0x88617e8)
#       0  HASH(0x889d578)
#          'heading' => 'LocusTagLink'
#          'source' => ARRAY(0x8912244)
#             0  HASH(0x8a5d648)
#                'src' => ARRAY(0x8a2203c)
#                   0  HASH(0x8a1af10)
#                      'db' => 'HGNC'
#                      'tag' => ARRAY(0x8a1add8)
#                         0  HASH(0x8a1af88)
#                            'id' => 5
# still not the safest, but saves some hassle writing code


sub trimdata
{
  my ($ref, $flag) = @_;
  $flag = 2 unless $flag;
  return if $flag == 3 || !ref($ref);
  if(ref($ref) ne 'ARRAY') # allows for object refs
  {
    my @keys;
    eval { @keys = keys %$ref }; # let's be careful and check if it can work as a hash
    return if $@;
    foreach my $key (@keys)
    {
      my $tmp = $ref->{$key};
      while(ref($tmp) eq 'ARRAY' && @$tmp == 1)
      {
        last if($flag == 2 && ref($tmp->[0]) ne 'ARRAY');
        $tmp = $tmp->[0]
      }
      $ref->{$key} = $tmp;
      trimdata($ref->{$key}, $flag) if(ref($ref->{$key}))
    }
  }
  else
  {
    # since the only situations where we would get an array of array is
    # when ASN file has a bracket of brackets (otherwise we'd get at least
    # a hash), it makes sense to reduce the arrayrefs to one level
    foreach my $item (@$ref)
    {
      my $tmp = $item;
      while(ref($tmp) eq 'ARRAY' && @$tmp == 1)
      {
        $tmp = $tmp->[0];
      }
      $item = $tmp;
      trimdata($item, $flag) if(ref($item))
    }
  }
}


sub fh
{
  my ($self, $filehandle) = @_;
  if($filehandle)
  {
    $self->{fh} = $filehandle;
    $self->{linenumber} = 0; # reset line number
  }
  return $self->{fh};
}


sub rawdata
{
  my $self = shift;
  return "Entrezgene ::= $self->{input}";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::ASN1::EntrezGene - Regular expression-based Perl Parser for NCBI Entrez Gene.

=head1 VERSION

version 1.73

=head1 SYNOPSIS

  use Bio::ASN1::EntrezGene;

  my $parser = Bio::ASN1::EntrezGene->new('file' => "Homo_sapiens");
  while(my $result = $parser->next_seq)
  {
    # extract data from $result, or Dumpvalue->new->dumpValue($result);
  }

  # a new way to get the $result data hash for a particular gene id:
  use Bio::ASN1::EntrezGene::Indexer;
  my $inx = Bio::ASN1::EntrezGene::Indexer->new(-filename => 'entrezgene.idx');
  my $seq = $inx->fetch_hash(10); # returns $result for Entrez Gene record
                                  # with geneid 10
  # note that the index file 'entrezgene.idx' can be created as follows
  my $inx = Bio::ASN1::EntrezGene::Indexer->new(
    -filename => 'entrezgene.idx',
    -write_flag => 'WRITE');
  $inx->make_index('Homo_sapiens', 'Mus_musculus'); # files come from NCBI download

  # for more detail please refer to Bio::ASN1::EntrezGene::Indexer perldoc

=head1 DESCRIPTION

Bio::ASN1::EntrezGene is a regular expression-based Perl Parser for NCBI Entrez
Gene genome databases (L<http://www.ncbi.nih.gov/entrez/query.fcgi?db=gene>).  It
parses an ASN.1-formatted Entrez Gene record and returns a data structure that
contains all data items from the gene record.

The parser will report error & line number if input data does not conform to the
NCBI Entrez Gene genome annotation file format.

Note that it is possible to provide reading of all NCBI's ASN.1-formatted
files through simple variations of the Entrez Gene parser (I need more
investigation to be sure, but at least the sequence parser is a very simple
variation on Entrez Gene parser and works well).

It took the parser version 1.0 11 minutes to parse the human genome Entrez Gene
file on one 2.4 GHz Intel Xeon processor.  The addition of validation and error
reporting in 1.03 and handling of new Entrez Gene format slowed the parser down
about 40%.

Since V1.07, this package also included an indexer that runs pretty fast (it
takes 21 seconds for the indexer to index the human genome on the same
processor).  Therefore the combination of the modules would allow user to
retrieve and parse arbitrary records.

=head1 ATTRIBUTES

=head2 maxerrstr

  Parameters: $maxerrstr (optional) - maximum number of characters after
                offending element, used by error reporting, default is 20
  Example:    $parser->maxerrstr(20);
  Function:   get/set maxerrstr.
  Returns:    maxerrstr.
  Notes:

=head2 input_file

  Parameters: $filename for file that contains Entrez Gene record(s)
  Example:    $parser->input_file($filename);
  Function:   Takes in name of a file containing Entrez Gene records.
              opens the file and stores file handle
  Returns:    none.
  Notes:      Attempts to open file larger than 2 GB even on Perl that
                does not support 2 GB file (accomplished by calling
                "cat" and piping output. On OS that does not have "cat"
                error message will be displayed)

=head1 METHODS

=head2 new

  Parameters: maxerrstr => 20 (optional) - maximum number of characters after
                offending element, used by error reporting, default is 20
              file or -file => $filename (optional) - name of the file to be
                parsed. call next_seq to parse!
              fh or -fh => $filehandle (optional) - handle of the file to be
                parsed.
  Example:    my $parser = Bio::ASN1::EntrezGene->new();
  Function:   Instantiate a parser object
  Returns:    Object reference
  Notes:      Setting file or fh will reset line numbers etc. that are used
                for error reporting purposes, and seeking on file handle would
                mess up linenumbers!

=head2 parse

  Parameters: $string that contains Entrez Gene record,
              $trimopt (optional) that specifies how the data structure
                returned should be trimmed. 2 is recommended and
                default
              $noreset (optional) that species that line number should not
                be reset
              DEPRECATED as external function!!! Do not call this function
                directly!  Call next_seq() instead
  Example:    my $value = $parser->parse($text); # DEPRECATED as
                # external function!!! Do not call this function
                # directly!  Call next_seq() instead
  Function:   Takes in a string representing Entrez Gene record, parses
                the record and returns a data structure.
  Returns:    A data structure containing all data items from the Entrez
                Gene record.
  Notes:      DEPRECATED as external function!!! Do not call this function
                directly!  Call next_seq() instead
              $string should not contain 'EntrezGene ::=' at beginning!

=head2 next_seq

  Parameters: $trimopt (optional) that specifies how the data structure
                returned should be trimmed. option 2 is recommended and
                default
  Example:    my $value = $parser->next_seq();
  Function:   Use the file handle generated by input_file, parses the next
                the record and returns a data structure.
  Returns:    A data structure containing all data items from the Entrez
                Gene record.
  Notes:      Must pass in a filename through new() or input_file() first!
              For details on how to use the $trimopt data trimming option
                please see comment for the trimdata method. An option
                of 2 is recommended and default
              The acceptable values for $trimopt include:
                1 - trim as much as possible
                2 (or 0, undef) - trim to an easy-to-use structure
                3 - no trimming (in version 1.06, prior to version
                    1.06, 0 or undef means no trimming)

=head2 trimdata

  Parameters: $hashref or $arrayref
              $trimflag (optional, see Notes)
  Example:    trimdata($datahash); # using the default flag
  Function:   recursively process all attributes of a hash/array
              hybrid and get rid of any arrayref that points to
              one-element arrays (trims data structure) depending on
              the optional flag.
  Returns:    none - trimming happenes in-place
  Notes:      This function is useful to compact a data structure produced by
                Bio::ASN1::EntrezGene::parse.
              The acceptable values for $trimopt include:
                1 - trim as much as possible
                2 (or 0, undef) - trim to an easy-to-use structure
                3 - no trimming (in version 1.06, prior to version
                    1.06, 0 or undef means no trimming)

=head2 fh

  Parameters: $filehandle (optional)
  Example:    trimdata($datahash); # using the default flag
  Function:   getter/setter for file handle
  Returns:    file handle for current file being parsed.
  Notes:      Use with care!
              Line number report would not be corresponding to file's line
                number if seek operation is performed on the file handle!

=head2 rawdata

  Parameters: none
  Example:    my $data = $parser->rawdata();
  Function:   Get the entrez gene data file that was just parsed
  Returns:    a string containing the ASN1-formatted Entrez Gene record
  Notes:      Must first parse a record then call this function!
              Could be useful in interpreting line number value in error
                report (if user did a seek on file handle right before parsing
                call)

=head1 INTERNAL METHODS

=head2 _parse

NCBI's Apr 05, 2005 format change forced much usage of lookahead, which would for
sure slows parser down.  But can't code efficiently without it.

=head1 PREREQUISITE

None.

=head1 INSTALLATION

Bio::ASN1::EntrezGene package can be installed & tested as follows:

  perl Makefile.PL
  make
  make test
  make install

=head1 SEE ALSO

The parse_entrez_gene_example.pl script included in this package (please
see the Bio-ASN1-EntrezGene-x.xx/examples directory) is a very
important and near-complete demo on using this module to extract all data
items from Entrez Gene records.  Do check it out because in fact, this
script took me about 3-4 times more time to make for my project than the
parser V1.0 itself. Note that the example script was edited to leave
out stuff specific to my internal project.

For details on various parsers I generated for Entrez Gene, example scripts that
uses/benchmarks the modules, please see L<http://sourceforge.net/projects/egparser/>.
Those other parsers etc. are included in V1.05 download.

=head1 CITATION

Liu, Mingyi, and Andrei Grigoriev. "Fast parsers for Entrez Gene."
Bioinformatics 21, no. 14 (2005): 3189-3190.

=head1 OPERATION SYSTEMS SUPPORTED

Any OS that Perl runs on.

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bio-asn1-entrezgene/issues

=head1 AUTHOR

Dr. Mingyi Liu <mingyiliu@gmail.com>

=head1 COPYRIGHT

This software is copyright (c) 2005 by Mingyi Liu, 2005 by GPC Biotech AG, and 2005 by Altana Research Institute.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
