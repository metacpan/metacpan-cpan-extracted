package DBIx::Class::Schema::Diff;
use strict;
use warnings;

# ABSTRACT: Simple Diffing of DBIC Schemas

our $VERSION = 1.11;

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);
use Module::Runtime;
use Try::Tiny;
use List::Util;
use Hash::Layout 2.00;
use Array::Diff;
use Data::Dumper;

use DBIx::Class::Schema::Diff::Schema;
use DBIx::Class::Schema::Diff::Filter;
use DBIx::Class::Schema::Diff::State;

sub state {
  shift if ($_[0] && (try{ $_[0]->isa(__PACKAGE__) } || $_[0] eq __PACKAGE__));
  DBIx::Class::Schema::Diff::State->new(@_)
}


has '_schema_diff', required => 1, is => 'ro', isa => InstanceOf[
  'DBIx::Class::Schema::Diff::Schema'
], coerce => \&_coerce_schema_diff;

has 'diff', is => 'ro', lazy => 1, default => sub {
  (shift)->_schema_diff->diff
}, isa => Maybe[HashRef];

has 'MatchLayout', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  Hash::Layout->new({
    default_key   => '*',
    default_value => 1,
    levels => [
      { 
        name => 'source', 
        delimiter => ':',
        registered_keys => [$self->_schema_diff->all_source_names]
      },{ 
        name => 'type', 
        delimiter => '/',
        registered_keys => [&_types_list]
      },{ 
        name => 'id', 
      }
    ]
  });

}, init_arg => undef, isa => InstanceOf['Hash::Layout'];


around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my %opt = (ref($args[0]) eq 'HASH') ? %{ $args[0] } : @args; # <-- arg as hash or hashref
  
  return $opt{_schema_diff} ? $self->$orig(%opt) : $self->$orig( _schema_diff => \%opt );
};


sub filter {
  my ($self,@args) = @_;
  my $params = $self->_coerce_filter_args(@args);
  
  my $Filter = DBIx::Class::Schema::Diff::Filter->new( $params ) ;
  my $diff   = $Filter->filter( $self->diff );
  
  # Make a second pass, using the actual matched paths to filter out
  # the intermediate paths that didn't actually match anything:
  #  (update: unless this is an empty match, in which case we will just
  #  return the whole diff as-is)
  if($Filter->mode eq 'limit' && ! $Filter->empty_match) {
    if(scalar(@{$Filter->matched_paths}) > 0) {
      $params->{match} = $Filter->match->clone->reset->load( map {
        $Filter->match->path_to_composite_key(@$_)
      } @{$Filter->matched_paths} );
      $Filter = DBIx::Class::Schema::Diff::Filter->new( $params ) ;
      $diff   = $Filter->filter( $diff );
    }
    else {
      # If nothing was matched, in limit mode, the diff is undef:
      $diff = undef;
    }
  }
  
  return $self->chain_new($diff)
}

sub chain_new {
  my ($self, $diff) = @_;
  return __PACKAGE__->new({
    _schema_diff => $self->_schema_diff,
    diff         => $diff
  });
}

sub filter_out {
  my ($self,@args) = @_;
  my $params = $self->_coerce_filter_args(@args);
  $params->{mode} = 'ignore';
  return $self->filter( $params );
}


sub _coerce_filter_args {
  my ($self,@args) = @_;
  
  # This is the cleanest solution for wildcards to match as expected, not requiring the
  # user to append a trailing '*' since they don't have to when doing an exact match
  @args = map {
    my ($one,$two) = ($_ && ! ref($_)) ? split (/\:/,$_,2) : ();
    (
      $one && $two && $one ne '*' && ($one =~ /\*/)
      && ($two eq 'columns' || $two eq 'relationships' || $two eq 'constraints')
    ) ? $_.'*' : $_
  } @args;
  
  my $params = (
    scalar(@args) > 1
    || ! ref($args[0])
    || ref($args[0]) ne 'HASH'
  ) ? { match => \@args } : $args[0];
  
  unless (exists $params->{match}) {
    my $n = { match => $params };
    my @othr = qw(events source_events);
    exists $n->{match}{$_} and $n->{$_} = delete $n->{match}{$_} for (@othr);
    $params = $n;
  }

  return { 
    %$params,
    match => $self->MatchLayout->coerce($params->{match})
  };
}



sub fingerprint {
  my $self = shift;
  my $sum = Digest::SHA1->new->add( $self->_string_for_signature )->hexdigest;
  join('-', 'diffsum', substr($sum,0,15) )
}


# So far this is the only thing I could find to produce a consistent string value across all
# Travis tested perls (5.10,5.12,5.14,5.16,5.18,5.20,5.22,5.24,5.26)
sub _string_for_signature {
  my $self = shift;
  
  local $Data::Dumper::Maxdepth = 0;
  Data::Dumper->new([ $self->diff ])
   ->Purity(0)
   ->Terse(1)
   ->Indent(0)
   ->Useqq(1)
   ->Sortkeys(1)
   ->Dump()
}


1;


__END__

=head1 NAME

DBIx::Class::Schema::Diff - Identify differences between two DBIx::Class schemas

=head1 SYNOPSIS

 use DBIx::Class::Schema::Diff;

 # Create new diff object using schema class names:
 my $D = DBIx::Class::Schema::Diff->new(
   old_schema => 'My::Schema1',
   new_schema => 'My::Schema2'
 );
 
 # Create new diff object using schema objects:
 $D = DBIx::Class::Schema::Diff->new(
   old_schema => $schema1,
   new_schema => $schema2
 );
 
 # Dump current schema data to a json file for later use:
 $D->old_schema->dump_json_file('/tmp/my_schema1_data.json');
 
 # Or
 DBIx::Class::Schema::Diff::SchemaData->new(
   schema => 'My::Schema1'
 )->dump_json_file('/tmp/my_schema1_data.json');
 
 # Create new diff object using previously saved 
 # schema data + current schema class:
 $D = DBIx::Class::Schema::Diff->new(
   old_schema => '/tmp/my_schema1_data.json',
   new_schema => 'My::Schema1'
 );
 
 # Git a checksum/fingerprint of the diff data:
 my $checksum = $D->fingerprint;
 

Filtering the diff:

 
 # Get all differences (hash structure):
 my $hash = $D->diff;
 
 # Only column differences:
 $hash = $D->filter('columns')->diff;
 
 # Only things named 'Artist' or 'CD':
 $hash = $D->filter(qw/Artist CD/)->diff;
 
 # Things named 'Artist', *columns* named 'CD' and *relationships* named 'columns':
 $hash = $D->filter(qw(Artist columns/CD relationships/columns))->diff;
 
 # Sources named 'Artist', excluding column changes:
 $hash = $D->filter('Artist:')->filter_out('columns')->diff;
 
 if( $D->filter('Artist:columns/name.size')->diff ) {
  # Do something only if there has been a change in 'size' (i.e. in column_info)
  # to the 'name' column in the 'Artist' source
  # ...
 }
 
 # Names of all sources which exist in new_schema but not in old_schema:
 my @sources = keys %{ 
   $D->filter({ source_events => 'added' })->diff || {}
 };
 
 # All changes to existing unique_constraints (ignoring added or deleted)
 # excluding those named or within sources named Album or Genre:
 $hash = $D->filter_out({ events => [qw(added deleted)] })
           ->filter_out('Album','Genre')
           ->filter('constraints')
           ->diff;
 
 # All changes to relationship attrs except for 'cascade_delete' in 
 # relationships named 'artists':
 $hash = $D->filter_out('relationships/artists.attrs.cascade_delete')
           ->filter('relationships/*.attrs')
           ->diff;


=head1 DESCRIPTION

General-purpose schema differ for L<DBIx::Class> to identify changes between two DBIC Schemas. 
Currently tracks added/deleted/changed events and deep diffing across 5 named types of source data:

=over

=item *

columns

=item *

relationships

=item *

constraints

=item *

table_name

=item *

isa

=back

The changes which are detected are stored in a HashRef which can be accessed by calling 
L<diff|DBIx::Class::Schema::Diff#diff>. This data packet, which has a format that is specific to 
this module, can either be inspected directly, or I<filtered> to be able to check for specific 
changes as boolean test(s), making it unnecessary to know the internal diff structure for many 
use-cases (since if there are no changes, or no changes left after being filtered, C<diff> returns 
false/undef - see the L<FILTERING|DBIx::Class::Schema::Diff#FILTERING> section for more info).

This tool attempts to be simple and flexible with a straightforward, "DWIM" API. It is meant
to be used programmatically in dynamic scenarios where schema changes are occurring but are not well
suited for L<DBIx::Class::Migration> or L<DBIx::Class::DeploymentHandler> for whatever reasons, or
some other event/action needs to take place based on certain types of changes (note that this tool 
is NOT meant to be a replacement for Migrations/DH). 

It is also useful as a general debugging/development tool, and was designed with this in mind to 
be "handy" and not need a lot of setup/RTFM to use.

This tool is different from L<SQL::Translator::Diff> in that it compares DBIC schemas at the 
I<class/code> level, not the underlying DDL, nor does it attempt to modify one schema to match
the other (although, it could certainly be used to write a tool that did).

=head1 METHODS

=head2 new

Create a new DBIx::Class::Schema::Diff instance. The following build options are supported:

=over 4

=item old_schema

The "old" (or left-side) schema to be compared. 

Can be supplied as a L<DBIx::Class::Schema> class name, connected schema object instance, 
or previously saved L<SchemaData|DBIx::Class::Schema::Diff::SchemaData> which can be 
supplied as an object, HashRef, or a path to a file containing serialized JSON data (as 
produced by L<DBIx::Class::Schema::Diff::SchemaData#dump_json_file>)

See the SYNOPSIS and L<DBIx::Class::Schema::Diff::SchemaData> for more info.

=item new_schema

The "new" (or right-side) schema to be compared. Accepts the same dynamic type options 
as C<old_schema>.

=back

=head2 diff

Returns the differences between the two schemas as a HashRef structure, or C<undef> if there are 
none.

The HashRef is divided first by source name, then by type, with the special C<_event> key 
identifying the kind of modification (added, deleted or changed) at both the source and the type 
level. For 'changed' events within types, a deeper, type-specific diff HashRef is provided (with 
column_info/relationship_info diffs generated using L<Hash::Diff>).

Here is an example of what a diff packet (with a sampling of lots of different kinds of changes) 
might look like:

 # Example diff with sample of all 3 kinds of events and all 5 types:
 {
   Address => {
     _event => "changed",
     isa => [
       "-Some::Removed::Component",
       "+Test::DummyClass"
     ],
     relationships => {
       customers2 => {
         _event => "added"
       },
       staffs => {
         _event => "changed",
         diff => {
           attrs => {
             cascade_delete => 1
           }
         }
       }
     }
   },
   City => {
     _event => "changed",
     table_name => "city1"
   },
   FilmCategory => {
     _event => "changed",
     columns => {
       last_update => {
         _event => "changed",
         diff => {
           is_nullable => 1
         }
       }
     }
   },
   FooBar => {
     _event => "added"
   },
   FooBaz => {
     _event => "deleted"
   },
   Store => {
     _event => "changed",
     constraints => {
       idx_unique_store_manager => {
         _event => "added"
       }
     }
   }
 }

=head2 filter

Accepts filter argument(s) to restrict the differences to consider and returns a new C<Schema::Diff> 
instance, making it chainable (much like L<ResultSets|DBIx::Class::ResultSet#search_rs>).

See L<FILTERING|DBIx::Class::Schema::Diff#FILTERING> for filter argument syntax.

=head2 filter_out

Works like C<filter()> but the arguments exclude differences rather than restrict/limit to them.

See L<FILTERING|DBIx::Class::Schema::Diff#FILTERING> for filter argument syntax.

=head2 fingerprint

Returns a SHA1 checksum (as a 15 character string) of the diff data.

=head1 FILTERING

The L<filter|DBIx::Class::Schema::Diff#filter> (and inverse 
L<filter_out|DBIx::Class::Schema::Diff#filter_out>) method is analogous to ResultSet's 
L<search_rs|DBIx::Class::ResultSet#search_rs> in that it is chainable (i.e. returns a new object 
instance) and each call further restricts the data considered. But, instead of building up an SQL 
query, it filters the data in the HashRef returned by L<diff|DBIx::Class::Schema::Diff#diff>. 

The filter argument(s) define an expression which matches specific parts of the C<diff> packet. In 
the case of C<filter()>, all data that B<does not> match the expression is removed from the diff 
HashRef (of the returned, new object), while in the case of C<filter_out()>, all data that B<does> 
match the expression is removed.

The filter expression is designed to be simple and declarative. It can be supplied as a list of 
strings which match schema data either broadly or narrowly. A filter string argument follows this 
general pattern:

 '<source>:<type>/<id>'

Where C<source> is the name of a specific source in the schema (either side), C<type> is the 
I<type> of data, which is currently one of five (5) supported, predefined types: I<'columns'>, 
I<'relationships'>, I<'constraints'>, I<'isa'> and I<'table_name'>, and C<id> is the name of an 
item, specific to that type, if applicable. 

For instance, this expression would match only the I<column> named 'timestamp' in the source 
named 'Artist':

 'Artist:columns/timestamp'

Not all types have sub-items (only I<columns>, I<relationships> and I<constraints>). The I<isa> and 
I<table_name> types are source-global. So, for example, to see changes to I<isa> (i.e. differences 
in inheritance and/or loaded components in the result class) you could use the following:

 'Artist:isa'

On the other hand, not only are there multiple I<columns> and I<relationships> within each source, 
but each can have specific changes to their attributes (column_info/relationship_info) which can 
also be targeted selectively. For instance, to match only changes in C<size> of a specific column:

 'Artist:columns/timestamp.size'

Attributes with sub hashes can be matched as well. For example, to match only changes in C<list> 
I<within> C<extra> (which is where DBIC puts the list of possible values for enum columns):

 'Artist:columns/my_enum.extra.list'

The structure is specific to the type. The dot-separated path applies to the data returned by L<column_info|DBIx::Class::ResultSource#column_info> for columns and
L<relationship_info|DBIx::Class::ResultSource#relationship_info> for relationships. For instance, 
the following matches changes to C<cascade_delete> of a specific relationship named 'some_rel' 
in the 'Artist' source:

 'Artist:relationships/some_rel.attrs.cascade_delete'

Filter arguments can also match I<broadly> using the wildcard asterisk character (C<*>). For 
instance, to match I<'isa'> changes in any source:

 '*:isa'

The system also accepts ambiguous/partial match strings and tries to "DWIM". So, the above can also 
be written simply as:

 'isa'

This is possible because 'isa' is understood/known as a I<type> keyword. Additionally, the system 
knows the names of all the sources in advance, so the following filter string argument would match 
everything in the 'Artist' source:

 'Artist'

Sub-item names are automatically resolved, too. The following would match any column, relationship, 
or constraint named C<'code'> in any source:

 'code'

When you have schemas with overlapping names, such as a column named 'isa', you simply need to 
supply more specific match strings, as ambiguous names are resolved with left-precedence. So, to 
match any column, relationship, or constraint named 'isa', you could use the following:

 # Matches column, relationship, or constraints named 'isa':
 '*:*/isa'

Different delimiter characters are used for the source level (C<':'>) and the type level (C<'/'>) 
so you can do things like match any column/relationship/constraint of a specific source, such as:

 Artist:code

The above is equivalent to:

 Artist:*/code

You can also supply a delimiter character to match a specific level explicitly. So, if you wanted to
match all changes to a I<source> named 'isa':

 # Matches a source (poorly) named 'isa'
 'isa:'

The same works at the type level. The following are all equivalent

 # Each of the following 3 filter strings are equivalent:
 'columns/'
 '*:columns/*'
 'columns'

Internally, L<Hash::Layout> is used to process the filter arguments.

=head2 event filtering

Besides matching specific parts of the schema, you can also filter by I<event>, which is either 
I<'added'>, I<'deleted'> or I<'changed'> at both the source and type level (i.e. the event of a 
new column is 'added' at the type level, but 'changed' at the source level).

Filtering by event requires passing a HashRef argument to filter/filter_out, with the special
C<'events'> key matching 'type' events, and C<'source_events'> matching 'source' events. Both accept
either a string (when specifying only one event) or an ArrayRef:

 # Limit type (i.e. columns, relationships, etc) events to 'added'
 $D = $D->filter({ events => 'added' });
 
 # Exclude added and deleted sources:
 $D = $D->filter_out({ source_events => ['added','deleted'] });
 
 # Also excludes added and deleted sources:
 $D = $D->filter({ source_events => ['changed'] });


=head1 EXAMPLES

For examples, see the L<SYNOPSIS|DBIx::Class::Schema::Diff#SYNOPSIS> and also the unit tests in C<t/>
which has lots of working examples.

=head1 BUGS/LIMITATIONS

I'm not aware of any bugs at this point (although I'm sure there are some), but there are 
several things to be aware of in general when using this tool that are worth mentioning:

=over

=item *

Firstly, the diff packet is I<informational> only; it does not contain the information needed to
"patch" anything, or see the previous and new values. It assumes you already/still have access to the
old and new schemas to look up this info yourself. Its main purpose is simply to I<flag> which 
items are changed.

=item *

Also, there is no deeper "diff" for 'added' and 'deleted' events because it is redundant. For an 
added source, for example, you already know that every column, relationship, etc., that it contains 
is also "added" (depending on your definition of "added"), so these are not included in the diff 
for the purpose of reducing clutter. But, one side effect of this that you have to keep in mind is 
that when filtering for all changes to 'columns', for example, this will not include columns in 
added sources. This is just a design decision made early on (and it can't be both ways). It just 
means if you want to check for the expanded definition of 'modified' columns, which include 
added/deleted via a source, you must also test for added/deleted sources.

In a later version, an additional layer of sugar methods could be added to provide convenient access
to some of these concepts.

=item *

As of version 1.1 filter string arguments I<are> glob patterns, so you can also do things like 
C<'Arti*'> to match sub-strings. See the unit tests for examples.

=item *

Also, the special C<*> character can only be used in place of the predefined first 3 levels 
(C<'*:*/*'>) and not within deeper column_info/relationship_info sub-hashes (so you can't match 
C<'Artist:columns/foo.*.list'>). We're really splitting hairs at this point, but it is still worth 
noting. (Internally, L<Hash::Layout> is used to process the filter arguments, so these limitations
have to do with the design of that package which provides more-useful flexibility in other areas)

=item *

In many practical cases, differences in loaded components will produce many more changes than just
'isa'. It depends on whether or not the components in question change the column/relationship infos. 
One common example is L<InflateColumn::DateTime|DBIx::Class::InflateColumn::DateTime> which sets 
inflator/deflators on all date columns. This is more of a feature than it is a limitation, but it 
is something to keep in mind. If one side loads a component(s) like this but the other doesn't, 
you'll have lots of differences to contend with that you might not actually care about. And, in 
order to filter out these differences, you have to filter out a lot more than 'isa', which is 
trivial. This is more about how DBIC works than anything else.

One thing that I did to overcome this when there were lots of different loaded components that I
couldn't do anything about was to deploy both sides to a temp SQLite file, then create new schemas
(in memory) from those files with L<Schema::Loader|DBIx::Class::Schema::Loader>, using the same 
options (and thus the same loaded components), and then run the diff on the two I<new> schemas. 
This type of approach may not work or be appropriate in all scenarios; it obviously depends on 
what exactly you are trying to accomplish.


=back

=head1 SEE ALSO

=over

=item *

L<DBIx::Class>

=item * 

L<SQL::Translator::Diff>

=item * 

L<DBIx::Class::Migration>

=item * 

L<DBIx::Class::DeploymentHandler>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
