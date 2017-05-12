package Bio::Regexp::AST;

use common::sense;

use List::MoreUtils;

my $parser;

{
  use Regexp::Grammars;

  $parser = qr{
    ## MAIN

    <regexp>

    ## GRAMMAR

    <token: regexp>
    ^
      <[element]>*
    $

    <token: element>
      <literal> <repeat>? |
      <charclass> <repeat>?

    <token: literal>
      [a-zA-Z]

    <token: charclass>
      \[ <negate_charclass>? <[literal]>+ \]

    <token: negate_charclass>
      \^

    <token: repeat>
      \{
         (?:
            <max=(?: \d+ )> <min=(?{ $MATCH{max} })> |
            <min=(?: \d+ )> , <max=(?: \d+ )>
         )
      \} |
      \? <min=(?{ 0 })> <max=(?{ 1 })>
  }xs;
}


sub new {
  my ($class, $regexp, $type, $arg) = @_;

  my $self = {
               regexp => $regexp,
               type => $type,
               strict_thymine_uracil => $arg->{strict_thymine_uracil},
             };

  bless $self, $class;

  $regexp =~ $parser;

  my $parsed = \%/;

  my @components;

  foreach my $element (@{ $parsed->{regexp}->{element} }) {
    my $component = {};

    if ($element->{literal}) {
      $component->{chars} = [ $element->{literal} ];
    } elsif ($element->{charclass}) {
      $component->{chars} = $element->{charclass}->{literal};
      $component->{negate} = 1 if $element->{charclass}->{negate_charclass};
    } else {
      die "unknown element type";
    }

    if ($element->{repeat}) {
      $component->{min} = $element->{repeat}->{min};
      $component->{max} = $element->{repeat}->{max};
    } else {
      $component->{min} = 1;
      $component->{max} = 1;
    }

    push @components, $component;
  }

  $self->{components} = \@components;

  if ($type eq 'dna' || $type eq 'rna') {
    $self->normalize_dna_rna;
  } else {
    die "protein not impl";
  }

  return $self;
}


sub compute_min_max {
  my ($self) = @_;

  my $min = my $max = 0;

  for my $component (@{ $self->{components} }) {
     $min += $component->{min};
     $max += $component->{max};
  }

  return ($min, $max);
}


my $iupac_lookup = {
  R => [ qw/A G/ ],
  Y => [ qw/C T/ ],
  W => [ qw/A T/ ],
  S => [ qw/C G/ ],
  M => [ qw/A C/ ],
  K => [ qw/G T/ ],
  H => [ qw/A C T/ ],
  B => [ qw/C G T/ ],
  V => [ qw/A C G/ ],
  D => [ qw/A G T/ ],
  N => [ qw/A C G T/ ],
};



sub normalize_dna_rna {
  my ($self) = @_;

  foreach my $component (@{ $self->{components} }) {
    my @chars = @{ $component->{chars} };

    if ($self->{strict_thymine_uracil}) {
      die "U in DNA pattern and strict_thymine_uracil specified"
        if $self->{type} eq 'dna' && grep { $_ eq 'U' } @chars;

      die "T in RNA pattern and strict_thymine_uracil specified"
        if $self->{type} eq 'rna' && grep { $_ eq 'T' } @chars;
    }

    ## Temporarily normalize U to T
    @chars = map { $_ eq 'U' ? 'T' : $_ } @chars;

    ## Expand IUPAC codes
    @chars = map { @{ $iupac_lookup->{$_} || [$_] } } @chars;

    ## Remove uniques
    @chars = List::MoreUtils::uniq(@chars);

    ## Negate
    if ($component->{negate}) {
      my @negated;

      foreach my $base (qw/ A T C G /) {
        push @negated, $base unless grep { $_ eq $base } @chars;
      }

      die "can't negate all encompassing character class" if !@negated;

      @chars = @negated;
    }

    $component->{chars} = \@chars;
  }
}



sub reverse_complement {
  my ($self) = @_;

  $self->{components} = [ reverse @{ $self->{components} } ];

  foreach my $component (@{ $self->{components} }) {
    my @chars = @{ $component->{chars} };

    @chars = map { $_ eq 'A' ? 'T' :
                   $_ eq 'T' ? 'A' :
                   $_ eq 'C' ? 'G' :
                   $_ eq 'G' ? 'C' :
                   die "unrecognised base: $_"
                 } @chars;

    $component->{chars} = \@chars;
  }
}



sub render {
  my ($self) = @_;

  my $output = '';

  foreach my $component (@{ $self->{components} }) {
    my @chars = @{ $component->{chars} };

    ## Re-normalize T to U
    if ($self->{type} eq 'rna') {
      @chars = map { $_ eq 'T' ? 'U' : $_ } @chars;
    }

    ## Support T and U unless strict
    if (!$self->{strict_thymine_uracil}) {
      @chars = map { $_ eq 'T' || $_ eq 'U' ? ('T', 'U') : $_ } @chars;
    }

    if (@chars == 1) {
      $output .= $chars[0];
    } else {
      $output .= '[' . join('', @chars) . ']';
    }

    if ($component->{min} == $component->{max}) {
      $output .= "{$component->{min}}" unless $component->{min} == 1;
    } elsif ($component->{min} == 0 && $component->{max} == 1) {
      $output .= "?";
    } else {
      $output .= "{$component->{min},$component->{max}}";
    }
  }

  return $output;
}



1;
