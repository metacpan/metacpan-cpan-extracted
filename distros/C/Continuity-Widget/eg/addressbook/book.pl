#!/usr/bin/perl

use lib '../../lib';

# This stuff allows us to add the 'label' attribute
#
# For some things, like labels, we'll need new attributes. For others we'll be
# able to look at the existing attributes for useful information. For example,
# we can see what type the field is to decide how we render it.
#
# Really the type of the field should know how to render itself... or there
# should be something like Str::Render or something maybe
#
# Another good function might be ->wait_for_input_for_me which would grep for
# incoming vars matching /^$uuid/ before continuing


# Now the good stuff
# The idea here is that we are defining a datatype and some basic behavior.
# Ideally we would have as little display-oriented code here as possible. Maybe
# there should be a separate Person::View class or something. Even still, all
# the metadata in the instance var declarations is invaluable.

# Tons of work to be done!

# It should be able to handle child-objects too. So in this case instead of
# just one phone number we should be able to have a little '+' button that will
# add phone numbers on the fly for that person. Maybe it will be able to handle
# isa => 'ArrayRef[Phone]' for example.

package Book;

use metaclass 'Moose::Meta::Class' => (
  attribute_metaclass => 'Continuity::Meta::Attribute::FormField'
);

use Moose;
extends 'Continuity::Widget';

has 'addresses' => (is => 'rw', isa => 'ArrayRef[Person]');

package Person;

use metaclass 'Moose::Meta::Class' => (
  attribute_metaclass => 'Continuity::Meta::Attribute::FormField'
);

use Moose;
extends 'Continuity::Widget';
with 'BonusTypes';

has name => (
  is => 'rw',
  label => 'Name',
);

has birthday => (
  is => 'rw',
  isa => 'DateTime',
  coerce => 1,
  default => sub { "yesterday" },
  label => 'Birthday'
);

has phone => (
  is => 'rw',
  label => 'Phone'
);

before main => sub {
  my ($self) = @_;
  $self->add_button('SayHello' => sub {
    print STDERR "Hello @{[$self->name]}!\n";
    $self->next("<h3>HELLO @{[$self->name]}!</h3>");
  });
  $self->add_button('Edit' => sub {
    my $out = $self->renderer->{edit}->($self);
    my $f = $self->next($out);
    $self->set_from_hash($f);
  });
};

# This is a generic wrapper to set up the context of our page and to manage our
# list of people in the addressbook

package main;

use Continuity;

Continuity->new( port => 8080 )->loop;

sub main {
  my $request = shift;

  my @people = ();

  my $joe = Person->new( name => 'Joe' );
  push @people, $joe;

  my $f = {};
  while(1) {

    my $form = join "<br><hr>", map {$_->process($f)} @people;
    $request->print(qq|
      <html>
        <head>
          <link rel="stylesheet" href="form.css" type="text/css">
        </head>
        <body>
          <h2>Address Book</h2>
          <form method=post>
            $form
            <input type=submit>
            <input type=submit name=action value="Add Person">
          </form>
        </body>
      </html>
    |);
    $request->next;
    $f = { $request->params };

    if($f->{action} && $f->{action} eq 'Add Person') {
      my $person = Person->new;
      push @people, $person;
    }
  }
}

