package Collection::Categorized;
use strict;
use warnings;
use Carp;
use Sub::AliasedUnderscore qw/transform/;

our $VERSION = '0.01';

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/_sorter _data/);

=head1 NAME

Collection::Categorized - categorize and organize a collection of data

=head1 SYNOPSIS

  use Collection::Categorized;

  # create a collection where elements are categorized by
  # the class they are in
  my $cc = Collection::Categorized->new( sub { ref $_ } );

  # add some data
  $foo->{awesomeness} = 42;
  $cc->add($foo); # $foo isa Foo
  $cc->add($bar, $bar2); # $bars are Bars
  $cc->add(@bazs); # @bazs are Bazs

  # see what we have
  my @c = $cc->categories; # (Foo, Bar, Baz) 

  # get the data by category  
  my @foos = $cc->get('Foo'); # ($foo)
  my @bars = $cc->get('Bar'); # ($bar, $bar2)
  my @HOOO = $cc->get('HOOO'); # undef

  # grep the data
  $cc->edit(sub { grep { defined $_->{awesomeness} } @_ });
  @foos = $cc->get('Foo'); # ($foo)
  @bars = $cc->get('Bar'); # ()
  @HOOO = $cc->get('HOOO'); # undef

=head1 DESCRIPTION

The idea is that, given a list of junk, you want to find order in the
chaos.  Write some categorizers (see below), dump your data in, and
get it out in some sort of meaningful order.

=head1 METHODS

=head2 new($coderef)

Create a categorized collection that categorizes its members
by the return value of C<$coderef>.  Coderef is run with C<$_>
aliased to the element to categorize.

=head2 new([ category => $condition, ... ])

Create a categorized collection that categorizes its members
based on the passed category definition list.  Example:

  new([ positive => sub { $_ <  0 },
        zero     => sub { $_ == 0 },
        negative => sub { $_ >  0 },
      ]);

This example creates three categories.  The conditions are run in
order, and the first condition to match decides the category that
element is in.  If an element doesn't match any of the three blocks
(unlikely in this case), then it is silently discarded.  If you want
some sort of fallback, just add a condition that always matches (like
C<sub { 1 }>).

Note that you're passing an arrayref, not a hashref, because we want
to preserve order.

=cut

sub new {
    my ($class, $ref) = @_;
    my $self = {};
    my $dispatch = 
      { CODE  => sub { $self->{_sorter} = transform $ref },
        ARRAY => sub {
            my %lookup = @$ref;
            $lookup{$_} = transform $lookup{$_} for keys %lookup;

            # with that out of the way, setup the sorter
            $self->{_sorter} = sub {
                my $arg = shift;
                foreach my $category (grep { !ref $_ } @$ref) {
                    return $category if $lookup{$category}->($arg);
                }
            }
        },
      };
    
    my $action = $dispatch->{ref $ref};
    croak 'pass an ARRAY or CODE reference only' unless $action;
    $action->();
    
    $self->{_data} = {};
    return bless $self => $class;
}

=head2 categories

Returns a list of categories in use

=cut

sub categories {
    my $self = shift;
    return keys %{$self->{_data}};
}

=head2 add($object)

Add an object to the collection.

=cut


sub add {
    my ($self, @objects) = @_;
    foreach (@objects) {
        my $class = $self->_sorter->($_);
        $self->_data->{$class} ||= [];
        push @{$self->_data->{$class}}, $_;
    }
    return;
}

=head2 get($type)

Gets all elements of a certain type

=cut

sub get {
    my ($self, $type) = @_;
    return @{$self->_data->{$type}||[]};
}

=head2 all

Get every element in the collection

=cut

sub all {
    my $self = shift;
    return map { $self->get($_) } $self->categories;
}

=head2 edit(sub { change @_ })

Given a a subref, apply it to every type and change the members of the
type to be the return value of the sub.

Example:

   # Input: ( category => data )
   #   { foo => [ 1 2 3 ],
   #     bar => [ 3 2 1 ],
   #   }

  $collection->edit( sub { reverse @_ } );

   # Output:
   #   { foo => [ 3 2 1 ],
   #     bar => [ 1 2 3 ],
   #   }


=cut

sub edit {
    my ($self, $editor) = @_;
    foreach my $type ($self->categories) {
        my @members = $self->get($type);
        my @changed = $editor->(@members);
        $self->_data->{$type} = \@changed;
    }
    return;
}

=head1 AUTHOR

Jonathan Rockway C<< jrockway AT cpan.org >>
Jeremy Wall C<< zaphar AT cpan.org >>

We wrote this for work.  Now you can have it too.

=head1 COPYRIGHT

This module is probably copyright (c) 2007 by Doubleclick Performics.
Despite the weird name of the copyright holder, you can use, modify,
and redistribute this module under the same terms as Perl itself.

=cut

1;
