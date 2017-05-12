package Data::Maker;
use Data::Maker::Record;
use Moose;
use Data::Maker::Value;
use Data::Maker::Field::Format;

our $VERSION = '0.29';

has fields => ( is => 'rw', isa => 'ArrayRef', auto_deref => 1 );
has record_count => ( is => 'rw', isa => 'Num' );
before record_count => sub { my $self = shift;  if (@_) { $self->reset } };
has data_sources => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has record_counts => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has delimiter => ( is => 'rw', default => "\t" );
has generated => ( is => 'rw', isa => 'Num', default => 0);
has seed => ( is => 'rw', isa => 'Num');

sub BUILD {
  my $this = shift;
  if ($this->seed) {
    unless($Data::Maker::Seeded) {
      srand($this->seed);
      $Data::Maker::Seeded = 1;
    }
  }
}

sub reset {
  my $this = shift;
  $this->generated(0);
  delete $this->{_field_objects};
  return;
}

sub field_by_name {
  my ($this, $name) = @_;
  for my $field($this->fields) {
    if ($field->{name} eq $name) {
      return $field;
    }
  }
}

sub _field_objects {
  my $this = shift;
  return $this->{_field_objects} ||= do {
    my @field_objects;
    for my $field($this->fields) {
      if (my $class = $field->{class}) {
        $field->{args}->{name} = $field->{name};
        push @field_objects, $class->new( $field->{args} ? %{$field->{args}} : () );
      }
      elsif ($field->{format}) {
        push @field_objects, Data::Maker::Field::Format->new( format => $field->{format} );
      }
    }
    \@field_objects
  };
}

sub next_record {
  my $this = shift;
  return if $this->generated >= $this->record_count;
  my $record = {};
  $this->{_in_progress} = $record;
  for my $field (@{ $this->_field_objects }) {
    $record->{ $field->name } = Data::Maker::Value->new($field->generate($this)->value);
  }
  my $obj = Data::Maker::Record->new(data => $record, fields => [$this->fields], delimiter => $this->delimiter );
  $this->generated( $this->generated + 1 );
  return $obj;
}

# deleted previous_record() method.  It was only going to be useful if we were maintaining
# a list of all records generated, and that's just not scalable and isn't needed.

sub in_progress {
  my ($this, $name) = @_;
  if (my $prog = $this->{_in_progress}) {
    if (defined(my $field = $prog->{$name})) {
      return $field->value;
    }
  }
}

sub header {
  my $this = shift;
  return join($this->delimiter, map { $_->{label} || $_->{name} } $this->fields); 
}

sub random {
  my $class = shift;
  my $choices;
  if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
    $choices = shift;
  }
  else {
    $choices = \@_;
  }
  return $choices->[ rand scalar @$choices ];
}

sub add_field {
  my ($this, $field) = @_;
  push(@{$this->{fields}}, $field);
}

1;
__END__

=head1 NAME

Data::Maker - Simple, flexibile and extensible generation of realistic data

=head1 SYNOPSIS

An extremely basic example:

  use Data::Maker;

  my $maker = Data::Maker->new(
    record_count => 10_000,
    fields => [
      { name => 'phone', format => '(\d\d\d)\d\d\d-\d\d\d\d' } 
    ]
  );

  while (my $record = $maker->next_record) {
    print $record->phone->value . "\n";
  }

A more complete example:

  use Data::Maker;
  use Data::Maker::Field::Person::LastName;
  use Data::Maker::Field::Person::FirstName;

  my $maker = Data::Maker->new(
    record_count => 10_000,
    delimiter => "\t",
    fields => [
      { 
        name => 'lastname', 
        class => 'Data::Maker::Field::Person::LastName'
      },
      { 
        name => 'firstname', 
        class => 'Data::Maker::Field::Person::FirstName'
      },
      { 
        name => 'phone', 
        class => 'Data::Maker::Field::Format',
        args => {
          format => '(\d\d\d)\d\d\d-\d\d\d\d',
        }
      },
    ]
  );

  while (my $record = $maker->next_record) {
    print $record->delimited . "\n";
  }


=head1 DESCRIPTION

=head2 Overview

Whatever kind of test or demonstration data you need, L<Data::Maker> will help you make lots of it.

And if you happen to need one of the various types of data that is available as predefined field types,
it will be even easier.

=head2 Performance

Data::Maker was not specifically designed for performance, though obviously performance is a consideration.

My latest benchmarking has generally been around 200 records per second, for a fairly typical assortment of fields, but obviously this varies with different types of fields and certainly with different quantities of fields.

I think it's a good idea to benchmark each field type.  I added most of them to a benchmarking script that creates a certain number of records (in this case 250) with one field at a time, and then that same number of records with all of the fields in it.   Obviously the time required to generate an entire record increases with each field that is added.

Here are those results (new benchmarks based on version 0.20):

  Data::Maker::Field::Format                          2891.54 records/s
  Data::Maker::Field::Person::FirstName               3709.70 records/s
  Data::Maker::Field::Person::LastName                3753.64 records/s
  Data::Maker::Field::Code                            3706.50 records/s
  Data::Maker::Field::Person::Gender                  3546.64 records/s
  Data::Maker::Field::DateTime                         422.07 records/s
  Data::Maker::Field::Lorem                           3474.74 records/s
  Data::Maker::Field::Person::SSN                     2947.59 records/s
  Data::Maker::Record (with all of the above fields)   375.29 records/s

These benchmarks were run on a 2.66 GHz Intel Core 2 Duo MacBook Pro with 4 GB of memory.  In the future I will benchmark additional hardware and put that information in another document.  

To run the same benchmarks yourself, run the C<t/benchmark.pl> script.

=head2 Related Modules

I recently heard about L<Data::Faker>, which seems to have had similar goals.  I had not heard of Data::Faker when I first published Data::Maker and, at the time of this writing, Data::Faker has not been updated in four and a half years.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<Data::Maker> object.  Any PARAMS passed to the constructor will be set as properties of the object.

=back

=head1 CLASS METHODS

=over 4

=item B<random> LIST
 
Just makes a quick random selection from a list of choices.   It's just like calling Perl's `rand()` without having to mention the list more than once, and just like using L<Data::Maker::Field::Set> with less syntax (and it works where using a Field subclass would not be appropriate).   A good use of this (and the reason it was written) is when you want a random number of records created.  You can set L<record_count|Data::Maker/record_count> to generate a random number of records between 3 and 19 with this code:

  $maker->record_count( Data::Maker->random(3..19) );

=back

=head1 OBJECT METHODS

=over 4

=item B<BUILD>

The BUILD method is a L<Moose> thing.  It is run immediately after the object is created.
Currently used in Data::Maker only to seed the randomness, if a seed was provided.

=item B<field_by_name> NAME

Given the name of a field, this method returns the Field object

=item B<next_record>

This method not only gets the next record, but it also triggers the generation of the data itself.

=item B<in_progress> B<NAME>

This method is used to get the already-generated value of a field in the list,
before the entire record has been created and blessed as a Record object.
This was created for, and is mostly useful for, fields that depend upon the values
of other fields.  For example, the Data::Maker::Field::Person::Gender class uses this,
so that the gender of the person will match the first name of the person.

=item B<header>

Prints out a delimited list of all of the labels, only if a delimiter was 
provided to the L<Data::Maker> object

=item B<add_field> HASHREF

Takes a hashref that describes a field attribute and adds it to the field list

=back

=head1 ATTRIBUTES

The following L<Moose> attributes are used (the data type of each attribute is also listed):

=over 4

=item B<fields> (I<ArrayRef[HashRef]>)

A list of hashrefs, each of which describes one field to be generated.   Each field needs to define the subclass of L<Data::Maker::Field> that is used to generate that field.  The order of the fields has I<some> relevance, particularly in the context of L<Data::Maker::Record>.  For example, the L<delimited|Data::Maker::Record/delimited> method returns the fields in the order in which they are listed here. 

B<Note:> It may make more sense in the future for each field to have a "sequence" attribute, so methods such as L<delimited|Data::Maker::Record/delimited> would return then in a different order than that in which they are generated.  The order in which fields are generated matters in the event that one field relies on data from another (for example, the L<Data::Maker::Field::Person::Gender> field class relies on a first name that must have already been generated).

=over 8 

=item * L<Data::Maker::Field::Code> - Use a code reference to generate the data.  This is useful for generating a value for a field that is based on the value of another field.

=item * L<Data::Maker::Field::DateTime> - Generates a random DateTime, using L<DateTime::Event::Random>.

=item * L<Data::Maker::Field::File> - Provide your own file of seed data.

=item * L<Data::Maker::Field::Format> - Specify a format for the data to follow.  The follow regexp-inspired atoms are supported:

  \d: Digit
  \w: Word character
  \W: Word character, with all letters uppercase
  \l: Letter
  \L: Uppercase letter
  \x: hex character (00, f2, 97, b4, etc)
  \X: Uppercase hex character (00, F2, 97, B4, etc)

=item * L<Data::Maker::Field::Person::FirstName> - A built-in field class for generating (mostly Anglo) first (given) names.

=item * L<Data::Maker::Field::Person::MiddleName> - A built-in field class for generating middle I<initials> (I realize it's called MiddleName).  It should eventually be able to generate middle I<names> or I<initials>.

=item * L<Data::Maker::Field::Person::LastName> - A built-in field class for generating (mostly Anglo) surnames.

=item * L<Data::Maker::Field::Person::Gender> - Given a field that represents a given name, this class uses L<Text::GenderFromName> to guess the gender (currently returning only "M" or "F").  If it is not able to guess the gender, it returns "U" (unknown). 

=item * L<Data::Maker::Field::Set> - A build-in field class for selecting a random member of a given set.

=item * L<Data::Maker::Field::Lorem> - A build-in field class for generating random Latin-looking text, using L<Text::Lorem>.

=back 

=item B<record_count> (I<Num>)

The number of records desired

=item B<data_sources> (I<HashRef>)

Used internally by Data::Maker.  It's a hashref to store open file handles.

=item B<record_counts> (I<HashRef>)

A hashref of record counts.  Not sure why this was used.  It's mentioned in
Data::Maker::Field::File 

=item B<delimiter>

The optional delimiter... could be anything.  Usually a comma, tab, pipe, etc

=item B<generated> (I<Num>)

Returns the number of records that have been generated so far.

=item B<seed> (I<Num>)

The optional random seed.  Provide a seed to ensure that the randomly-generated 
data comes out the same each time you run it.  This is actually super-cool 
when you need this kind of thing.

=back

=head1 CONTRIBUTORS

Thanks to my employer, Informatics Corporation of America, for its commitment to Perl and to giving back to the Perl community.
Thanks to Mark Frost for the idea about optionally seeding the randomness to ensure the same output each time a program is run, if that's what you need to do.
Thanks to Adam Corum for a very useful idea about how to do numeric ranges more efficiently than my boneheaded idea.

=head1 AUTHOR

John Ingram (john@funnycow.com)

=head1 LICENSE

Copyright 2010 by John Ingram. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
