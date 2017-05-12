use strict;
use warnings;
use MRO::Compat 'c3';

package DBIx::FlexibleBinding;
our $VERSION = '2.0.4'; # VERSION
# ABSTRACT: Greater statement placeholder and data-binding flexibility.
use DBI             ();
use Exporter        ();
use Message::String ();
use Scalar::Util    ( 'reftype', 'blessed', 'weaken' );
use Sub::Util       ( 'set_subname' );
use namespace::clean;
use Params::Callbacks ( 'callback' );
use message << 'EOF';
CRIT_EXP_AREF_AFTER Expected a reference to an ARRAY after argument (%s)
CRIT_UNEXP_ARG      Unexpected argument (%s)
CRIT_EXP_SUB_NAMES  Expected a sub name, or reference to an array of sub names
CRIT_EXP_HANDLE     Expected a %s::database or statement handle 
CRIT_DBI            A DBI error occurred\n%s 
CRIT_PROXY_UNDEF    Handle (%s) undefined 
EOF

our @ISA                  = qw(DBI Exporter);
our @EXPORT               = qw(callback);
our $AUTO_BINDING_ENABLED = 1;

sub _is_arrayref
{
    return ref( $_[0] ) && reftype( $_[0] ) eq 'ARRAY';
}

sub _is_hashref
{
    return ref( $_[0] ) && reftype( $_[0] ) eq 'HASH';
}

sub _as_list_or_ref
{
    return wantarray ? @{ $_[0] } : $_[0]
        if defined $_[0];
    return wantarray ? () : undef;
}

sub _create_namespace_alias
{
    my ( $package, $ns_alias ) = @_;
    return $package unless $ns_alias;
    no strict 'refs';
    for ( '', 'db', 'st' ) {
        my $ext .= $_ ? "\::$_" : $_;
        $ext .= '::';
        *{ $ns_alias . $ext } = *{ $package . $ext };
    }
    return $package;
}

sub _create_dbi_handle_proxies
{
    my ( $package, $caller, $list_of_sub_names ) = @_;
    return $package unless $list_of_sub_names;
    if ( ref $list_of_sub_names ) {
        CRIT_EXP_SUB_NAMES
            unless _is_arrayref( $list_of_sub_names );
        for my $sub_name ( @$list_of_sub_names ) {
            $package->_create_dbi_handle_proxy( $caller, $sub_name );
        }
    }
    else {
        $package->_create_dbi_handle_proxy( $caller, $list_of_sub_names );
    }
    return $package;
}

our %proxies;

sub _create_dbi_handle_proxy
{
    # A DBI Handle Proxy is a subroutine masquerading as a database or
    # statement handle object in the calling package namespace. They're
    # intended to function as a pure convenience if that convenience is
    # wanted.
    my ( $package, $caller, $sub_name ) = @_;
    my $fqpi = "$caller\::$sub_name";
    no strict 'refs';
    *$fqpi = set_subname(
        $sub_name => sub {
            unshift @_, ( $package, $fqpi );
            goto &_service_call_to_a_dbi_handle_proxy;
        }
    );
    $proxies{$fqpi} = undef;
    return $package;
}

sub _service_call_to_a_dbi_handle_proxy
{
    # This is the handler servicing calls to a DBI Handle Proxy. It
    # imparts a set of overloaded behaviours on the object, each
    # triggered by a different usage context.
    my ( $package, $fqpi, @args ) = @_;
    return $proxies{$fqpi}
        unless @args;
    if ( @args == 1 ) {
        unless ( $args[0] ) {
            undef $proxies{$fqpi};
            return $proxies{$fqpi};
        }
        if ( blessed( $args[0] ) ) {
            if ( $args[0]->isa( "$package\::db" ) ) {
                weaken( $proxies{$fqpi} = $args[0] );
            }
            elsif ( $args[0]->isa( "$package\::st" ) ) {
                weaken( $proxies{$fqpi} = $args[0] );
            }
            else {
                CRIT_EXP_HANDLE( $package );
            }
            return $proxies{$fqpi};
        }
    }
    if ( $args[0] =~ m{^dbi:}i ) {
        $proxies{$fqpi} = $package->connect( @args )
            or CRIT_DBI( $DBI::errstr );
    }
    else {
        CRIT_PROXY_UNDEF( $fqpi )
            unless $proxies{$fqpi};
        my $proxy = $proxies{$fqpi};
        $proxy->execute( @args )
            if $proxy->isa( "$package\::st" );
        return $proxy->getrows( @args );
    }
    return $proxies{$fqpi};
}

sub import
{
    my ( $package, @args ) = @_;
    my $caller = caller;
    @_ = ( $package );

    while ( @args ) {
        my $arg = shift( @args );

        if ( substr( $arg, 0, 1 ) eq '-' ) {
            if ( $arg eq '-alias' || $arg eq '-as' ) {
                my $ns_alias = shift @args;
                $package->_create_namespace_alias( $ns_alias );
            }
            elsif ( $arg eq '-subs' ) {
                my $list_of_sub_names = shift @args;
                $package->_create_dbi_handle_proxies( $caller, $list_of_sub_names );
            }
            else {
                CRIT_UNEXP_ARG( $arg );
            }
        }
        else {
            push @_, $arg;
        }
    }

    goto &Exporter::import;
}

sub connect
{
    my ( $invocant, $dsn, $user, $pass, $attr ) = @_;
    $attr = {}
        unless defined $attr;
    $attr->{RootClass} = ref( $invocant ) || $invocant
        unless defined $attr->{RootClass};
    return $invocant->next::method( $dsn, $user, $pass, $attr );
}

package    # Hide from PAUSE
    DBIx::FlexibleBinding::db;
our $VERSION = '2.0.4'; # VERSION

BEGIN {
    *_is_hashref     = \&DBIx::FlexibleBinding::_is_hashref;
    *_as_list_or_ref = \&DBIx::FlexibleBinding::_as_list_or_ref;
}

use Params::Callbacks 'callbacks';
use namespace::clean;

our @ISA = 'DBI::db';

sub do
{
    my ( $callbacks, $dbh, $sth, @bind_values ) = &callbacks;
    my $result;
    unless ( ref $sth ) {
        my $attr;
        $attr = shift @bind_values
            if _is_hashref( $bind_values[0] );
        $sth = $dbh->prepare( $sth, $attr );
        return undef
            if $sth->err;
    }
    $result = $sth->execute( @bind_values );
    return undef
        if $sth->err;
    local $_;
    $result = $callbacks->smart_transform( $_ = $result )
        if @$callbacks;
    return $result;
}

sub prepare
{
    my ( $dbh, $stmt, @args ) = @_;
    my @params;
    if ( $stmt =~ m{:\w+\b} ) {
        @params = $stmt =~ m{:(\w+)\b}g;
        $stmt =~ s{:\w+\b}{?}g;
    }
    elsif ( $stmt =~ m{\@\w+\b} ) {
        @params = $stmt =~ m{(\@\w+)\b}g;
        $stmt =~ s{\@\w+\b}{?}g;
    }
    elsif ( $stmt =~ m{\?\d+\b} ) {
        @params = $stmt =~ m{\?(\d+)\b}g;
        $stmt =~ s{\?\d+\b}{?}g;
    }
    else {
        # No recognisable placeholders to extract/convert
    }
    my $sth = $dbh->next::method( $stmt, @args );
    return $sth
        unless defined $sth;
    $sth->_init_private_attributes( \@params );
    return $sth;
}

sub getrows_arrayref
{
    my ( $callbacks, $dbh, $sth, @bind_values ) = &callbacks;
    unless ( ref $sth ) {
        my $attr;
        $attr = shift( @bind_values )
            if _is_hashref( $bind_values[0] );
        $sth = $dbh->prepare( $sth, $attr );
        return _as_list_or_ref( undef )
            if $sth->err;
    }
    $sth->execute( @bind_values );
    return _as_list_or_ref( undef )
        if $sth->err;
    return $sth->getrows_arrayref( $callbacks );
}

sub getrows_hashref
{
    my ( $callbacks, $dbh, $sth, @bind_values ) = &callbacks;
    unless ( ref $sth ) {
        my $attr;
        $attr = shift( @bind_values )
            if _is_hashref( $bind_values[0] );
        $sth = $dbh->prepare( $sth, $attr );
        return _as_list_or_ref( undef )
            if $sth->err;
    }
    $sth->execute( @bind_values );
    return _as_list_or_ref( undef )
        if $sth->err;
    return $sth->getrows_hashref( $callbacks );
}

sub getrow_arrayref
{
    my ( $callbacks, $dbh, $sth, @bind_values ) = &callbacks;
    unless ( ref $sth ) {
        my $attr;
        $attr = shift( @bind_values )
            if _is_hashref( $bind_values[0] );
        $sth = $dbh->prepare( $sth, $attr );
        return undef
            if $sth->err;
    }

    $sth->execute( @bind_values );
    return undef
        if $sth->err;
    return $sth->getrow_arrayref( $callbacks );
}

sub getrow_hashref
{
    my ( $callbacks, $dbh, $sth, @bind_values ) = &callbacks;
    unless ( ref $sth ) {
        my $attr;
        $attr = shift( @bind_values )
            if _is_hashref( $bind_values[0] );
        $sth = $dbh->prepare( $sth, $attr );
        return undef
            if $sth->err;
    }
    $sth->execute( @bind_values );
    return undef
        if $sth->err;
    return $sth->getrow_hashref( $callbacks );
}

BEGIN {
    *getrows = \&getrows_hashref;
    *getrow  = \&getrow_hashref;
}

package    # Hide from PAUSE
    DBIx::FlexibleBinding::st;
our $VERSION = '2.0.4'; # VERSION

BEGIN {
    *_is_arrayref    = \&DBIx::FlexibleBinding::_is_arrayref;
    *_is_hashref     = \&DBIx::FlexibleBinding::_is_hashref;
    *_as_list_or_ref = \&DBIx::FlexibleBinding::_as_list_or_ref;
}

use List::MoreUtils   ( 'any' );
use Params::Callbacks ( 'callbacks' );
use namespace::clean;
use message << 'EOF';
ERR_EXP_AHR         Expected a reference to a HASH or ARRAY
ERR_MISSING_BIND_ID Binding identifier is missing
ERR_BAD_BIND_ID     Bad binding identifier (%s)
EOF

our @ISA = 'DBI::st';

sub _priv_attr
{
    my ( $sth, $name, $value, @more ) = @_;
    return $sth->{private_dbix_flexbind}
        unless @_ > 1;
    $sth->{private_dbix_flexbind}{$name} = $value
        if @_ > 2;
    return $sth->{private_dbix_flexbind}{$name}
        unless @more;
    while ( @more ) {
        $name = shift @more;
        $sth->{private_dbix_flexbind}{$name} = shift @more;
    }
    return $sth;
}

sub _auto_bind
{
    my ( $sth, $value ) = @_;
    return $sth->_priv_attr( 'auto_bind' )
        unless @_ > 1;
    $sth->_priv_attr( auto_bind => !!$value );
    return $sth;
}

sub _param_count
{
    my ( $sth, $value ) = @_;
    if ( @_ > 1 ) {
        $sth->_priv_attr( 'param_count' => $value );
        return $sth;
    }
    $sth->_priv_attr( 'param_count' => {} )
        unless defined $sth->_priv_attr( 'param_count' );
    return %{ $sth->_priv_attr( 'param_count' ) }
        if wantarray;
    return $sth->_priv_attr( 'param_count' );
}

sub _param_order
{
    my ( $sth, $value ) = @_;
    if ( @_ > 1 ) {
        $sth->_priv_attr( param_order => $value );
        return $sth;
    }
    $sth->_priv_attr( param_order => [] )
        unless defined $sth->_priv_attr( 'param_order' );
    return @{ $sth->_priv_attr( 'param_order' ) }
        if wantarray;
    return $sth->_priv_attr( 'param_order' );
}

sub _using_named
{
    my ( $sth, $value ) = @_;
    return $sth->_priv_attr( 'using_named' )
        unless @_ > 1;
    if ( $sth->_priv_attr( using_named => !!$value ) ) {
        $sth->_priv_attr( using_positional => '',
                          using_numbered   => '' );
    }
    return $sth;
}

sub _using_numbered
{
    my ( $sth, $value ) = @_;
    return $sth->_priv_attr( 'using_numbered' ) unless @_ > 1;
    if ( $sth->_priv_attr( using_numbered => !!$value ) ) {
        $sth->_priv_attr( using_positional => '',
                          using_named      => '' );
    }
    return $sth;
}

sub _using_positional
{
    my ( $sth, $value ) = @_;
    return $sth->_priv_attr( 'using_positional' ) unless @_ > 1;
    if ( $sth->_priv_attr( using_positional => !!$value ) ) {
        $sth->_priv_attr( using_numbered => '',
                          using_named    => '' );
    }
    return $sth;
}

sub _init_private_attributes
{
    my ( $sth, $params_arrayref ) = @_;
    return $sth unless _is_arrayref( $params_arrayref );
    $sth->_priv_attr;
    $sth->_param_order( $params_arrayref );
    return $sth->_using_positional( 1 )
        unless @$params_arrayref;
    $sth->_auto_bind( $DBIx::FlexibleBinding::AUTO_BINDING_ENABLED );
    my $param_count = $sth->_param_count;
    for my $param ( @$params_arrayref ) {

        if ( defined $param_count->{$param} ) {
            $param_count->{$param}++;
        }
        else {
            $param_count->{$param} = 1;
        }
    }
    return $sth->_using_named( 1 )
        if any {/\D/} @$params_arrayref;
    return $sth->_using_numbered( 1 );
}

sub _bind_arrayref
{
    my ( $sth, $arrayref ) = @_;
    for ( my $n = 0; $n < @$arrayref; $n++ ) {
        $sth->bind_param( $n + 1, $arrayref->[$n] );
    }
    return $sth;
}

sub _bind_hashref
{
    my ( $sth, $hashref ) = @_;
    while ( my ( $k, $v ) = each %$hashref ) {
        $sth->bind_param( $k, $v );
    }
    return $sth;
}

sub _bind
{
    my ( $sth, @args ) = @_;
    return $sth
        unless @args;
    return $sth->_bind_arrayref( \@args )
        if $sth->_using_positional;
    if ( @args == 1 && ref( $args[0] ) ) {
        return $sth->set_err( $DBI::stderr, ERR_EXP_AHR )
            unless _is_arrayref( $args[0] ) || _is_hashref( $args[0] );
        return $sth->_bind_hashref( $args[0] )
            if _is_hashref( $args[0] );
        return $sth->_bind_arrayref( $args[0] )
            if $sth->_using_numbered;
        return $sth->_bind_hashref( { @{ $args[0] } } );
    }
    if ( @args ) {
        return $sth->_bind_arrayref( \@args )
            if $sth->_using_numbered;
        return $sth->_bind_hashref( {@args} );
    }
    return $sth;
}

sub bind_param
{
    my ( $sth, $param, $value, $attr ) = @_;
    return $sth->set_err( $DBI::stderr, ERR_MISSING_BIND_ID )
        unless $param;
    return $sth->set_err( $DBI::stderr, ERR_BAD_BIND_ID( $param ) )
        if $param =~ m{[^\@\w]};
    my $result;
    if ( $sth->_using_positional ) {
        $result = $sth->next::method( $param, $value, $attr );
    }
    else {
        my ( $pos, $count, %param_count ) = ( 0, 0, $sth->_param_count );
        for my $identifier ( $sth->_param_order ) {
            $pos++;
            if ( $identifier eq $param ) {
                last if ++$count > $param_count{$param};
                $result = $sth->next::method( $pos, $value, $attr );
            }
        }
    }
    return $result;
}

sub execute
{
    my ( $sth, @bind_values ) = @_;
    my $rows;
    if ( $sth->_auto_bind ) {
        $sth->_bind( @bind_values );
        $rows = $sth->next::method();
    }
    else {
        if ( @bind_values == 1 && _is_arrayref( $bind_values[0] ) ) {
            $rows = $sth->next::method( @{ $bind_values[0] } );
        }
        else {
            $rows = $sth->next::method( @bind_values );
        }
    }
    return $rows;
}

sub iterate
{
    my ( $callbacks, $sth, @bind_values ) = &callbacks;
    my $rows = $sth->execute( @bind_values );
    return $rows unless defined $rows;
    my $iter_fn = sub { $sth->getrow( $callbacks ) };
    return bless( $iter_fn, 'DBIx::FlexibleBinding::Iterator' );
}

sub getrows_arrayref
{
    my ( $callbacks, $sth, @args ) = &callbacks;
    unless ( $sth->{Active} ) {
        $sth->execute( @args );
        return _as_list_or_ref( undef )
            if $sth->err;
    }
    my $result = $sth->fetchall_arrayref;
    return _as_list_or_ref( $result )
        if $sth->err or not defined $result;
    local $_;
    $result = [ map { $callbacks->transform( $_ ) } @$result ]
        if @$callbacks;
    return _as_list_or_ref( $result );
}

sub getrows_hashref
{
    my ( $callbacks, $sth, @args ) = &callbacks;
    unless ( $sth->{Active} ) {
        $sth->execute( @args );
        return _as_list_or_ref( undef )
            if $sth->err;
    }
    my $result = $sth->fetchall_arrayref( {} );
    return _as_list_or_ref( $result )
        if $sth->err or not defined $result;
    local $_;
    $result = [ map { $callbacks->transform( $_ ) } @$result ]
        if @$callbacks;
    return _as_list_or_ref( $result );
}

sub getrow_arrayref
{
    my ( $callbacks, $sth, @args ) = &callbacks;
    unless ( $sth->{Active} ) {
        $sth->execute( @args );
        return undef
            if $sth->err;
    }
    my $result = $sth->fetchrow_arrayref;
    return $result
        if $sth->err or not defined $result;
    local $_;
    $result = [@$result];
    $result = $callbacks->smart_transform( $_ = $result )
        if @$callbacks;
    return $result;
}

sub getrow_hashref
{
    my ( $callbacks, $sth, @args ) = &callbacks;
    unless ( $sth->{Active} ) {
        $sth->execute( @args );
        return undef
            if $sth->err;
    }
    my $result = $sth->fetchrow_hashref;
    return $result
        if $sth->err or not defined $result;
    local $_;
    $result = $callbacks->smart_transform( $_ = $result )
        if @$callbacks;
    return $result;
}

BEGIN {
    *getrows = \&getrows_hashref;
    *getrow  = \&getrow_hashref;
}

package    # Hide from PAUSE
    DBIx::FlexibleBinding::Iterator;
our $VERSION = '2.0.4'; # VERSION

use Params::Callbacks ( 'callbacks' );
use namespace::clean;

sub for_each
{
    my ( $callbacks, $iter ) = &callbacks;
    my @results;
    local $_;
    while ( my @items = $iter->() ) {
        last if @items == 1 and not defined $items[0];
        push @results, map { $callbacks->transform( $_ ) } @items;
    }
    return wantarray ? @results : \@results;
}

1;

=pod

=encoding utf8

=head1 NAME

DBIx::FlexibleBinding - Greater statement placeholder and data-binding flexibility.

=head1 VERSION

version 2.0.4

=head1 SYNOPSIS

This module extends the DBI allowing you choose from a variety of supported
parameter placeholder and binding patterns as well as offering simplified
ways to interact with datasources, while improving general readability.

    #########################################################
    # SCENARIO 1                                            #
    # A connect followed by a prepare-execute-process cycle #
    #########################################################

    use DBIx::FlexibleBinding;
    use constant DSN => 'dbi:mysql:test;host=127.0.0.1';
    use constant SQL => << '//';
    SELECT solarSystemName AS name
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    # Pretty standard connect, just with the new DBI subclass ...
    #
    my $dbh = DBIx::FlexibleBinding->connect(DSN, '', '', { RaiseError => 1 });

    # Prepare statement using named placeholders (not bad for MySQL, eh) ...
    #
    my $sth = $dbh->prepare(SQL);

    # Execute the statement (parameter binding is automatic) ...
    #
    my $rv = $sth->execute(is_regional => 1,
                           minimum_security => 1.0);

    # Fetch and transform rows with a blocking callback to get only the data you
    # want without cluttering the place up with intermediate state ...
    #
    my @system_names = $sth->getrows_hashref(callback { $_->{name} });

    ############################################################################
    # SCENARIO 2                                                               #
    # Let's simplify the previous scenario using the database handle's version #
    # of that getrows_hashref method.                                       #
    ############################################################################

    use DBIx::FlexibleBinding -alias => 'DFB';
    use constant DSN => 'dbi:mysql:test;host=127.0.0.1';
    use constant SQL => << '//';
    SELECT solarSystemName AS name
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    # Pretty standard connect, this time with the DBI subclass package alias ...
    #
    my $dbh = DFB->connect(DSN, '', '', { RaiseError => 1 });

    # Cut out the middle men ...
    #
    my @system_names = $dbh->getrows_hashref(SQL,
                                             is_regional => 1,
                                             minimum_security => 1.0,
                                             callback { $_->{name} });

    #############################################################################
    # SCENARIO 3                                                                #
    # The subclass import method provides a versatile mechanism for simplifying #
    # matters further.                                                          #
    #############################################################################

    use DBIx::FlexibleBinding -subs => [ 'MyDB' ];
    use constant DSN => 'dbi:mysql:test;host=127.0.0.1';
    use constant SQL => << '//';
    SELECT solarSystemName AS name
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    # MyDB will represent our datasource; initialise it ...
    #
    MyDB DSN, '', '', { RaiseError => 1 };

    # Cut out the middle men and some of the line-noise, too ...
    #
    my @system_names = MyDB(SQL,
                            is_regional => 1,
                            minimum_security => 1.0,
                            callback { $_->{name} });

=head1 DESCRIPTION

This module subclasses the DBI to provide improvements and greater flexibility
in the following areas:

=over 2

=item * Parameter placeholders and data binding

=item * Data retrieval and processing

=item * Accessing and interacting with datasources

=back

It may be most useful in situations that require a lot of database code to
be written quickly.

=head2 Parameter placeholders and data binding

This module provides support for a wider range of parameter placeholder and
data-binding schemes. As well as continued support for the simple positional
placeholders (C<?>), additional support is provided for numeric placeholders (C<:N>
and C<?N>), and named placeholders (C<:NAME> and C<@NAME>).

As for the process of binding data values to parameters: that is, by default,
now completely automated, removing a significant part of the workload from the
prepare-bind-execute cycle. It is, however, possible to swtch off automatic
data-binding globally and on a statement-by-statement basis.

The following familiar operations have been modified to accommodate all of these
changes, though developers continue to use them as they always have done:

=over 2

=item * C<$DATABASE_HANDLE-E<gt>prepare($STATEMENT, \%ATTR);>

=item * C<$DATABASE_HANDLE-E<gt>do($STATEMENT, \%ATTR, @DATA);>

=item * C<$STATEMENT_HANDLE-E<gt>bind_param($NAME_OR_POSITION, $VALUE, \%ATTR);>

=item * C<$STATEMENT_HANDLE-E<gt>execute(@DATA);>

=back

=head2 Data retrieval and processing

Four new methods, each available for database B<and> statement handles, have
been implemented:

=over 2

=item * C<getrow_arrayref>

=item * C<getrow_hashref>

=item * C<getrows_arrayref>

=item * C<getrows_hashref>

=back

These methods complement DBI's existing fetch methods, providing new ways to
retrieve and process data.

=head2 Accessing and interacting with datasources

The module's C<-subs> import option may be used to create subroutines,
during the compile phase, and export them to the caller's namespace for
use later as representations of database and statement handles.

=over 2

=item * Use for connecting to datasources

    use DBIx::FlexibleBinding -subs => [ 'MyDB' ];

    # Pass in any set of well-formed DBI->connect(...) arguments to associate
    # your name with a live database connection ...
    #
    MyDB( 'dbi:mysql:test;host=127.0.0.1', '', '', { RaiseError => 1 } );

    # Or, simply pass an existing database handle as the only argument ...
    #
    MyDB($dbh);

=item * Use them to represent database handles

    use DBIx::FlexibleBinding -subs => [ 'MyDB' ];
    use constant SQL => << '//';
    SELECT *
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    MyDB( 'dbi:mysql:test;host=127.0.0.1', '', '', { RaiseError => 1 } );

    # If your name is already associated with a database handle then just call
    # it with no parameters to use it as such ...
    #
    my $sth = MyDB->prepare(SQL);

=item * Use them to represent statement handles

    use DBIx::FlexibleBinding -subs => [ 'MyDB', 'solar_systems' ];
    use constant SQL => << '//';
    SELECT *
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    MyDB( 'dbi:mysql:test;host=127.0.0.1', '', '', { RaiseError => 1 } );

    my $sth = MyDB->prepare(SQL);

    # Simply call the statement handle proxy, passing a statement handle in as
    # the only argument ...
    #
    solar_systems($sth);

=item * Use to interact with the represented database and statement handles

    use DBIx::FlexibleBinding -subs => [ 'MyDB', 'solar_systems' ];
    use constant SQL => << '//';
    SELECT *
      FROM mapsolarsystems
     WHERE regional  = :is_regional
       AND security >= :minimum_security
    //

    MyDB( 'dbi:mysql:test;host=127.0.0.1', '', '', { RaiseError => 1 } );

    # Use the database handle proxy to prepare, bind and execute statements, then
    # retrieve the results ...
    #
    # Use the database handle proxy to prepare, bind and execute statements, then
    # retrieve the results ...
    #
    my $array_of_hashrefs = MyDB(SQL,
                                 is_regional => 1,
                                 minimum_security => 1.0);

    # In list context, results come back as lists ...
    #
    my @array_of_hashrefs = MyDB(SQL,
                                 is_regional => 1,
                                 minimum_security => 1.0);

    # You can use proxies to represent statements, too. Simply pass in a statement
    # handle as the only argument ...
    #
    my $sth = MyDB->prepare(SQL);
    solar_systems($sth);    # Using "solar_systems" as statement proxy.

    # Now, when called with other types of arguments, those argument values are
    # bound and the statement is executed ...
    #
    my $array_of_hashrefs = solar_systems(is_regional => 1,
                                          minimum_security => 1.0);

    # In list context, results come back as lists ...
    #
    my @array_of_hashrefs = solar_systems(is_regional => 1,
                                          minimum_security => 1.0);

    # Statements requiring no parameters cannot be used in this manner because
    # making a call to a statement proxy with an arity of zero results in the
    # statement handle being returned. In this situation, use something like
    # undef as an argument (it will be ignored in this particular instance) ...
    #
    my $rv = statement_proxy(undef);
    #
    # Meh, you can't win 'em all!

=back

=head1 PACKAGE GLOBALS

=head2 $DBIx::FlexibleBinding::AUTO_BINDING_ENABLED

A boolean setting used to determine whether or not automatic binding is enabled
or disabled globally.

The default setting is C<"1"> (I<enabled>).

=head1 IMPORT TAGS AND OPTIONS

=head2 -alias

This option may be used by the caller to select an alias to use for this
package's unwieldly namespace.

    use DBIx::FlexibleBinding -alias => 'DBIF';

    my $dbh = DBIF->connect('dbi:SQLite:test.db', '', '');

=head2 -subs

This option may be used to create subroutines, during the compile phase, in
the caller's namespace to be used as representations of database and statement
handles.

    use DBIx::FlexibleBinding -subs => [ 'MyDB' ];

    # Initialise by passing in a valid set of DBI->connect(...) arguments.
    # The database handle will be the return value.
    #
    MyDB 'dbi:mysql:test;host=127.0.0.1', '', '', { RaiseError => 1 };

    # Or, initialise by passing in a DBI database handle.
    # The handle is also the return value.
    #
    MyDB $dbh;

    # Once initialised, use the subroutine as you would a DBI database handle.
    #
    my $statement = << '//';
    SELECT solarSystemName AS name
      FROM mapsolarsystems
     WHERE security >= :minimum_security
    //
    my $sth = MyDB->prepare($statement);

    # Or use it as an expressive time-saver!
    #
    my $array_of_hashrefs = MyDB($statement, security => 1.0);
    my @system_names = MyDB($statement, minimum_security => 1.0, callback {
        return $_->{name};
    });
    MyDB $statement, minimum_security => 1.0, callback {
        my ($row) = @_;
        print "$row->{name}\n";
    };

=head1 CLASS METHODS

=head2 connect

    $dbh = DBIx::FlexibleBinding->connect($data_source, $user, $pass)
      or die $DBI::errstr;
    $dbh = DBIx::FlexibleBinding->connect($data_source, $user, $pass, \%attr)
      or die $DBI::errstr;

Establishes a database connection, or session, to the requested data_source and
returns a database handle object if the connection succeeds or undef if it does
not.

Refer to L<http://search.cpan.org/dist/DBI/DBI.pm#connect> for a more detailed
description of this method.

=head1 DATABASE HANDLE METHODS

=head2 do

    $rows = $dbh->do($statement_string) or die $dbh->errstr;
    $rows = $dbh->do($statement_string, @bind_values) or die $dbh->errstr;
    $rows = $dbh->do($statement_string, \%attr) or die $dbh->errstr;
    $rows = $dbh->do($statement_string, \%attr, @bind_values) or die $dbh->errstr;
    $rows = $dbh->do($statement_handle) or die $dbh->errstr;
    $rows = $dbh->do($statement_handle, @bind_values) or die $dbh->errstr;


Prepares (if necessary) and executes a single statement. Returns the number of
rows affected or undef on error. A return value of -1 means the number of rows
is not known, not applicable, or not available. When no rows have been affected
this method continues the C<DBI> tradition of returning C<0E0> on successful
execution and C<undef> on failure.

The C<do> method accepts optional callbacks for further processing of the result.

The C<do> implementation provided by this module allows for some minor
deviations in usage over the standard C<DBI> implementation. In spite
of this, the new method may be used just like the original.

Refer to L<http://search.cpan.org/dist/DBI/DBI.pm#do> for a more detailed
description of this method.

B<Examples>

=over

=item 1. Statement attributes are now optional:

    $sql = << '//';
    UPDATE employees
       SET salary = :salary
     WHERE employee_id = :employee_id
    //

    $dbh->do($sql, employee_id => 52, salary => 35_000)
      or die $dbh->errstr;

A reference to the statement attributes hash is no longer required, even if it's
empty. If, however, a hash reference is supplied as the first parameter then it
would be used for that purpose.

=item 2. Prepared statements now may be re-used:

    $sth = $dbh->prepare(<< '//');
    UPDATE employees
       SET salary = ?
     WHERE employee_id = ?
    //

    $dbh->do($sth, 35_000, 52) or die $dbh->errstr;

A prepared statement may also be used in lieu of a statement string. In such
cases, referencing a statement attributes hash is neither required nor expected.

=back

=head2 prepare

    $sth = $dbh->prepare($statement_string);
    $sth = $dbh->prepare($statement_string, \%attr);

Prepares a statement for later execution by the database engine and returns a
reference to a statement handle object.

Refer to L<http://search.cpan.org/dist/DBI/DBI.pm#prepare> for a more detailed
description of this method.

B<Examples>

=over

=item 1. Prepare a statement using positional placeholders:

    $sql = << '//';
    UPDATE employees
       SET salary = ?
     WHERE employee_id = ?
    //

    $sth = $dbh->prepare($sql);

=item 2. Prepare a statement using named placeholders:

I<(Yes, even for those MySQL connections!)>

    $sql = << '//';
    UPDATE employees
       SET salary = :salary
     WHERE employee_id = :employee_id
    //

    $sth = $dbh->prepare($sql);

=back

=head2 getrows_arrayref I<(database handles)>

    $results = $dbh->getrows_arrayref($statement_string, @bind_values);
    @results = $dbh->getrows_arrayref($statement_string, @bind_values);
    $results = $dbh->getrows_arrayref($statement_string, \%attr, @bind_values);
    @results = $dbh->getrows_arrayref($statement_string, \%attr, @bind_values);
    $results = $dbh->getrows_arrayref($statement_handle, @bind_values);
    @results = $dbh->getrows_arrayref($statement_handle, @bind_values);

Prepares (if necessary) and executes a single statement with the specified data
bindings and fetches the result set as an array of array references.

The C<getrows_arrayref> method accepts optional callbacks for further processing
of the results by the caller.

B<Examples>

=over

=item 1. Prepare, execute it then get the results as a reference:

    $sql = << '//';
    SELECT solarSystemName AS name
         , security
      FROM mapsolarsystems
     WHERE regional  = 1
       AND security >= :minimum_security
    //

    $systems = $dbh->getrows_arrayref($sql, minimum_security => 1.0);

    # Returns a structure something like this:
    #
    # [ [ 'Kisogo',      '1' ],
    #   [ 'New Caldari', '1' ],
    #   [ 'Amarr',       '1' ],
    #   [ 'Bourynes',    '1' ],
    #   [ 'Ryddinjorn',  '1' ],
    #   [ 'Luminaire',   '1' ],
    #   [ 'Duripant',    '1' ],
    #   [ 'Yulai',       '1' ] ]

=item 2. Re-use a prepared statement, execute it then return the results as a list:

We'll use the query from Example 1 but have the results returned as a list for
further processing by the caller.

    $sth = $dbh->prepare($sql);

    @systems = $dbh->getrows_arrayref($sql, minimum_security => 1.0);

    for my $system (@systems) {
        printf "%-11s %.1f\n", @$system;
    }

    # Output:
    #
    # Kisogo      1.0
    # New Caldari 1.0
    # Amarr       1.0
    # Bourynes    1.0
    # Ryddinjorn  1.0
    # Luminaire   1.0
    # Duripant    1.0
    # Yulai       1.0

=item 3. Re-use a prepared statement, execute it then return modified results as a
reference:

We'll use the query from Example 1 but have the results returned as a list
for further processing by a caller who will be using callbacks to modify those
results.

    $sth = $dbh->prepare($sql);

    $systems = $dbh->getrows_arrayref($sql, minimum_security => 1.0, callback {
        my ($row) = @_;
        return sprintf("%-11s %.1f\n", @$row);
    });

    # Returns a structure something like this:
    #
    # [ 'Kisogo      1.0',
    #   'New Caldari 1.0',
    #   'Amarr       1.0',
    #   'Bourynes    1.0',
    #   'Ryddinjorn  1.0',
    #   'Luminaire   1.0',
    #   'Duripant    1.0',
    #   'Yulai       1.0' ]

=back

=head2 getrows_hashref I<(database handles)>

    $results = $dbh->getrows_hashref($statement_string, @bind_values);
    @results = $dbh->getrows_hashref($statement_string, @bind_values);
    $results = $dbh->getrows_hashref($statement_string, \%attr, @bind_values);
    @results = $dbh->getrows_hashref($statement_string, \%attr, @bind_values);
    $results = $dbh->getrows_hashref($statement_handle, @bind_values);
    @results = $dbh->getrows_hashref($statement_handle, @bind_values);

Prepares (if necessary) and executes a single statement with the specified data
bindings and fetches the result set as an array of hash references.

The C<getrows_hashref> method accepts optional callbacks for further processing
of the results by the caller.

B<Examples>

=over

=item 1. Prepare, execute it then get the results as a reference:

    $sql = << '//';
    SELECT solarSystemName AS name
         , security
      FROM mapsolarsystems
     WHERE regional  = 1
       AND security >= :minimum_security
    //

    $systems = $dbh->getrows_hashref($sql, minimum_security => 1.0);

    # Returns a structure something like this:
    #
    # [ { name => 'Kisogo',      security => '1' },
    #   { name => 'New Caldari', security => '1' },
    #   { name => 'Amarr',       security => '1' },
    #   { name => 'Bourynes',    security => '1' },
    #   { name => 'Ryddinjorn',  security => '1' },
    #   { name => 'Luminaire',   security => '1' },
    #   { name => 'Duripant',    security => '1' },
    #   { name => 'Yulai',       security => '1' } ]

=item 2. Re-use a prepared statement, execute it then return the results as a list:

We'll use the query from Example 1 but have the results returned as a list for
further processing by the caller.

    $sth = $dbh->prepare($sql);

    @systems = $dbh->getrows_hashref($sql, minimum_security => 1.0);

    for my $system (@systems) {
        printf "%-11s %.1f\n", @{$system}{'name', 'security'}; # Hash slice
    }

    # Output:
    #
    # Kisogo      1.0
    # New Caldari 1.0
    # Amarr       1.0
    # Bourynes    1.0
    # Ryddinjorn  1.0
    # Luminaire   1.0
    # Duripant    1.0
    # Yulai       1.0

=item 3. Re-use a prepared statement, execute it then return modified results as a
reference:

We'll use the query from Example 1 but have the results returned as a list
for further processing by a caller who will be using callbacks to modify those
results.

    $sth = $dbh->prepare($sql);

    $systems = $dbh->getrows_hashref($sql, minimum_security => 1.0, callback {
        sprintf("%-11s %.1f\n", @{$_}{'name', 'security'}); # Hash slice
    });

    # Returns a structure something like this:
    #
    # [ 'Kisogo      1.0',
    #   'New Caldari 1.0',
    #   'Amarr       1.0',
    #   'Bourynes    1.0',
    #   'Ryddinjorn  1.0',
    #   'Luminaire   1.0',
    #   'Duripant    1.0',
    #   'Yulai       1.0' ]

=back

=head2 getrows I<(database handles)>

    $results = $dbh->getrows($statement_string, @bind_values);
    @results = $dbh->getrows($statement_string, @bind_values);
    $results = $dbh->getrows($statement_string, \%attr, @bind_values);
    @results = $dbh->getrows($statement_string, \%attr, @bind_values);
    $results = $dbh->getrows($statement_handle, @bind_values);
    @results = $dbh->getrows$statement_handle, @bind_values);

Alias for C<getrows_hashref>.

If array references are preferred, have the symbol table glob point alias the 
C<getrows_arrayref> method.

The C<getrows> method accepts optional callbacks for further processing
of the results by the caller.

=head2 getrow_arrayref I<(database handles)>

    $result = $dbh->getrow_arrayref($statement_string, @bind_values);
    $result = $dbh->getrow_arrayref($statement_string, \%attr, @bind_values);
    $result = $dbh->getrow_arrayref($statement_handle, @bind_values);

Prepares (if necessary) and executes a single statement with the specified data
bindings and fetches the first row as an array reference.

The C<getrow_arrayref> method accepts optional callbacks for further processing
of the result by the caller.

=head2 getrow_hashref I<(database handles)>

    $result = $dbh->getrow_hashref($statement_string, @bind_values);
    $result = $dbh->getrow_hashref($statement_string, \%attr, @bind_values);
    $result = $dbh->getrow_hashref($statement_handle, @bind_values);

Prepares (if necessary) and executes a single statement with the specified data
bindings and fetches the first row as a hash reference.

The C<getrow_hashref> method accepts optional callbacks for further processing
of the result by the caller.

=head2 getrow I<(database handles)>

    $result = $dbh->getrow($statement_string, @bind_values);
    $result = $dbh->getrow($statement_string, \%attr, @bind_values);
    $result = $dbh->getrow($statement_handle, @bind_values);

Alias for C<getrow_hashref>.

If array references are preferred, have the symbol table glob point alias the 
C<getrows_arrayref> method.

The C<getrow> method accepts optional callbacks for further processing
of the result by the caller.

=head1 STATEMENT HANDLE METHODS

=head2 bind_param

    $sth->bind_param($param_num, $bind_value)
    $sth->bind_param($param_num, $bind_value, \%attr)
    $sth->bind_param($param_num, $bind_value, $bind_type)

    $sth->bind_param($param_name, $bind_value)
    $sth->bind_param($param_name, $bind_value, \%attr)
    $sth->bind_param($param_name, $bind_value, $bind_type)

The C<bind_param> method associates (binds) a value to a placeholder embedded in the
prepared statement. The implementation provided by this module allows the use of
parameter names, if appropriate, in addition to parameter positions.

I<Refer to L<http://search.cpan.org/dist/DBI/DBI.pm#bind_param> for a more detailed
explanation of how to use this method>.

=head2 execute

    $rv = $sth->execute() or die $DBI::errstr;
    $rv = $sth->execute(@bind_values) or die $DBI::errstr;

Perform whatever processing is necessary to execute the prepared statement. An
C<undef> is returned if an error occurs. A successful call returns true regardless
of the number of rows affected, even if it's zero.

Refer to L<http://search.cpan.org/dist/DBI/DBI.pm#execute> for a more detailed
description of this method.

B<Examples>

=over

=item Use prepare, execute and getrow_hashref with a callback to modify my data:

    use strict;
    use warnings;

    use DBIx::FlexibleBinding -subs => [ 'TestDB' ];
    use Data::Dumper;
    use Test::More;

    $Data::Dumper::Terse  = 1;
    $Data::Dumper::Indent = 1;

    TestDB 'dbi:mysql:test', '', '', { RaiseError => 1 };

    my $sth = TestDB->prepare(<< '//');
       SELECT solarSystemID   AS id
            , solarSystemName AS name
            , security
         FROM mapsolarsystems
        WHERE solarSystemName RLIKE "^U[^0-9\-]+$"
     ORDER BY id, name, security DESC
        LIMIT 5
    //

    $sth->execute() or die $DBI::errstr;

    my @rows;
    my @callback_list = (
        callback {
            my ($row) = @_;
            $row->{filled_with} = ( $row->{security} >= 0.5 )
                ? 'Carebears' : 'Yarrbears';
            $row->{security} = sprintf('%.1f', $row->{security});
            return $row;
        }
    );

    while ( my $row = $sth->getrow_hashref(@callback_list) ) {
        push @rows, $row;
    }

    my $expected_result = [
       {
         'name' => 'Uplingur',
         'filled_with' => 'Yarrbears',
         'id' => '30000037',
         'security' => '0.4'
       },
       {
         'security' => '0.4',
         'id' => '30000040',
         'name' => 'Uzistoon',
         'filled_with' => 'Yarrbears'
       },
       {
         'name' => 'Usroh',
         'filled_with' => 'Carebears',
         'id' => '30000068',
         'security' => '0.6'
       },
       {
         'filled_with' => 'Yarrbears',
         'name' => 'Uhtafal',
         'id' => '30000101',
         'security' => '0.5'
       },
       {
         'security' => '0.3',
         'id' => '30000114',
         'name' => 'Ubtes',
         'filled_with' => 'Yarrbears'
       }
    ];

    is_deeply( \@rows, $expected_result, 'iterate' )
        and diag( Dumper(\@rows) );
    done_testing();

=back

=head2 iterate

    $iterator = $sth->iterate() or die $DBI::errstr;
    $iterator = $sth->iterate(@bind_values) or die $DBI::errstr;

Perform whatever processing is necessary to execute the prepared statement. An
C<undef> is returned if an error occurs. A successful call returns an iterator
which can be used to traverse the result set.

B<Examples>

=over

=item 1. Using an iterator and callbacks to process the result set:

    use strict;
    use warnings;

    use DBIx::FlexibleBinding -subs => [ 'TestDB' ];
    use Data::Dumper;
    use Test::More;

    $Data::Dumper::Terse  = 1;
    $Data::Dumper::Indent = 1;

    my @drivers = grep { /^SQLite$/ } DBI->available_drivers();

    SKIP: {
      skip("iterate tests (No DBD::SQLite installed)", 1) unless @drivers;

      TestDB "dbi:SQLite:test.db", '', '', { RaiseError => 1 };

      my $sth = TestDB->prepare(<< '//');
       SELECT solarSystemID   AS id
            , solarSystemName AS name
            , security
         FROM mapsolarsystems
        WHERE solarSystemName REGEXP "^U[^0-9\-]+$"
     ORDER BY id, name, security DESC
        LIMIT 5
    //

    # Iterate over the result set
    # ---------------------------
    # We also queue up a sneaky callback to modify each row of data as it
    # is fetched from the result set.

      my $it = $sth->iterate( callback {
          my ($row) = @_;
          $row->{filled_with} = ( $row->{security} >= 0.5 )
              ? 'Carebears' : 'Yarrbears';
          $row->{security} = sprintf('%.1f', $row->{security});
          return $row;
      } );

      my @rows;
      while ( my $row = $it->() ) {
          push @rows, $row;
      }

    # Done, now check the results ...

      my $expected_result = [
         {
           'name' => 'Uplingur',
           'filled_with' => 'Yarrbears',
           'id' => '30000037',
           'security' => '0.4'
         },
         {
           'security' => '0.4',
           'id' => '30000040',
           'name' => 'Uzistoon',
           'filled_with' => 'Yarrbears'
         },
         {
           'name' => 'Usroh',
           'filled_with' => 'Carebears',
           'id' => '30000068',
           'security' => '0.6'
         },
         {
           'filled_with' => 'Yarrbears',
           'name' => 'Uhtafal',
           'id' => '30000101',
           'security' => '0.5'
         },
         {
           'security' => '0.3',
           'id' => '30000114',
           'name' => 'Ubtes',
           'filled_with' => 'Yarrbears'
         }
      ];

      is_deeply( \@rows, $expected_result, 'iterate' )
          and diag( Dumper(\@rows) );
    }

    done_testing();

In this example, we're traversing the result set using an iterator. As we iterate
through the result set, a callback is applied to each row and we're left with
an array of transformed rows.

=item 2. Using an iterator's C<for_each> method and callbacks to process the
result set:

    use strict;
    use warnings;

    use DBIx::FlexibleBinding -subs => [ 'TestDB' ];
    use Data::Dumper;
    use Test::More;

    $Data::Dumper::Terse  = 1;
    $Data::Dumper::Indent = 1;

    my @drivers = grep { /^SQLite$/ } DBI->available_drivers();

    SKIP: {
      skip("iterate tests (No DBD::SQLite installed)", 1) unless @drivers;

      TestDB "dbi:SQLite:test.db", '', '', { RaiseError => 1 };

      my $sth = TestDB->prepare(<< '//');
       SELECT solarSystemID   AS id
            , solarSystemName AS name
            , security
         FROM mapsolarsystems
        WHERE solarSystemName REGEXP "^U[^0-9\-]+$"
     ORDER BY id, name, security DESC
        LIMIT 5
    //

    # Iterate over the result set
    # ---------------------------
    # This time around we call the iterator's "for_each" method to process
    # the data. Bonus: we haven't had to store the iterator anywhere or
    # pre-declare an empty array to accommodate our rows.

      my @rows = $sth->iterate->for_each( callback {
          my ($row) = @_;
          $row->{filled_with} = ( $row->{security} >= 0.5 )
              ? 'Carebears' : 'Yarrbears';
          $row->{security} = sprintf('%.1f', $row->{security});
          return $row;
      } );

    # Done, now check the results ...

      my $expected_result = [
         {
           'name' => 'Uplingur',
           'filled_with' => 'Yarrbears',
           'id' => '30000037',
           'security' => '0.4'
         },
         {
           'security' => '0.4',
           'id' => '30000040',
           'name' => 'Uzistoon',
           'filled_with' => 'Yarrbears'
         },
         {
           'name' => 'Usroh',
           'filled_with' => 'Carebears',
           'id' => '30000068',
           'security' => '0.6'
         },
         {
           'filled_with' => 'Yarrbears',
           'name' => 'Uhtafal',
           'id' => '30000101',
           'security' => '0.5'
         },
         {
           'security' => '0.3',
           'id' => '30000114',
           'name' => 'Ubtes',
           'filled_with' => 'Yarrbears'
         }
      ];

      is_deeply( \@rows, $expected_result, 'iterate' )
          and diag( Dumper(\@rows) );
    }

    done_testing();

Like the previous example, we're traversing the result set using an iterator but
this time around we have done away with C<$it> in favour of calling the iterator's
own C<for_each> method. The callback we were using to process each row of the
result set has now been passed into the C<for_each> method also eliminating a
C<while> loop and an empty declaration for C<@rows>.

=back

=head2 getrows_arrayref I<(database handles)>

    $results = $sth->getrows_arrayref();
    @results = $sth->getrows_arrayref();

Fetches the entire result set as an array of array references.

The C<getrows_arrayref> method accepts optional callbacks for further processing
of the results by the caller.

=head2 getrows_hashref I<(database handles)>

    $results = $sth->getrows_hashref();
    @results = $sth->getrows_hashref();

Fetches the entire result set as an array of hash references.

The C<getrows_hashref> method accepts optional callbacks for further processing
of the results by the caller.

=head2 getrows I<(database handles)>

    $results = $sth->getrows();
    @results = $sth->getrows();

Alias for C<getrows_hashref>.

If array references are preferred, have the symbol table glob point alias the 
C<getrows_arrayref> method.

The C<getrows> method accepts optional callbacks for further processing
of the results by the caller.

=head2 getrow_arrayref I<(database handles)>

    $result = $sth->getrow_arrayref();

Fetches the next row as an array reference. Returns C<undef> if there are no more
rows available.

The C<getrow_arrayref> method accepts optional callbacks for further processing
of the result by the caller.

=head2 getrow_hashref I<(database handles)>

    $result = $sth->getrow_hashref();

Fetches the next row as a hash reference. Returns C<undef> if there are no more
rows available.

The C<getrow_hashref> method accepts optional callbacks for further processing
of the result by the caller.

=head2 getrow I<(database handles)>

    $result = $sth->getrow();

Alias for C<getrow_hashref>.

If array references are preferred, have the symbol table glob point alias the 
C<getrows_arrayref> method.

The C<getrow> method accepts optional callbacks for further processing
of the result by the caller.

=head1 EXPORTS

The following symbols are exported by default:

=head2 callback

To enable the namespace using this module to take advantage of the callbacks,
which are one of its main features, without the unnecessary burden of also
including the module that provides the feature I<(see L<Params::Callbacks> for
more detailed information)>.

=head1 SEE ALSO

=over 2

=item * L<DBI>

=item * L<Params::Callbacks>

=back

=head1 REPOSITORY

=over 2

=item * L<https://github.com/cpanic/DBIx-FlexibleBinding>

=item * L<http://search.cpan.org/dist/DBIx-FlexibleBinding/lib/DBIx/FlexibleBinding.pm>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-anybinding at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-FlexibleBinding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::FlexibleBinding


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-FlexibleBinding>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-FlexibleBinding>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-FlexibleBinding>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-FlexibleBinding/>

=back

=head1 ACKNOWLEDGEMENTS

Many, many thanks to the CPANTesters network.

Test data set extracted from Fuzzwork's MySQL conversion of CCP's EVE Online Static
Data Export:

=over 2

=item * Fuzzwork L<https://www.fuzzwork.co.uk/>

=item * EVE Online L<http://www.eveonline.com/>

=back

Eternal gratitude to GitHub contributors:

=over 2

=item * Syohei Yoshida L<http://search.cpan.org/~syohex/>

=back

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
