package Data::Maker::Field::Code;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.09';

has code => ( is => 'rw', isa => 'CodeRef');

sub generate_value {
  my ($this, $maker) = @_;
  if ($this->code && (ref($this->code) eq 'CODE') ) {
    &{$this->code}($this, $maker);
  } else {
    die "A field of class Data::Maker::Field::Code must have a \"code\" attribute passed, which must be a code reference";
  }
}

1;

__END__

=head1 NAME

Data::Maker::Field::Code - A L<Data::Maker> field class that generates its data based on a code reference.   It was written specifically to allow for certain fields to be based on the value of some other field in the same record.

=head1 SYNOPSIS

  use Data::Maker;
  use Data::Maker::Field::Person::FirstName;
  use Data::Maker::Field::Person::LastName;
  use Data::Maker::Field::Code;

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [
      {
        name => 'firstname',
        class => 'Data::Maker::Field::Person::FirstName'
      },
      {
        name => 'lastname',
        class => 'Data::Maker::Field::Person::LastName'
      },
      {
        name => 'username',
        class => 'Data::Maker::Field::Code',
        args => {
          code => sub {
            my ($this, $maker) = @_;
            my $first = $maker->in_progress('firstname');
            my $lastname = $maker->in_progress('lastname');
            my $username = lc( substr($first, 0, 1) . $lastname );
            return $username;
          }
        }
      },
    ]
  );

  while(my $record = $maker->next_record) {
    print $record->username .  "\n";
  }

=head1 DESCRIPTION

Data::Maker::Field::Code takes a single argument, C<code>, whose value must be a code reference that is run to obtain the value of this field.

This class can be used when you need the value of one field to be derived from the value of another field.  This can be done using Data::Maker's L<in_progress|Data::Maker/in_progress> method, as in the example above.

