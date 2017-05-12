package Class::DBI::Factory::List;

use strict;
use Carp qw();
use vars qw( $AUTOLOAD $VERSION );

$VERSION = "0.93";

=head1 NAME

Class::DBI::Factory::List - an iterator-based retriever and paginator of Class::DBI data

=head1 SYNOPSIS
    
	$list = Class::DBI::Factory::List->from( $iterator );

    or
    
	$list = Class::DBI::Factory::List->new({
		 class => My::CD,
		 genre => $genre,
		 year => 1975,
		 startat => 0,
		 step => 20,
		 sortby => 'title',
		 sortorder => 'asc',
	 });
	 
	 my @objects = $list->page;
	 my $total = $list->total;

=head1 INTRODUCTION

Class::DBI::Factory::List (henceforth CDFL) is meant to do most the work of constructing, retrieving and displaying a list of Class::DBI objects. It is designed to be used in a template-driven application, and gives easy, readable shorthands for the different bits of information a template might want to display in the course of paginating and navigating a list.

CDFL is capable of constructing simple queries, but uses normal cdbi mechanisms as much as possible: the query is built with a call to search(), and iterators are used for all retrieval operations, for example. This means that we inherit the limitations of search(), and cannot build very complex queries within the module.

You can get around this limitation by using Class::DBI's other retrieveal methods or creating your own custom ones. So long as they return an iterator, you should be able to call:

CDFL->from( My::Class->complex_retrieval_method() );

CDFL is written as part of Class::DBI::Factory. There is no reason it could not be used in another context - the factory just makes it easier to get at - but this does mean that it has been designed first to play a role in a factory setting: it would probably have a cleaner interface if it had been built as an straight response to the problem of making lists, for example. Its development so far has been a gradual generalisation of what were initially very specific abilities.

At the moment the pagination routines are internal, but we intent to follow the example of Class::DBI::Pager and use Data::Page for that. Too many errors by one to avoid otherwise (though we're fencepost-clean at the moment and will hopefully stay that way).

=head1 BUILDING A LIST

There are two ways to construct a list object. You can build one from scratch by passing in a set of parameters and constraints, or you can turn an existing iterator into a list directly.

=head2 terminology: parameters and constraints

'Parameter' is used here, and in the code, to refer to a criterion that is used in selecting the members of the list: in other words, something that is going to end up in the WHERE clause of the search query around which this list is a wrapper. 'Constraint' is used to refer to a criterion that will govern the presentation of the list: the number of items to display per page, the order in which the list is sorted, and so on.

There are only four constraints, at the moment: anything else is assumed to be a query parameter. They are startat, step, sortby and sortorder, and the names are hopefully self-explanatory.

There is some muddling there, because the sorting constraints are also used to build the query - using the current, rather half-hearted cdbi mechanism to append an ORDER BY clause - but the pagination constraints are not used until the iterator is sliced. This is a consequence of using iterators, and will no doubt go through many more changes, so we're not letting it bother us too much.

The third kind of criterion is the content class, which is usually, sloppily, regarded as another parameter. As in all Class::DBI operations, it provides the database connection and table name. 

In the absence of any parameters apart from the content class, the module functions as a simple pager for that class. If that's your only use of it, then Class::DBI::Pager is almost certainly a more efficient way to go.

=head2 new()

To build a list from scratch, you just need to supply a hashref of criteria that contains at least a 'class' parameter, which should be a Full::Class::Name. In this call:

	my $list = Class::DBI::Factory::List->new({
		 moniker => 'cd',
		 genre => $genre,
		 year => 1975,
		 startat => 0,
		 step => 20,
		 sortby => 'title',
	 });

A quick call to the factory gives us a fully qualified class name for the moniker. The startat, step and sortby criteria are pulled out and stored as display constraints. The remaining criteria are held as the parameters which will be used passed to the $content_class->search() method when the time comes to display the list.

So if your application is using Class::DBI::Factory and the Template Toolkit, creating a list on page can be as simple as:

	[% list = factory.list(
		'cd',
		'artist' => artist,
		'sortby' => 'title',
	) %]

=head2 from()

Building a list from an iterator is simpler but less flexible: all you have to do is pass in the iterator and CDFL will do the rest. No search parameters are needed, but you can still supply pagination constraints. There is also the option to supply a calling object, since one of the main uses of from() is to paginate a list of relations. Nothing is done to the supplied parent object: it is just held ready in case it is needed to build the list title (or a template asks for it).

my $iterator = $artist->cds;
my $list = Class::DBI::Factory::List->from( $iterator, $artist, { step => 20 });

=cut

sub new {
	my ( $class, $input ) = @_;
	my $moniker = delete $input->{moniker};
    throw Exception::NOT_FOUND(-text => "No such content class ('$moniker').") unless $class->factory->has_class( $moniker );
    
    my $content_class = $class->factory->class_name($moniker);
    my $prefix = delete $input->{prefix};
	my %parameters =  map { $_ => ($input->{$_} || $class->default($_)) } grep { $content_class->find_column($_) } keys %$input;
	my %constraints = map { $_ => ($input->{$_} || $class->default($_)) } keys %{ $class->default };
	$constraints{step} = $class->config('max_list_step') if $constraints{step} > $class->config('max_list_step');
	my $self = bless {
		_parameters => \%parameters,
		_constraints => \%constraints,
		_class => $content_class,
	    _prefix => $prefix,
	    _sortable => 1,
	}, $class;
    $self->debug(3, "new list. content_class is $content_class and prefix is '$prefix");
    return $self;
}

sub from {
	my ($class, $iterator, $source, $param) = @_;
	throw Exception::SERVER_ERROR(-text => "CDF::List can't make a list from an iterator without an iterator") unless $iterator;
	my $content_class = $iterator->class;
    my $prefix = delete $param->{prefix};
	my %parameters =  ( $source->moniker => $source->id ) if $source;
	my %constraints = map { $_ => $param->{$_} || $class->default($_) } keys %{ $class->default };
	my $self = bless {
		iterator => $iterator,
		_parameters => \%parameters,
		_constraints => \%constraints,
		_class => $content_class,
	    _prefix => $prefix,
	    _sortable => 0,
	}, $class;
    $self->debug(2, "*** list from iterator. content class is $content_class.");
    return $self;
}

=head1 DISPLAYING A LIST

Execution of the list query is deferred until you call one of the content-display methods (unless you supplied the iterator up front, of course). They are:

=head2 page()

returns a simple array of inflated Class::DBI objects obtained by applying your pagination constraints to the iterator built from your query. You get a page full of list, in other words, which is created by calling iterator->slice(). Very simple.

=head2 total()

returns the number of records overall. The same as calling iterator->count.

=head2 title()

By default this is a rudimentary method that just returns the table name of the content class. It is intended to be subclassed to return a title in the form that suits your application. My data classes usually have a class_plural() method, and I tend to scan the parameters to append qualifications like 'by person x' or 'in project y'.

=head2 iterator()

you can also get at the iterator directly, if your requirements are more complicated than just an orderly segment of list.

=cut 

sub content_class { 
    my $self = shift;
    $self->{_class} = $_[0] if @_;
    throw Exception::SERVER_ERROR(-text => 'List has no content class.') unless $self->{_class};
    return $self->{_class};
}

sub iterator {
	my $self = shift;
	$self->debug(3, "CDF::List->iterator.");
	return $self->{iterator} if $self->{iterator};

	my $ob = $self->order_by;
    my $obclause = { order_by => $ob } if $ob;    
	my $whereclause = $self->where;
    my $iterator = $whereclause ? 
                   $self->content_class->search( %$whereclause, $obclause ) : 
                   $self->content_class->retrieve_all( $obclause );

    return $self->{iterator} = $iterator;
}

sub object_type {
	return shift->content_class->moniker;
}

sub contents { shift->page(@_); }

sub page {
	my $self = shift;
	$self->debug(3, "CDF::List->contents.");
	return $self->{contents} if $self->{contents};
	my $counter = 1;
	return @{ $self->{contents} } = map { $self->tweak_entry($_, $counter++) } $self->iterator->slice( $self->start, $self->end-1 );
}

sub total {
	my $self = shift;
	return $self->{total} if $self->{total};
	$self->debug(3, "CDF::List->total.");
	my $it = $self->iterator;
	return $self->{total} = $it->count;
}

sub title {
	my $self = shift;
	$self->debug(3, "CDF::List->title.");
	return $self->{_title} = $_[0] if $_[0];
	return $self->{_title} if $self->{_title};
	return $self->{_title} = $self->content_class->table;
}

=head1 POST-PROCESSING

Each item retrieved by contents() can be tweaked before it is returned. To accomplish this you just have to define a tweak_entry method in subclass. This is most useful for simple tasks like numbering the list entries.

=head2 tweak_entry()

receives each object in the contents() list before it is returned to the caller, along with the position of that object on the present page. It should return the object with which it has been supplied, unless you have decided that you want to exclude that one from the list (but note that the displayed totals won't be affected, so exclusion by this means might look odd).

For example, if you wanted to number each entry in your list according to its overall position, you could define a 'list_pos' TEMP column for every class and:

  sub tweak_entry {
	my ($self, $thing, $position) = @_;
	$position ||= 1;
	$position += $self->start;
	$thing->list_pos($position);
	return $thing;
  }

=cut

sub tweak_entry { 
	return $_[1];
}

=head1 QUERY COMPONENTS

The main query-assembly routines are separated out here in order to facilitate subclassing. You can tweak the query construction here without changing the overall way things are done.

=head2 where()

returns a hashref of {column => value} which can be passed on to content_class->search().

=head2 order_by()

returns the sort_by field, with ' DESC' appended to it if necessary.

=head2 start()

returns the start_at value

=head2 end()

calculates and returns the end of the page based on start_at and step.

=cut

sub where {
	my $self = shift;
	return unless keys %{ $self->{_parameters} };
	return $self->{_parameters};
};

sub order_by {
	my $self = shift;
	my ($package, $filename, $line) = caller;
	my $ob = $self->constraints('sortby');
	$self->debug(3, "list order_by is $ob");
	return unless $ob;
	$ob .= $self->_order_desc;
	$self->debug(3, "and now it's $ob");
	return $ob;
}

sub _order_desc {
	my $self = shift;
    return ' DESC' if $self->constraints('sortorder') =~ /desc/i;
}

sub start { 
	my $self = shift;
	return $self->constraints('startat');
};

sub end { 
	my $self = shift;
	my $reach = $self->constraints('startat') + $self->constraints('step');
	my $end = ($self->total_records < $reach) ? $self->total_records : $reach;
	return $end;
};

=head1 PAGINATION

The remaining methods are all to do with the tediously fiddly business of displaying pagination information and linking pages.

=head2 qs()

returns the query string that would be used to build the present page. Any supplied parameters are used to extend or override the present set, so:

  $list->qs( step => 50 );

Will give you the query string needed to display this list with 50 items per page instead of whatever the current value is.

=head2 next_qs()

returns the query string that would be used to build the next page 

=head2 previous_qs()

returns the query string that would be used to build the previous page 

=cut

sub qs {
	my ($self, %override) = @_;
	my %parameters = $self->_as_hash( %override );
	return join '&',  map { "$_=$parameters{$_}" } keys %parameters;
}

sub next_qs {
	my $self = shift;
	my %parameters = $self->_as_hash(startat => $self->next_start);
	return join '&', map { "$_=$parameters{$_}" } keys %parameters;
}

sub previous_qs {
	my $self = shift;
	my %parameters = $self->_as_hash(startat => $self->previous_start);
	return join '&', map { "$_=$parameters{$_}" } keys %parameters;
}

=head2 make_qs()

Accepts a hash and returns it as a query string. Override this method if you would like to use a notation other than foo=bar;this=that.

=cut

sub make_qs {
	my ($self, %contents) = @_;
	return join ';', map { "$_=$contents{$_}" } keys %contents;
}

=head2 prefix()

If a prefix parameter is supplied during construction, then all the pagination links returned will take the form "${prefix}parameter". This is to allow the separate pagination of more than one list on a page. If for some reason you want to set the prefix after list construction, just supply a value to this method.

=cut

sub prefix {
	my $self = shift;
	return $self->{_prefix} = $_[0] if @_;
    return $self->{_prefix};
}

=head2 as_form()

returns a set of hidden html inputs that could be used to create a form that would generate the present page. Any fields that you would like to omit from the form can be supplied as a list if, for example, you would like to allow users to enter a value for the year, but keep everything else the same:

  $list->as_form('year');

=cut

sub as_form {
	my ($self, @omit_parameters) = @_;
	my %parameters = $self->_as_hash;
	delete $parameters{$_} for @omit_parameters;
	my %values = map { $_ => ref $parameters{$_} ? $parameters{$_}->id : $parameters{$_} } keys %parameters;
	return join "\n", 
		   map { qq|<input type="hidden" name="$_" value="$values{$_}">| }
		   keys %parameters;
}

=head2 _as_hash()

This is the basis of all the as_* and *_qs methods: it returns a hash of parameter=>value, suitable for recreating this list object with whatever changes are required. It prepends the prefix marker to each key, and accepts a hash of override values.

=cut

sub _as_hash {
	my ($self, %override) = @_;
	my $prefix = $self->prefix;
	my %parameters;
	$parameters{"$prefix$_"} = $override{$_} || $self->parameters($_) for keys %{ $self->parameters };
	$parameters{"$prefix$_"} = $override{$_} || $self->constraints($_) for keys %{ $self->constraints };
	return %parameters;
}

=head2 show_pagination()

returns true if the total number of records exceeds the number to be displayed on each page.

=cut

sub show_pagination {
	my $self = shift;
	return 1 unless $self->total_records < $self->constraints('step') && $self->constraints('startat') < 1;
	return 0;
}

=head2 sortable()

Returns true if this list can be resorted simply. The answer is yes if the underlying iterator was built here - we can build it again with a different sort clause - but we assume that it is no if the iterator was passed in to us already constructed. 

=cut

sub sortable {
	my $self = shift;
	return $self->{_sortable};
}

=head2 previous_step()

returns the number of items that would be displayed on the previous page in the sequence. 

=cut

sub previous_step {
	my $self = shift;
	return ($self->constraints('startat') > $self->constraints('step')) ? $self->constraints('step') : $self->constraints('startat');
}

=head2 previous_step()

returns the overall position at which the previous page in the sequence would start.

=cut

sub previous_start {
	my $self = shift;
	return ($self->constraints('startat') < $self->constraints('step')) ? 0 : $self->constraints('startat') - $self->constraints('step');
}

=head2 next_step()

returns the number of items that would be displayed on the next page in the sequence.

=cut

sub next_step {
	my $self = shift;
	return ($self->total_records > ($self->constraints('startat') + ($self->constraints('step') * 2))) ? $self->constraints('step') : ($self->total_records - ($self->constraints('startat') + $self->constraints('step')));
}

=head2 next_step()

returns the overall position at which the next page in the sequence would start.

=cut

sub next_start {
	my $self = shift;
	return ($self->total_records > ($self->constraints('startat') + $self->constraints('step'))) ? $self->constraints('startat') + $self->constraints('step') : $self->total_records;
}

=head1 ADMINISTRIVIA

Which just leaves a few routines that provide debugging information or simplify access to some internal bit of data or other:

=head2 has_parameter()

returns true if a parameter value exists for the supplied key, even if the value is zero or undef.

=head2 parameters()

returns the value of the requested parameter, if a key is supplied, or the hash of all parameters if not.

=cut

sub has_parameter {
	return 1 if exists shift->{_parameters}->{$_[0]};
	return 0;
}

sub parameters {
	my $self = shift;
	return $self->{_parameters}->{$_[0]} if $_[0];
	return $self->{_parameters};
}

=head2 has_constraint()

returns true if a constraint value exists for the supplied key, even if the value is zero or undef.

=head2 constraints()

returns the value of the requested constraint, if a key is supplied, or the hash of all constraints if not.

=cut

sub has_constraint {
	return 1 if exists shift->{_constraints}->{$_[0]};
	return 0;
}

sub constraints {
	my $self = shift;
	return $self->{_constraints}->{$_[0]} if $_[0];
	return $self->{_constraints};
}

=head2 sortby() sortorder() startat() step()

An AUTOLOAD method provides get and set access to the display constraints, so you can call:

  $list->startat(50);

before you display its contents, or 

  $list->step();

to get the current number of items per page. Any constraints that you add to the set defined by default() will also be made available this way.

=cut

sub AUTOLOAD {
	my $self = shift;
	my $methodname = $AUTOLOAD;
	$methodname =~ s/.*://;
	$methodname eq 'DESTROY' && return;
	if (exists $self->{_constraints}->{$methodname}) {
		return $self->{_constraints}->{$methodname} = $_[0] if $_[0];
		return $self->{_constraints}->{$methodname};
	}
	return;
}

=head2 factory()

returns the local factory object, or creates one if none exists yet.

=head2 factory_class()

returns the full name of the class that should be used to instantiate the factory. Defaults to Class:DBI::Factory, of course: if you subclass the factory class, you must mention the name of the subclass here.

=head2 config()

A useful shortcut that returns the Config object attached to our factory. Added here just to keep syntax consistent.

=cut

sub factory_class { "Class::DBI::Factory" }
sub factory { return shift->factory_class->instance; }
sub config { return shift->factory->config; }

=head2 default()

returns the value of a requested default, if a constraint name is supplied, or the hash of default values if not. Defaults can be overridden freely, but things might go awry if you don't supply at least the basic four.

Note that the keys defined here dictate what is regarded as a constraint. Anything that does not appear here will be supplied to search() as a parameter.

=cut

sub default {
	my ( $self, $param ) = @_;
	my $defaults = {
		startat => 0,
		step => 20,
		sortby => 'id',
		sortorder => 'asc',
	};
	return if $param && not exists $defaults->{$param};
	return $defaults->{$param} if $param;
	return $defaults;
}


# old synonyms on the way out:

sub ends_at { return shift->end; }
sub starts_at { return shift->start; }
sub total_records { return shift->total; }

=head2 debug()

hands over to L<Class::DBI::Factory>'s centralised debugging message thing.

=cut

sub debug {
    shift->factory->debug(@_);
}

=head1 SEE ALSO

L<Class::DBI> L<Class::DBI::Factory> L<Class::DBI::Factory::Config> L<Class::DBI::Factory::Handler> L<Class::DBI::Pager>

=head1 AUTHOR

William Ross, wross@cpan.org

=head1 COPYRIGHT

Copyright 2001-4 William Ross, spanner ltd.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
