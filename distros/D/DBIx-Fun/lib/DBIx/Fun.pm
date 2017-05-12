#$Id: Fun.pm,v 1.7 2006/10/04 19:16:27 jef539 Exp $
package DBIx::Fun;

=head1 NAME

DBIx::Fun - access database stored procedures as methods

=head1 SYNOPSIS

    use DBI;
    use DBIx::Fun;
    
    my $dbh = DBI->connect('dbi:Oracle:orcl', 'scott', 'tiger');
    
    my $fun = DBIx::Fun->context($dbh);
    
    # print 5 random numbers from the database
    
    $fun->dbms_random->initialize( 123 );
    
    for my $i ( 1 .. 5 ) {
        printf "%d %d\n", $i, $fun->dbms_random->random;
    }
    
    $fun->dbms_random->terminate;
    
    $dbh->disconnect;

=head1 DESCRIPTION

This module allow Perl programs to access database stored procedures
as if they were methods on an object.  

=cut

use strict;
use Carp ();    # don't import any subs, call them explicitly

our $VERSION = '0.02';

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw( fun auto );
our @EXPORT_FAIL = qw( auto );

=head1 CONSTRUCTORS

=cut

#======
# new()
#    not directly callable
#    only in subclasses, as a class method

sub new {
    my ( $class, %args ) = @_;
    Carp::croak "new() not an object method on " . ref($class) if ref($class);

    Carp::croak "Can't instantiate base class " . __PACKAGE__
      if $class eq __PACKAGE__;

    my $self = bless { cache => {}, %args }, $class;

    # override _init in subclass
    $self->_init();
    return $self;
}

# override _init in subclass
sub _init { }


=head2 context( $dbh ) 

Creates a C<DBI::Fun> subclass matching the driver of $dbh, e.g., 
DBD::Oracle => DBIx::Fun::Oracle.  

    # call as a class method
    my $fun = DBIx::Fun->context($dbh);

Privately used as an object method to create child contexts.
  
=cut

sub context {
    my ( $self, @args ) = @_;

    # handle first element = dbh by adding 'dbh' hash key
    if ( eval { $args[0]->isa('DBI::db') } ) {
        unshift @args, 'dbh';
    }

    my %args = @args;

    # inherit settings of parent context
    my %self;
    %self = %$self if eval { $self->isa('HASH') };

    my $dbh = $args{dbh} || $self{dbh};
    Carp::croak "No db handle supplied to context()" unless $dbh;

    my $driver  = $dbh->{Driver}{Name};
    my $package = "DBIx::Fun::$driver";

    # validate package name as Perl identifier
    Carp::croak("Invalid package name $package")
      unless $package =~ /^([^\W\d]\w*)(::[^\W\d]\w*)*$/;

    # firesafe code from DBI:
    # prevents files from messing with the current package

    eval "package 
             DBIx::Fun::_firesafe;
             require $package;"
      or Carp::croak($@)
      unless $INC{$package};

    return $package->new( %self, %args );
}

=head2 fun( $dbh ) 

Returns a context for $dbh, cached in $dbh.  Exportable as a function.

   use DBIx::Fun 'fun';

   print fun($dbh)->sysdate, "\n";
   sleep 60;

   # function signature cached in $dbh 
   print fun($dbh)->sysdate, "\n";

=cut

sub fun {
    my ($dbh) = @_;
    $dbh->{private_dbix_fun} ||= { cache => {} };
    return DBIx::Fun->context(
        dbh => $dbh,
        %{ $dbh->{private_dbix_fun} }
    );
}

=head2 auto

Not an actual function.  Importing 'auto' will load fun() into the 
DBI::db package, exposing it as a method on database handles.

   use DBIx::Fun 'auto';

   print $dbh->fun->sysdate, "\n";

=cut

sub export_fail {
    my ( $class, @name ) = @_;

    my @fail;
    for my $name (@name) {
        if ( $name eq 'auto' ) {
            if ( not defined &DBI::db::fun ) {
                *DBI::db::fun = \&fun;
            }
        }
        else {
            push @fail, $name;
        }
    }
    return @fail;
}

=head1 METHODS

=head2 dbh

Accessor for the underlying database handle.

=head2 commit, rollback, disconnect

Convenience methods on the underlying database handle.

=cut

sub dbh        { $_[0]->{dbh} }
sub commit     { $_[0]->dbh->commit }
sub rollback   { $_[0]->dbh->rollback }
sub disconnect { $_[0]->dbh->disconnect }

=head1 PRIVATE METHODS

=cut

#======
# _path
#    private accessor for subclasses, returning the context 'path'

sub _path { @{ $_[0]->{path} || [] } }

#======
# _croak_notfound($name)
#    simulate normal Perl error messages for undefined subs

sub _croak_notfound {
    local $Carp::Verbose = 0;
    Carp::croak "Undefined subroutine &" . __PACKAGE__ . "::$_[0] called"
      if @_ < 2;
    my $class = ref( $_[0] ) || $_[0] || __PACKAGE__;
    Carp::croak "Can't locate object method \"$_[1]\" via package \"$class\"";
}

#======
# _lookup( $name )
#    return a coderef or context for $name
#    override in subclasses

sub _lookup { $_[0]->_croak_notfound( $_[1] ) }

# localized variable to prevent calling AUTOLOAD recursively
our $in_AUTOLOAD = undef;

=head2 _call($name, [ @args ] )

Call stored proc C<$name> with arguments @args.

C<$fun-E<gt>_call()> can be used to call a stored procedure 
that contains characters not allowed in a Perl identifier, or 
that clashes with a method defined in Perl.

=cut

sub _call {
    my ( $self, $name ) = @_;
    local $in_AUTOLOAD = $name;

    my $obj = $self->_lookup($name);

    return $obj->(@_) if ref($obj) eq 'CODE';
    return $obj if $obj;
    $self->_croak_notfound($name);
}

sub can {
    my ( $self, $name ) = @_;
    my $obj = $self->SUPER::can($name);
    return $obj if $obj;

    $obj = $self->_lookup($name);
    print $obj;
    return $obj if ref($obj) eq 'CODE';
    return sub { $obj } if defined $obj;
    return undef;
}

#======
# AUTOLOAD()
#    goto &_call

sub AUTOLOAD {
    our $AUTOLOAD;

    Carp::croak "AUTOLOAD recursion: $in_AUTOLOAD -> $AUTOLOAD"
      if defined $in_AUTOLOAD;

    local $in_AUTOLOAD = $AUTOLOAD;

    ( my $method = $AUTOLOAD ) =~ s/.*:://;
    my $self = $_[0];

    # if this is an object method call, place the method name
    # into the argument list and go directly to _call

    if ( ref($self) and eval { $self->isa(__PACKAGE__) } ) {
        splice( @_, 1, 0, $method );
        goto &_call;
    }

    # for class method and plain subroutine calls, croak

    _croak_notfound($method);
}

# don't AUTOLOAD DESTROY!
sub DESTROY { local $@; }

1;
__END__
