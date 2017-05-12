#!perl -w
$| = 1;
use strict;
use Data::Maker;
use Data::Maker::Field::Format;
use Data::Maker::Field::Person;
use Data::Maker::Field::Code;
use Data::Maker::Field::Set;
use Data::Maker::Field::DateTime;
use Data::Maker::Field::Lorem;
use Time::HiRes qw( gettimeofday );

my $count = shift || 100;

my $maker = Data::Maker->new(
  record_count => $count,
  delimiter => "\t",
);

my @test_fields = (
  {     
    name => 'ssn',
    class => 'Data::Maker::Field::Format',
    args => {
      format => '\d\d\d-\d\d-\d\d\d\d'
    }
  },
  {     
    name => 'firstname',
    class => 'Data::Maker::Field::Person::FirstName',
  },
  {     
    name => 'lastname',
    class => 'Data::Maker::Field::Person::LastName',
  },
  {
    name => 'username',
    class => 'Data::Maker::Field::Code',
    args => {
      code => sub {
        my ($this, $maker) = @_;
        my $first = 'John';
        my $last = 'Smith';
        my $username = lc( substr($first, 0, 1) . $last);
        return $username;
      } 
    }   
  },    
  {     
    name => 'gender',
    class => 'Data::Maker::Field::Person::Gender',
    args => {
      name => 'Jacob'
    }
  },
  {     
    name => 'datetime',
    class => 'Data::Maker::Field::DateTime',
    args => {
      start => 1900,
      end => 2009
    }
  },
  {     
    name => 'lorem',
    class => 'Data::Maker::Field::Lorem',
    args => {
      words => 5
    }
  },
  {     
    name => 'ssn',
    class => 'Data::Maker::Field::Person::SSN',
  },
);

for my $field(@test_fields) {
  #print "Benchmarking $field->{class}\n";
  $maker->fields( [ $field ] );
  $maker->reset;
  run_tests($maker, $field);
}

sub run_tests {
  my ($maker, $field) = @_;
  my $start = gettimeofday;
  my $length = 0;
  while (my $record = $maker->next_record) {
    my $rec = $record->delimited;
    if ($length) {
      print "\b" x $length;
    }
    my $count_length = length($count);
    my $string = sprintf("Generated %0${count_length}d of $count %s records...", $maker->generated, $field->{class});
    $length = length($string);
    print $string;
  }
  my $elapsed = gettimeofday - $start;
  my $persec = $count / $elapsed;
  my $summary = sprintf("%s took %.6f seconds", $field->{class}, $elapsed, $persec);
  my $persec_string = sprintf("%.2f/s", $persec);
  printf("\n%-60s %20s\n", $summary, $persec_string);
}

$maker->fields( \@test_fields );
$maker->reset;
run_tests($maker, { class => 'Data::Maker::Record' } );

