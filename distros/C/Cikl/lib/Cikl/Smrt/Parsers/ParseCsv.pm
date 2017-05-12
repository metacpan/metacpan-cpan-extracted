package Cikl::Smrt::Parsers::ParseCsv;

use strict;
use warnings;

use Mouse;
use Cikl::Smrt::Parser;
extends 'Cikl::Smrt::Parser';
use namespace::autoclean;
use Text::CSV_XS;

use constant NAME => 'csv';
sub name { return NAME; }

has 'feed_limit' => (
  is => 'ro',
);

has 'values' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'skipfirst' => (
  is => 'ro',
  isa => 'Num',
  default => 0
);

sub parse {
    my $self = shift;
    my $fh = shift;
    my $broker = shift;

    my $csv = Text::CSV_XS->new();

    my @cols = split(/\s*,\s*/, $self->values);
    
    my $start = 0;
    my $end = undef;
    if(my $l = $self->feed_limit){
        if(ref($l) eq 'ARRAY'){
            ($start,$end) = @{$l};
        } else {
            ($start,$end) = (0,$l-1);
        }
    }
    $start += 1 if($self->skipfirst);

    # Find our way to the first line we need to read.
    my $lineno = -1;
    while (!$fh->eof()) {
      $lineno++;
      last if (defined($end) && $lineno > $end);

      my $row = $csv->getline($fh);

      next if $lineno < $start;

      my $h = {};
      foreach (0 ... $#cols){
        $h->{$cols[$_]} = $row->[$_];
      }
      $broker->emit($h);
    }

    return(undef);
}

__PACKAGE__->meta->make_immutable;

1;
