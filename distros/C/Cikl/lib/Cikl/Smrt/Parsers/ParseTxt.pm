package Cikl::Smrt::Parsers::ParseTxt;

use strict;
use warnings;

use Mouse;
use Cikl::Smrt::Parser;
extends 'Cikl::Smrt::Parser';
use namespace::autoclean;

use constant NAME => 'txt';
sub name { return NAME; }

has 'regex' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'regex_values' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

sub parse {
    my $self = shift;
    my $fh = shift;
    my $broker = shift;
    my $re = $self->regex;
    $re = qr/$re/;
    
    my @cols = split(/\s*,\s*/, $self->regex_values);

    # This is more memory efficient.
    while(!$fh->eof()) {
        my $line = $fh->getline();
        next if($line =~ /^(#|<|$)/);
        # Strip \n\r off the end of the line.
        $line =~ s/[\r\n]+$//;

        my @m = ($line =~ $re);
        next unless(@m);
        my $h = {};
        foreach (0 ... $#cols){
            $m[$_] = '' unless($m[$_]);
            for($m[$_]){
                s/^\s+//;
                s/\s+$//;
            }
            $h->{$cols[$_]} = $m[$_];
        }
        # a work-around, we do some of this in iodef::pb::simple too
        # adding this here makes the debugging messages a little less complicated
        if($h->{'address_mask'}){
            $h->{'address'} .= '/'.$h->{'address_mask'};
        }
        $broker->emit($h);
    }
    return(undef);

}

__PACKAGE__->meta->make_immutable;

1;
