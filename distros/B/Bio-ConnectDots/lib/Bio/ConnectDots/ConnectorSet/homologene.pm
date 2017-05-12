package Bio::ConnectDots::ConnectorSet::homologene;
use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
  my ($self) = @_;
  my $input_fh=$self->input_fh;
  #the file start with line with index number 1 
  while (<$input_fh>) {
    chomp;
    if (/^>>/) {
       next unless $self->have_dots;
       return 1;
    }

    my @field = split(/\t/, $_);
    #field[1] is the organism specis, $field[2] is the locuslink id
    $self->put_dot("$field[1]","$field[2]");
    
  } #end of while

  return undef;
} #end of sub

1;
