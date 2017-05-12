# $Id: Senna.pm 2 2005-06-20 03:01:23Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::Plugin::Senna;
use strict;
use base qw(Class::Data::Inheritable);
use Senna;
our $VERSION = '0.01';

sub import
{
    my $class = shift;
    my %args  = @_;

    my($pkg) = caller();

    $pkg->isa('Class::DBI') or Carp::croak("Calling class is not a Class::DBI");

    $pkg->mk_classdata('index_filename');
    $pkg->mk_classdata('index_column');
    $pkg->mk_classdata('index_createargs');
    $pkg->mk_classdata('senna_index');

    if (! $args{index_filename}) {
        Carp::croak("Required parameter index_filename not specified");
    }

    if (! $args{index_column}) {
        Carp::croak("Required parameter index_column not specified");
    }

    $pkg->index_filename($args{index_filename});
    $pkg->index_column($args{index_column});
    $pkg->index_createargs($args{index_createargs});

    my @args  = $pkg->index_createargs ? @{ $pkg->index_createargs } : ();
    my $index = Senna::Index->open($pkg->index_filename) ||
        Senna::Index->create($pkg->index_filename, @args);
    $index or Carp::croak("Failed to create index file " . $pkg->index_filename);
    $pkg->senna_index($index);
    {
        no strict 'refs';
        *{"${pkg}::fulltext_search"} = \&senna_search;
    }

    $pkg->add_trigger(after_create => \&_after_create_trigger);
    $pkg->add_trigger(after_update => \&_after_update_trigger);
    $pkg->add_trigger(before_delete => \&_before_delete_trigger);
    $pkg->add_trigger(after_delete => \&_after_delete_trigger);
    $pkg->add_trigger("before_set_$args{index_column}", \&_before_set_trigger);
}

sub senna_search
{
    my $class  = shift;
    my $query  = shift;
    my $index  = $class->senna_index();
    my $cursor = $index->search($query);

    my $iter   = Class::DBI::Plugin::Senna::Iterator->new($class, $cursor);
    if (wantarray) {
        my @ret;
        while (my $e = $iter->next) {
            push @ret, $e;
        }
        return @ret;
    } else {
        return $iter;
    }
}

sub _after_create_trigger
{
    my $self = shift;
    my $index = $self->senna_index;
    my $column = $self->index_column;
    $index->put($self->id, $self->$column);
}

sub _before_set_trigger
{
    my $self = shift;
    return unless ref($self);
    $self->{__preval}->{$self->index_column} = $self->get($self->index_column);
}

sub _after_update_trigger
{
    my $self = shift;
    my %args = @_;

    my $column = $self->index_column;
    # Don't do anything if discard_records does not contain what
    # we're looking for.
    return if !grep { $_ eq $column } @{$args{discard_columns}};
    # if it does, then get the previous value and update the index
    my $index = $self->senna_index;
    my $prev  = delete $self->{__preval}->{$self->index_column};
    $index->replace($self->id, $prev, $self->$column()) or die "Failed to replace";
}

sub _before_delete_trigger
{
    my $self = shift;
    $self->{__preval}->{$self->index_column} = $self->get($self->index_column);
}

sub _after_delete_trigger
{
    my $self = shift;
    my $index = $self->senna_index;
    my $prev  = delete $self->{__preval}->{$self->index_column};
    $index->del($self->id, $prev);
}

package Class::DBI::Plugin::Senna::Iterator;
use strict;
use overload
    '0+' => 'count',
    fallback => 1
;

sub new
{
    my($class, $them, $cursor) = @_;
    bless {
        _class  => $them,
        _cursor => $cursor,
    }, $class;
}

sub count
{
    my $self = shift;
    my $cursor = $self->{_cursor};
    return $cursor->hits;
}

sub reset
{
    my $self   = shift;
    my $cursor = $self->{_cursor};
    $cursor->rewind;
}

sub first
{
    my $self = shift;
    $self->reset;
    return $self->next;
}

sub next
{
    my $self   = shift;
    my $class  = $self->{_class};
    my $cursor = $self->{_cursor};

    my $result = $cursor->next();
    my $obj;
    if (defined $result) {
        $obj = $class->retrieve($result->key);
    }
    return $obj;
}

sub delete_all
{
    my $self = shift;
    $self->count or return;

    $self->first->delete;
    while (my $obj = $self->next) {
        $obj->delete;
    }
    1;
}
    

__END__

=head1 NAME

Class::DBI::Plugin::Senna - Add Instant Fulltext Search Capability With Senna

=head1 SYNOPSIS

  package MyDATA;
  use base qw(Class::DBI);
  use Class::DBI::Plugin::Senna (
      index_filename => 'foo',
      index_column   => 'column_name'
  );

  # in main portion of your code..
  my $iter = MyDATA->fulltext_search($query);

=head1 DESCRIPTION

Class::DBI::Plugin::Senna harnesses the power of Senna 
(http://b.razil.jp/project/senna) with Class::DBI. This module installs hooks 
in your Class::DBI package that automatically creates and updates a Senna index.

You can then call fulltext_search() to retrieve the rows that match the
particular fulltext search.

However, because Class::DBI is just a Perl wrapper (albeit a good one) around
a database, you will only be able to create simple indices -- that is, 
you can only create an index against a single column, and not against
multiple columns. This may sound limiting, but for anything more than that
you really ought to be embedding Senna into the database itself, as that will
allow for more complex searching.

=head1 HOW TO SETUP

First set up your Class::DBI object like you do normally. Then, add a few
lines like this:

  use Class::DBI::Plugin::Senna
    index_filename => 'path/to/index',
    index_column   => 'name_of_column'
  ;

C<index_filename> is the name of the index file that Senna will create.
C<index_column> is the name of the column that you want to build your
index on. Class::DBI::Plugin::Senna will *ONLY* create an index on this
column alone -- it is possible to apply the same hook that this module
does on multiple columns, but the cross-column search just gets too hairy.
If you want more power, you really should be embedding Senna in your database
(like Senna does for mysql). 

Class::DBI::Plugin::Senna willbe responsible for creating/opening the index
file. If you want to specify non-default arguments to the create() method
for Senna::Index, you can add a C<index_createargs> parameter in the
above list:

  use Class::DBI::Plugin::Senna
    index_filename => 'path/to/index',
    index_column   => 'name_of_column',
    index_createargs => [ $key_size, $flags, $n_segments, $encoding ]
  ;

Once you do that, your Class::DBI object will now automatically update the
Senna index for the particular column you chose as  you invoke the regular
Class::DBI create/update/delete methods. These will all update the index
accordingly:

  $obj = YourDataClass->create({ ... });

  $obj->your_indexed_column($new_value);
  $obj->update;

  $obj->delete;

After you poopulate the index, you can perform a fulltext search
on the column you specified by calling:

  my $iter = YourDataClass->fulltext_search($query);

C<$iter> is a special iterator class for Class::DBI::Plugin::Senna. You can
also retrieve the whole list of object that matches your query:

  my @obj = YourDataClass->fulltext_search($query);

That's it! Enjoyin searching :)

=head1 METHODS

=head2 fulltext_search($query)

Performs a fulltext search on the column specified in your class. In list 
context, returns a list of objects that match your particular query, an 
instance of Class::DBI::Plugin::Senna::Iterator.

=head2 index_filename()

Class method to get the name of the index file. Do NOT modify this value!

=head2 index_column()

Class method to get the name of the column that is being indexed by Senna. 
Do NOT modify this value!

=head2 index_createargs()

Class method to get the list of arguments passed to Senna::Index::create().
Do NOT modify this value!

=head2 senna_index()

Class method to get the Senna index object that is handling the index.
You may performa operations on it, but do not set it to a new index or such.

=head1 CAVEATS

The senna index is maitained if and only if you perform your updates through
this interface! If you go and change the data behind the scenes (by using
a interactive shell, for example), then the actual data and the index will
be out of sync.

This module uses triggers to update the index: if you do any exotic data
processing in the trigger chain that modifies the data, things may get
a bit weird.

=head1 AUTHOR

(c) Copyright 2005 by Daisuke Maki E<lt>dmaki@cpan.orgE<gt>

Development fundex by Brazil Ltd. E<lt>http://dev.razl.jp/projects/sennaE<gt>

=head1 SEE ALSO

L<Senna|Senna>, L<Class::DBI|Class::DBI>

=cut
