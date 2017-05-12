package Class::DBI::Plugin::Pager;
use strict;
use warnings;
use Carp;

use UNIVERSAL::require;
use SQL::Abstract;

use base qw( Data::Page Class::Data::Inheritable ); 

use vars qw( $VERSION );

$VERSION = '0.566';

# D::P inherits from Class::Accessor::Chained::Fast
__PACKAGE__->mk_accessors( qw( where abstract_attr per_page page order_by _cdbi_app ) );

__PACKAGE__->mk_classdata( '_syntax' );
__PACKAGE__->mk_classdata( '_pager_class' );


=head1 NAME

Class::DBI::Plugin::Pager - paged queries for CDBI

=head1 DESCRIPTION

Adds a pager method to your class that can query using SQL::Abstract where clauses,
and limit the number of rows returned to a specific subset.

=head1 SYNOPSIS

    package CD;
    use base 'Class::DBI';

    use Class::DBI::Plugin::AbstractCount;      # pager needs this
    use Class::DBI::Plugin::Pager;

    # or to use a different syntax
    # use Class::DBI::Plugin::Pager::RowsTo;

    __PACKAGE__->set_db(...);


    # in a nearby piece of code...

    use CD;

    # see SQL::Abstract for how to specify the query
    my $where = { ... };

    my $order_by => [ qw( foo bar ) ];

    # bit by bit:
    my $pager = CD->pager;

    $pager->per_page( 10 );
    $pager->page( 3 );
    $pager->where( $where );
    $pager->order_by( $order_by );

    $pager->set_syntax( 'RowsTo' );

    my @cds = $pager->search_where;

    # or all at once
    my $pager = CD->pager( $where, $order_by, 10, 3 );

    my @cds = $pager->search_where;

    # or

    my $pager = CD->pager;

    my @cds = $pager->search_where( $where, $order_by, 10, 3 );

    # $pager isa Data::Page
    # @cds contains the CDs just for the current page

=head1 METHODS

=over

=item import

Loads the C<pager> method into the CDBI app.

=cut

sub import {
    my ( $class ) = @_; # the pager class or subclass

    __PACKAGE__->_pager_class( $class );

    my $caller;

    # find the app - supports subclassing (My::Pager is_a CDBI::P::Pager, not_a CDBI)
    foreach my $level ( 0 .. 10 )
    {
        $caller = caller( $level );
        last if UNIVERSAL::isa( $caller, 'Class::DBI' )
    }

    warn( "can't find the CDBI app" ), return unless $caller; 
    #croak( "can't find the CDBI app" ) unless $caller;

    no strict 'refs';
    *{"$caller\::pager"} = \&pager;
}

=item pager( [$where, [$abstract_attr]], [$order_by], [$per_page], [$page], [$syntax] )

Also accepts named arguments:

    where           => $where,
    abstract_attr   => $attr,
    order_by        => $order_by,
    per_page        => $per_page,
    page            => $page,
    syntax          => $syntax

Returns a pager object. This subclasses L<Data::Page>.

Note that for positional arguments, C<$abstract_attr> can only be passed if
preceded by a C<$where> argument.

C<$abstract_attr> can contain the C<$order_by> setting (just as in
L<SQL::Abstract|SQL::Abstract>).

=over 4

=item configuration

The named arguments all exist as get/set methods.

=over 4

=item where

A hashref specifying the query. See L<SQL::Abstract|SQL::Abstract>.

=item abstract_attr

A hashref specifying extra options to be passed through to the
L<SQL::Abstract|SQL::Abstract> constructor.

=item order_by

Single column name or arrayref of column names for the ORDER BY clause.
Defaults to the primary key(s) if not set.

=item per_page

Number of results per page.

=item page

The pager will retrieve results just for this page. Defaults to 1.

=item syntax

Change the way the 'limit' clause is constructed. See C<set_syntax>. Default
is C<LimitOffset>.

=back

=back

=cut

sub pager {
    my $cdbi = shift;

    my $class = __PACKAGE__->_pager_class;

    my $self = bless {}, $class;

    $self->_cdbi_app( $cdbi );

    # This has to come before _init, so the caller can choose to set the syntax
    # instead. But don't auto-set if we're a subclass.
    $self->auto_set_syntax if $class eq __PACKAGE__;

    $self->_init( @_ );

    return $self;
}

# _init is also called by results, so preserve any existing settings if
# new settings are not provided
sub _init {
    my $self = shift;

    return unless @_;

    my ( $where, $abstract_attr, $order_by, $per_page, $page, $syntax );

    if ( ref( $_[0] ) or $_[0] =~ /^\d+$/ )
    {
        $where          = shift if ref $_[0]; # SQL::Abstract accepts a hashref or an arrayref 
        $abstract_attr  = shift if ref $_[0] eq 'HASH';
#        $order_by       = shift unless $_[0] =~ /^\d+$/;
#        $per_page       = shift if $_[0] =~ /^\d+$/;
#        $page           = shift if $_[0] =~ /^\d+$/;
        $order_by       = shift unless $_[0] and $_[0] =~ /^\d+$/;
        $per_page       = shift if $_[0] and $_[0] =~ /^\d+$/;
        $page           = shift if $_[0] and $_[0] =~ /^\d+$/;         
        $syntax         = shift;
    }
    else
    {
        my %args  = @_;

        $where          = $args{where};
        $abstract_attr  = $args{abstract_attr};
        $order_by       = $args{order_by};
        $per_page       = $args{per_page};
        $page           = $args{page};
        $syntax         = $args{syntax};
    }

    # Emulate AbstractSearch's search_where ordering -VV 20041209
    $order_by = delete $$abstract_attr{order_by} if ($abstract_attr and !$order_by);

    $self->per_page( $per_page )          if $per_page;
    $self->set_syntax( $syntax )          if $syntax;
    $self->abstract_attr( $abstract_attr )if $abstract_attr;
    $self->where( $where )                if $where;
    $self->order_by( $order_by )          if $order_by;
    $self->page( $page )                  if $page;
}

=item search_where

Retrieves results from the pager. Accepts the same arguments as the C<pager>
method.

=cut

# like CDBI::AbstractSearch::search_where, with extra limitations
sub search_where {
    my $self = shift;

    $self->_init( @_ );

    $self->_setup_pager;

    my $cdbi = $self->_cdbi_app;

    my $order_by      = $self->order_by || [ $cdbi->primary_columns ];
    my $where         = $self->where;
    my $syntax        = $self->_syntax || $self->set_syntax;
    my $limit_phrase  = $self->$syntax;
    my $sql           = SQL::Abstract->new( %{ $self->abstract_attr  || {} } );

    $order_by = [ $order_by ] unless ref $order_by;
    my ( $phrase, @bind ) = $sql->where( $where, $order_by );
    
    # If the phrase starts with the ORDER clause (i.e. no WHERE spec), then we are 
    # emulating a { 1 => 1 } search, but avoiding the bug in Class::DBI::Plugin::AbstractCount 0.04,
    # so we need to replace the spec - patch from Will Hawes
    if ( $phrase =~ /^\s*ORDER\s*/i ) 
    {
        $phrase = ' 1=1' . $phrase;
    }
    

    $phrase .= ' ' . $limit_phrase;
    $phrase =~ s/^\s*WHERE\s*//i;

    return $cdbi->retrieve_from_sql( $phrase, @bind );
}

=item retrieve_all

Convenience method, generates a WHERE clause that matches all rows from the table. 

Accepts the same arguments as the C<pager> or C<search_where> methods, except that no 
WHERE clause should be specified.

Note that the argument parsing routine called by the C<pager> method cannot cope with 
positional arguments that lack a WHERE clause, so either use named arguments, or the 
'bit by bit' approach, or pass the arguments directly to C<retrieve_all>.

=cut

sub retrieve_all 
{
    my $self = shift;

    my $get_all = {}; # { 1 => 1 };

    unless ( @_ ) 
    {   # already set pager up via method calls
            $self->where( $get_all );
            return $self->search_where;
    }
    
    my @args = ( ref( $_[0] ) or $_[0] =~ /^\d+$/ ) ?
                ( $get_all, @_ ) :          # send an array
                ( where => $get_all, @_ );  # send a hash

    return $self->search_where( @args );
}

sub _setup_pager 
{
    my ( $self ) = @_;

    my $where = $self->where || {}; 
    
    # fix { 1 => 1 } as a special case - Class::DBI::Plugin::AbstractCount 0.04 has a bug in 
    # its column-checking code
    if ( ref( $where ) eq 'HASH' and $where->{1} )
    {
        $where = {};
        $self->where( {} );
    }    
    
    my $per_page = $self->per_page || croak( 'no. of entries per page not specified' );
    my $cdbi     = $self->_cdbi_app;
    my $count    = $cdbi->count_search_where( $where, $self->abstract_attr );
    my $page     = $self->page || 1;

    $self->total_entries( $count );
    $self->entries_per_page( $per_page );
    $self->current_page( $page );
    
    croak( 'Fewer than one entry per page!' ) if $self->entries_per_page < 1;

    $self->current_page( $self->first_page ) unless defined $self->current_page;
    $self->current_page( $self->first_page ) if $self->current_page < $self->first_page;
    $self->current_page( $self->last_page  ) if $self->current_page > $self->last_page;
}

# SQL::Abstract::_recurse_where eats the WHERE clause 
#sub where {
#   my ( $self, $where_ref ) = @_;
#
#   return $self->_where unless $where_ref;
#
#   my $where_copy;
#
#   if ( ref( $where_ref ) eq 'HASH' ) {
#       $where_copy = { %$where_ref };
#   }
#   elsif ( ref( $where_ref ) eq 'ARRAY' )
#   {
#       $where_copy = [ @$where_ref ];
#   }
#   else
#   {
#       die "WHERE clause [$where_ref] must be specified as an ARRAYREF or HASHREF";
#   }
#
#   # this will get eaten, but the caller's value is now protected
#   $self->_where( $where_copy );
#}

=item set_syntax( [ $name || $class || $coderef ] )

Changes the syntax used to generate the C<limit> or other phrase that restricts
the results set to the required page.

The syntax is implemented as a method called on the pager, which can be
queried to provide the C<$rows> and C<$offset> parameters (see the subclasses
included in this distribution).

=over 4

=item $class

A class with a C<make_limit> method.

=item $name

Name of a class in the C<Class::DBI::Plugin::Pager::> namespace, which has a
C<make_limit> method.

=item $coderef

Will be called as a method on the pager object, so receives the pager as its
argument.

=item (no args)

Called without args, will default to C<LimitOffset>, which causes
L<Class::DBI::Plugin::Pager::LimitOffset|Class::DBI::Plugin::Pager::LimitOffset>
to be used.

=back

=cut

sub set_syntax {
    my ( $proto, $syntax ) = @_;

    # pick up default from subclass, or load from LimitOffset
    $syntax ||= $proto->can( 'make_limit' );
    $syntax ||= 'LimitOffset';

    if ( ref( $syntax ) eq 'CODE' )
    {
        $proto->_syntax( $syntax );
        return $syntax;
    }

    my $format_class = $syntax =~ '::' ? $syntax : "Class::DBI::Plugin::Pager::$syntax";

    $format_class->require || croak "error loading $format_class: $UNIVERSAL::require::ERROR";

    my $formatter = $format_class->can( 'make_limit' ) || croak "no make_limit method in $format_class";

    $proto->_syntax( $formatter );

    return $formatter;
}

=item auto_set_syntax

This is called automatically when you call C<pager>, and attempts to set the
syntax automatically.

If you are using a subclass of the pager, this method will not be called.

Will C<die> if using Oracle or DB2, since there is no simple syntax for limiting
the results set. DB2 has a C<FETCH> keyword, but that seems to apply to a
cursor and I don't know if there is a cursor available to the pager. There
should probably be others to add to the unsupported list.

Supports the following drivers:

                      DRIVER        CDBI::P::Pager subclass
    my %supported = ( pg        => 'LimitOffset',
                      mysql     => 'LimitOffset', # older versions need LimitXY
                      sqlite    => 'LimitOffset', # or LimitYX
                      sqlite2   => 'LimitOffset', # or LimitYX
                      interbase => 'RowsTo',
                      firebird  => 'RowsTo',
                      );

Older versions of MySQL should use the LimitXY syntax. You'll need to set it
manually, either by C<use CDBI::P::Pager::LimitXY>, or by passing
C<syntax =E<gt> 'LimitXY'> to a method call, or call C<set_syntax> directly.

Any driver not in the supported or unsupported lists defaults to LimitOffset.

Any additions to the supported and unsupported lists gratefully received.

=cut

sub auto_set_syntax {
    my ( $self ) = @_;

    # not an exhaustive list
    my %not_supported = ( oracle => 'Oracle',
                          db2    => 'DB2',
                          );

    # additions welcome
    my %supported = ( pg        => 'LimitOffset',
                      mysql     => 'LimitOffset', # older versions need LimitXY
                      sqlite    => 'LimitOffset', # or LimitYX
                      sqlite2   => 'LimitOffset', # or LimitYX
                      interbase => 'RowsTo',
                      firebird  => 'RowsTo',
                      );

    my $cdbi = $self->_cdbi_app;

    my $driver = lc( $cdbi->__driver );

    die __PACKAGE__ . " can't build limit clauses for $not_supported{ $driver }"
        if $not_supported{ $driver };
        
    #warn sprintf "Setting syntax to %s for $driver", $supported{ $driver } || 'LimitOffset';

    $self->set_syntax( $supported{ $driver } || 'LimitOffset' );
}

1;

__END__

#=for notes
#
#Would this work?
#
#with $limit and $offset defined.
#
#my $last = $limit + $offset
#
#my $order_by_str = join( ', ', @$order_by )
#
#$cdbi->set_sql( emulate_limit => <<'');
#    SELECT * FROM (
#        SELECT TOP $limit * FROM (
#            SELECT TOP $last __ESSENTIAL__
#            FROM __TABLE__
#            ORDER BY $order_by_str ASC
#        ) AS foo ORDER BY $order_by_str DESC
#    ) AS bar ORDER BY $order_by_str ASC
#
#
#e.g. MS Access (thanks Emanuele Zeppieri)
#
#to add LIMIT/OFFSET to this query:
#
#SELECT my_column
#FROM my_table
#ORDER BY my_column ASC
#
#say with the values LIMIT=5 OFFSET=10, you have to resort to the TOP
#clause and re-write it this way:
#
#SELECT * FROM (
#   SELECT TOP 5 * FROM (
#       SELECT TOP 15 my_column
#       FROM my_table
#       ORDER BY my_column ASC
#   ) AS foo ORDER BY my_column DESC
#) AS bar ORDER BY my_column ASC
#
#=cut

=back

=head2 SUBCLASSING

The 'limit' syntax can be set by using a subclass, e.g.

    use Class::DBI::Plugin::Pager::RowsTo;

instead of setting at runtime. A subclass looks like this:

    package Class::DBI::Plugin::Pager::RowsTo;
    use base 'Class::DBI::Plugin::Pager';

    sub make_limit {
        my ( $self ) = @_;

        my $offset = $self->skipped;
        my $rows   = $self->entries_per_page;

        my $last = $rows + $offset;

        return "ROWS $offset TO $last";
    }

    1;

You can omit the C<use base> and switch syntax by calling
C<$pager-E<gt>set_syntax( 'RowsTo' )>. Or you can leave in the C<use base> and
still say C<$pager-E<gt>set_syntax( 'RowsTo' )>, because in this case the class is
C<require>d and the C<import> in the base class doesn't get called. Or something.
At any rate, It Works.

The subclasses implement the following LIMIT syntaxes:

=over

=item Class::DBI::Plugin::Pager::LimitOffset

    LIMIT $rows OFFSET $offset

This is the default if your driver is not in the list of known drivers.

This should work for PostgreSQL, more recent MySQL, SQLite, and maybe some
others.

=item Class::DBI::Plugin::LimitXY

    LIMIT $offset, $rows

Older versions of MySQL.

=item Class::DBI::Plugin::LimitYX

    LIMIT $rows, $offset

SQLite.

=item Class::DBI::Plugin::RowsTo

    ROWS $offset TO $offset + $rows

InterBase, also FireBird, maybe others?

=back

=head1 TODO

I've only used this on an older version of MySQL. Reports of this thing
working (or not) elsewhere would be useful.

It should be possible to use C<set_sql> to build the complex queries
required by some databases to emulate LIMIT (see notes in source).

=head1 CAVEATS

This class can't implement the subselect mechanism required by some databases
to emulate the LIMIT phrase, because it only has access to the WHERE clause,
not the whole SQL statement. At the moment.

Each query issues two requests to the database - the first to count the entire
result set, the second to retrieve the required subset of results. If your
tables are small it may be quicker to use L<Class::DBI::Pager|Class::DBI::Pager>.

The C<order_by> clause means the database has to retrieve (internally) and sort
the entire results set, before chopping out the requested subset. It's probably
a good idea to have an index on the column(s) used to order the results. For
huge tables, this approach to paging may be too inefficient.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub L<https://github.com/majesticcpan/class-dbi-plugin-pager>. 
Feel free to fork the repository and submit pull requests!

=head1 DEPENDENCIES

L<SQL::Abstract|SQL::Abstract>,
L<Data::Page|Data::Page>,
L<Class::DBI::Plugin::AbstractCount|Class::DBI::Plugin::AbstractCount>,
L<Class::Accessor|Class::Accessor>,
L<Class::Data::Inheritable|Class::Data::Inheritable>,
L<Carp|Carp>.

=head1 SEE ALSO

L<Class::DBI::Pager|Class::DBI::Pager> does a similar job, but retrieves
the entire results set into memory before chopping out the page you want.

=head1 BUGS

Please report all bugs via the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-Plugin-Pager>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2012 by David Baird.

Copyright 2012 Nikolay S. C<majestic@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Baird

