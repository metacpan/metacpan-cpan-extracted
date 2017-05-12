package Data::Maker::Field;
use Moose::Role;

our $VERSION = '0.28';

has name      => ( is => 'rw' );
has class     => ( is => 'rw' );
has args      => ( is => 'rw', isa => 'HashRef' );
has value     => ( is => 'rw' );
has formatted => ( is => 'rw', default => sub { shift->value }  );

requires 'generate_value';

sub generate {
  my $this = shift;
  my $maker = shift;
  my $value = $this->generate_value($maker);
  if (my $code = $this->formatted) {
    $value = &{$code}($value);
  }
  $this->value( $value );
  return $this;
}

sub output {
  my $this = shift;
  $this->value;
}


1;


__END__

=head1 NAME

Data::Maker::Field - a L<Moose> role that is consumed by all Data::Maker field classes; the ones included with Data::Maker and the ones that you write yourself to extend Data::Maker's capabilities.

=head1 SYNOPSIS

  use Data::Maker;
  use Data::Maker::Field::Person::LastName;
  use MyField;

  my $maker = Data::Maker->new(
    record_count => 10_000,
    delimiter => "\t",
    fields => [
      { 
        name => 'lastname', 
        class => 'Data::Maker::Field::Person::LastName'
      },
      { 
        name => 'ssn', 
        class => 'Data::Maker::Field::Format',
        args => {
          format => '\d\d\d-\d\d-\d\d\d\d'
        }
      },
      { 
        name => 'myfield', 
        class => 'MyField'
      },
    ]
  );
  

=head1 DESCRIPTION

To write your own Data::Maker field class, create a L<Moose> class that consumes the Data::Maker::Field role.  

  package MyField;
  use Moose;
  with 'Data::Maker::Field';
 
  has some_attribute => ( is => 'rw' ); 

  sub generate_value {
    my ($this, $maker) = @_;
    # amazing code here...
    return $amazing_value;
  }

  1;


You must provide a C<generate_value> method, which is the method that will be called to generate the value of this field for each record.

Any Moose attribute that you define (C<some_flag> in the above example) can then be passed in as an argument in your field definition and will be available as an object method inside your C<generate_value> method (or any other class method, for that matter):

  # define the field in your Data::Maker constructor:

  my $maker = Data::Maker->new(
    record_count => 10,
    fields => [ 
      {
        name => 'myfield',
        class => 'MyField',
        args => { 
          some_attribute => 'blah' 
        }
      }
    ]
  );

  # And then later, in generate_value()...

  sub generate_value {
    my ($this, $maker) = @_;
    # $this->some_attribute now return "blah"
    # amazing code here...
    return $amazing_value;
  }

=head1 ATTRIBUTES

The following public L<Moose> attributes are supported (the data type of each attribute is also listed)

=over 4

=item B<name>

The name of the field.  This is used to refer to this field from other fields, and can also be used as a method
to the Data::Maker::Record object to retrieve the value for this field.

=back

=over 4

=item B<class>

The name of the class to be used for this field

=back

=over 4

=item B<args> (I<HashRef>)

The hash reference of arguments to be passed to this field

=back

=over 4

=item B<formatted> (I<CodeRef>)

A code reference that will be executed on the value after it is generated, but before it is returned

=back


