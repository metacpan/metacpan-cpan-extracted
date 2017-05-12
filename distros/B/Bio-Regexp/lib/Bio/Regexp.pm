package Bio::Regexp;

our $VERSION = '0.101';

use v5.10;
use common::sense;

use Data::Alias;
use Regexp::Exhaustive;

use Bio::Regexp::AST;




sub dna { _arg($_[0], 'type', 'dna') }
sub rna { _arg($_[0], 'type', 'rna') }
sub protein { _arg($_[0], 'type', 'protein') }

sub circular { _arg($_[0], 'circular', 1) }
sub linear { _arg($_[0], 'circular', 0) }

sub single_stranded { _arg($_[0], 'strands', 1) }
sub double_stranded { _arg($_[0], 'strands', 2) }

sub strict_thymine_uracil { _arg($_[0], 'strict_thymine_uracil', 1) }
sub strict_case { _arg($_[0], 'strict_case', 1) }

sub no_substr { _arg($_[0], 'no_substr', 1) }


sub _arg_defaults {
  my ($self) = @_;

  $self->{type} //= 'dna';

  if ($self->{type} eq 'dna') {
    $self->{arg}->{strands} //= 2;
  } elsif ($self->{type} eq 'rna') {
    $self->{arg}->{strands} //= 1;
  } elsif ($self->{type} eq 'protein') {
    die "protein search not implemented";
  }
}





sub new {
  my ($class, @args) = @_;

  my $self = {};
  bless $self, $class;

  return $self;
}



sub add {
  my ($self, $regexp) = @_;

  die "Can't add new regexp because regexp has already been compiled" if $self->{compiled_regexp};

  push @{ $self->{regexps} }, $regexp;

  return $self;
}



sub compile {
  my ($self) = @_;

  return if $self->{compiled_regexp};

  $self->_arg_defaults;

  my $regexp_index = 0;
  my @regexp_fragments;

  foreach my $regexp (@{ $self->{regexps} }) {
    ## Parse

    my $ast = Bio::Regexp::AST->new($regexp, $self->{type}, $self->{arg});

    ## Compute meta data

    my ($min, $max) = $ast->compute_min_max;

    $self->{min} = $min if !defined $self->{min} || $min < $self->{min};
    $self->{max} = $max if !defined $self->{max} || $max > $self->{max};

    ## Main "sense" strand

    my $rendered = $ast->render;

    push @regexp_fragments, "$rendered(?{ $regexp_index })";
    $regexp_index++;

    my $component = { regexp => $regexp, };

    $component->{strand} = 1 if $self->{arg}->{strands} == 2;

    push @{ $self->{components} }, $component;

    ## Reverse complement strand

    if ($self->{arg}->{strands} == 2) {
      $ast->reverse_complement;
      $rendered = $ast->render;

      push @regexp_fragments, "$rendered(?{ $regexp_index })";
      $regexp_index++;

      my $component = { regexp => $regexp, strand => 2, };

      push @{ $self->{components} }, $component;
    }
  }

  my $compiled_regexp = ($self->{arg}->{strict_case} ? '' : '(?i)') .
                        '(' .
                        ($self->{arg}->{no_substr} ? '?:' : '') .
                        join('|', @regexp_fragments) .
                        ')';

  {
    use re 'eval';
    $self->{compiled_regexp} = qr{$compiled_regexp};
  }

  return $self;
}



sub match {
  alias my ($self, $input, $callback) = @_;

  $self->compile;

  my @output;

  my @matches = Regexp::Exhaustive::exhaustive($input => $self->{compiled_regexp},
                                               qw[ $1 @- @+ $^R ]);

  foreach my $match (@matches) {
    my $element = {
                    match => $match->[0],
                    start => $match->[1]->[0],
                    end => $match->[2]->[0],
                    %{ $self->{components}->[$match->[3]] },
                  };

    push @output, $element;
  }


  ## Check circular overlap

  if ($self->{arg}->{circular}) {
    my $start = length($input) - $self->{max} + 1;
    $start = 1 if $start < 1;

    my $end = $self->{max} - 1;
    $end = 0 if $end < 0;

    my $input_overlap = substr($input, $start) . substr($input, 0, $end);

    my @matches_overlap = Regexp::Exhaustive::exhaustive($input_overlap => $self->{compiled_regexp},
                                                         qw[ $1 @- @+ $^R ]);

    foreach my $match (@matches_overlap) {
      my $element = {
                      match => $match->[0],
                      start => $match->[1]->[0],
                      end => $match->[2]->[0],
                      %{ $self->{components}->[$match->[3]] },
                    };

      $element->{start} += $start;
      $element->{end} += $start;

      push @output, $element;
    }
  }


  ## Re-order reverse complement start/end

  if ($self->{arg}->{strands} == 2) {
    foreach my $match (@output) {
      ($match->{start}, $match->{end}) = ($match->{end}, $match->{start})
        if $match->{strand} == 2;
    }
  }

  return @output;
}






sub _arg {
  my ($self, $arg, $val) = @_;

  die "Can't set $arg to $val because it was already set to $val" if exists $self->{$arg};
  die "Can't set $arg to $val because regexp has already been compiled" if $self->{compiled_regexp};

  $self->{arg}->{$arg} = $val;

  return $self;
}


1;



__END__

=head1 NAME

Bio::Regexp - Exhaustive DNA/RNA/protein regexp searches

=head1 SYNOPSIS

    my @matches = Bio::Regexp->new->dna
                             ->add('A?GCYY[^G]{2,3}GCGC')
                             ->add('GAATTC')
                             ->circular
                             ->match($input);

    ## Example match:
    {
      'match' => 'AGCTCAAAGCGC',
      'start' => '0',
      'end' => '12',
      'strand' => 1,
      'regexp' => 'A?GCYY[^G]{2,3}GCGC'
    }


=head1 DESCRIPTION

This module is for searching inside DNA or RNA or protein sequences. The sequence to be found is specified by a restricted version of regular expressions. The restrictions allow us to manipulate the regexp in various ways described below. As well as regular expression character classes, bases can be expressed in IUPAC short form (which are kind of like character classes themselves).

The goal of this module is to provide a complete search. Given the particulars of a sequence (DNA/RNA/protein, linear molecule/circular plasmid, single/double stranded) it attempts to figure out all of the possible matches without any false-positive or duplicated matches.

It handles cases where matches overlap in the sequence and cases where the regular expression can match in multiple ways. For circular DNA (plasmids) it will find matches even if they span the arbitrary location in the circular sequence selected as the "start". For double-stranded DNA it will find matches on the reverse complement strand as well.

The typical use case of this module is to search for multiple small patterns in large amounts of input data. Although it is optimised for that task it is also efficient at others. For efficiency, none of the input sequence data is copied at all except to extract matches (but this can be disabled with C<no_substr>) and to implement circular searches (though the amount copied is usually very small).



=head1 INPUT FORMAT

The input string passed to C<match> must be a nucleotide sequence for now (protein sequences will be supported soon). There must be no line breaks or other whitespace, or any other kind of FASTA-like header/data.

If your data does not conform to the description above then the results are undefined and you should sanitise your data before using this module.

If your data is anything other than DNA (the default) you must call one of the type functions like C<rna> or C<protein>:

    my $re = Bio::Regexp->new->rna->add('GAUAUC')->compile;

Normally however C<T> and C<U> are both compiled into C<[TU]> so your patterns will work on DNA and RNA. If you wish to prevent this and throw an error while compiling your regexp, call C<strict_thymine_uracil>.

Unless C<strict_case> is specified, the case of your patterns and the case of your input doesn't matter. I suggest using uppercase everywhere.




=head1 EXHAUSTIVE SEARCH

Most methods of searching nucleotide sequences will only find non-overlapping matches in the input. For example, when searching for the sequence C<AA> in the input C<AAAA>, perl's C<m/AA/g> searches will only return 2 matches:

    AAAA
    --
      --

With this module you get all three matches:

    AAAA
    --
     --
      --

For DNA data this can be useful for finding the comprehensive set of possible molecules that could exist after a restriction enzyme cleaving.




=head1 INTERBASE COORDINATES

All offsets returned by this module are in "interbase coordinates". Rather than the first base in a sequence being described as "base 1" as most biologists might think of it, or even "base 0" as computer scientists might, with interbase coordinates the first base is described as the sequence spanning coordinates 0 through 1.

One of the reasons this is useful is because it allows us to unambiguously specify 0-width sequences like for example endonuclease cut sites. If index-style coordinates are used it is ambiguous whether the cut is before or after.

Unlike with string indices, the start coordinate can be greater than the end coordinate. This happens when C<double_stranded> is set (the default for DNA) and the pattern is found on the reverse complement strand. Use C<single_stranded> if you don't want reverse complement matches.

For circular inputs, interbase coordinates can also be greater than the length of the input. This is interpreted as wrapping back around to the beginning in a modular arithmetic fashion. Similarly, negative coordinates wrap around to the end of the input. "Out-of-range" interbase coordinates are only defined for circular inputs and referencing them on linear inputs will throw errors.




=head1 IUPAC SHORT FORMS

For DNA and RNA, IUPAC incompletely specified nucleotide sequences can be used. These are analogous to regular expression character classes. Just like perl's C<\s> is short for C<[ \r\n\t]>, in IUPAC form C<V> is short for C<[ACG]>, or C<[^T]>. Unless C<strict_thymine_uracil> is in effect this will actually be like C<[^TU]> for both DNA and RNA inputs.

See L<wikipedia|http://en.wikipedia.org/wiki/Nucleic_acid_notation> for the list of IUPAC short forms.



=head1 ADDING MULTIPLE SEARCH PATTERNS

An important feature of this module is that any number of regular expressions can be combined into one so that many patterns can be searched for simultaneously while doing a single pass over the data.

Doing a single pass is generally more efficient because of memory locality and has other positive side-effects. For instance, we can also scan a strand's reverse complement during the pass and therefore avoid copying and reversing the input (which may be quite large).

This module should be able to support quite a large number of simultaneous search patterns although I have some ideas for future optimisations if they prove necessary. Large numbers of patterns may come in handy when building a list of all restriction enzymes that don't cut a target sequence, or finding all PCR primer sites accounting for IUPAC expanded primers.

Multiple patterns can be added at once simply by calling C<add()> multiple times before attempting a C<match> (or a C<compile>):

    my $re = Bio::Regexp->new;

    $re->add($_) for ('GAATTC', 'CCWGG');

    my @matches = $re->match($input);

Which pattern matched is returned as the C<match> key in the returned match results. You should probably have a hash of all your patterns so that you can look them up while processing matches. The way this is implemented is similar to the very useful L<Regexp::Assemble> except without the hacks needed for ancient perl versions.

When matching, only a single pass will be made over the data so as to find all possible locations that either of the added sequences could have matched. Large numbers of patterns should be fairly efficient because the perl 5.10+ regular expression engine uses a trie data structure for such patterns (and 5.10 is the minimum required perl for other reasons).





=head1 CIRCULAR INPUTS

If the C<circular> method is called, the search sequence C<GAATTC> will match the following input:

    ATTCGGGGGGGGGGGGGGGGGGA
    ----                 --

The C<start> and C<end> coordinates for one of the matches will be 21 and 27. Since the input's length is only 23, we know that it must have wrapped around. In this case there will be another match of coordinates at 27 and 21 because C<GAATTC> is a palindromic sequence.

In order to make this efficient even with really long input sequences, this module copies only the maximum length your search pattern could possibly be. Being able to figure out the minimum and maximum sequence lengths is one of the reasons why the types of regular expressions you can use with this module are limited.



=head1 SEE ALSO

L<Bio-Regexp github repo|https://github.com/hoytech/Bio-Regexp>

Presentation about Bio::Regexp and more: L<Getting the most out of regular expressions|http://hoytech.github.io/regexp-presentation/>

L<Bio::Tools::SeqPattern> from the BioPerl distribution also allows the manipulation of patterns but is less advanced than this module. Also, the way L<Bio::Tools::SeqPattern> reverses a regular expression in order to match the reverse complement is... wow. Just wow. :)

L<Bio::Grep> is an interface to various programs that search biological sequences. L<Bio::Grep::Backend::RE> is probably the most comparable to this module.

L<Bio::DNA::Incomplete>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut



TODO:

!! Implement non-capturing groups

?? Implement back references  http://www.bioperl.org/wiki/Regular_expressions_and_Repeats
