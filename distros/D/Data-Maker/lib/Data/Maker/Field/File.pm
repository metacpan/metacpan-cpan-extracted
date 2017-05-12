package Data::Maker::Field::File;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.08';

has filename => ( is => 'rw' );

sub generate_value {
  my $this = shift;
  my $maker = shift;
  if (my $data = $this->data($maker)) {
    my $key = '_record_count';
    if (my $name = $this->name) {
      my $counts = $maker->record_counts;
      $counts->{$name} = @{$data} unless $counts->{$name};
      return $data->[ rand $counts->{$name} ];
    }
  }
}

sub data {
  my $this = shift;
  my $maker = shift;
  my $key = $this->name;

  if (my $cached = $maker->data_sources->{$key}) {
    return $cached;
  }
  if ($this->filename) {
    if (-e $this->filename) {
      open(IN, $this->filename);
      my @data = (<IN>);
      chomp @data;
      close(IN);
      $maker->data_sources->{$key} = \@data;
    } else {
      confess "File " . $this->filename . " does not exist";
    }
  }
}

1;
