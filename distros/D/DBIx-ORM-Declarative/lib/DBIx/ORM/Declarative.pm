package DBIx::ORM::Declarative;

use strict;
use Carp;
use DBIx::ORM::Declarative::Schema;
use DBIx::ORM::Declarative::Table;
use DBIx::ORM::Declarative::Join;
use DBIx::ORM::Declarative::Row;
use DBIx::ORM::Declarative::JRow;

use vars qw($VERSION);
$VERSION = '0.22';

use constant BASE_CLASS   => 'DBIx::ORM::Declarative';
use constant SCHEMA_CLASS => 'DBIx::ORM::Declarative::Schema';
use constant TABLE_CLASS  => 'DBIx::ORM::Declarative::Table';
use constant JOIN_CLASS   => 'DBIx::ORM::Declarative::Join';
use constant ROW_CLASS    => 'DBIx::ORM::Declarative::Row';
use constant JROW_CLASS   => 'DBIx::ORM::Declarative::JRow';

# Use this to /really/ supress warnings
use constant w__noop => sub { };

# The error we return when we have an embarassment of riches
use constant E_TOOMANYROWS => 'Database error: underdetermined data set';

# The error we return when we've lost the row we just inserted
use constant E_NOROWSFOUND => 'Database error: inserted data not found';

# We need to register table & join creation methods; otherwise, we
# may wind up blowing up when we try to deal with a table that has
# a column with the same name as the table itself
my %table_methods = ();
my %join_methods = ();

sub table_method
{
    my ($self, $table, $method) = @_;
    return $table_methods{$table} if $table_methods{$table} and not $method;
    $table_methods{$table} = $method;
}

sub join_method
{
    my ($self, $join, $method) = @_;
    return $join_methods{$join} if $join_methods{$join} and not $method;
    $join_methods{$join} = $method;
}

# This applies a method by name - necessary for perl < 5.6
sub apply_method
{
    my ($obj, $method, $wantarray, @args) = @_;
    # Check to see if we can apply it directly
    my @rv;
    eval
    {
        # We don't need any warnings here
        local $SIG{__WARN__} = __PACKAGE__->w__noop;
        if($wantarray)
        {
            @rv = $obj->$method(@args);
        }
        else
        {
            $rv[0] = $obj->$method(@args);
        }
    } ;
    if(not $@)
    {
        return $wantarray?@rv:$rv[0];
    }
    my $res = UNIVERSAL::can($obj, $method);
    if($res)
    {
        return $wantarray?($res->($obj, @args)):scalar($res->($obj, @args));
    }
    $res = UNIVERSAL::can($obj, 'AUTOLOAD');
    if($res)
    {
        # We can't directly use the result in $res, because we need to know
        # which AUTOLOAD it found.  Just use eval for now.  *sigh*.
        if($wantarray)
        {
            eval "\@rv = \$obj->$method(\@args)";
        }
        else
        {
            eval "\$rv[0] = \$obj->$method(\@args)";
        }
        carp $@ if $@;
        return $wantarray?@rv:$rv[0];
    }
    my $class = ref $obj || $obj;
    carp qq(Can't locate object method "$method" via package "$class");
}

# Create a new DBIx::ORM::Declarative object
# Accepts args as a hash
# Recognized args are "handle" and "debug"
# Unrecognized args are ignored
# If used as an object method, copy the handle and debug status, if available
sub new
{
    my ($self, %args) = @_;
    my $class = ref $self || $self;
    my $handle = exists $args{handle}?$args{handle}:$self->handle;
    my $debug = delete $args{debug} || $self->debug_level || 0;
    if(not exists $args{handle} and DBI->can('connect') and $args{dsn})
    {
        $handle = DBI->connect(@args{qw(dsn username password)},
            { RaiseError => 0, PrintError => 0, AutoCommit => 0 });
    }
    my $rv = bless { __handle => $handle, __debug_level => $debug }, $class;
    return $rv;
}

# Custom import method to create schemas during the "use" clause.
sub import
{
    my ($package, @args) = @_;
    if(not ref $args[0])
    {
        $package->schema(@args);
        return;
    }
    for my $arg (@args)
    {
        if(not ref $arg)
        {
            carp "Can't import '$arg' in '$package'";
            next;
        }
        $package->schema(%$arg);
    }
}

# Get or set the DBI handle
sub handle
{
    my $self = shift;
    return unless ref $self;
    if(@_)
    {
        delete $self->{__handle};
        $self->{__handle} = $_[0] if $_[0];
        return $self;
    }
    return unless exists $self->{__handle};
    return $self->{__handle};
}

# Get or set the debug level
sub debug_level
{
    my $self = shift;
    return 0 unless ref $self;
    if(@_)
    {
        $self->{__debug_level} = $_[0] || 0;
        return $self;
    }
    return $self->{__debug_level} || 0;
}

# Get the current schema name, or switch to a new schema, or create a
# new schema class.
sub schema
{
    my ($self, @args) = @_;
    if(@args<2)
    {
        if(@args==1)
        {
            my $schema = shift @args;
            return $self->apply_method($schema,wantarray)
                if $schema and $self->can($schema);
            return $self;
        }
        my $schema;
        eval { $schema = $self->_schema; };
        return $schema;
    }

    # Creating/updating a schema class - process the args
    my %args = @args;
    my $schema = delete $args{schema};
    my $from_dual = delete $args{from_dual};
    my $limit_clause = delete $args{limit_clause} || 'LIMIT %offset%,%count%';

    carp "missing schema argument" and return unless $schema;
    my $schema_class = $self->SCHEMA_CLASS . "::$schema";

    # The meat of the declarations
    my $tables = delete $args{tables} || [ ];
    my $joins = delete $args{joins} || [ ];
    my $aliases = delete $args{table_aliases} || { };

    # We're gonna do a whole mess of symbolic references...
    no strict 'refs';
    my $schema_method_name = $self->BASE_CLASS . "::$schema";
    if(not @{$schema_class . '::ISA'})
    {
        # Create the class heirarchy
        @{$schema_class . '::ISA'} = ($self->SCHEMA_CLASS);

        # Let's see if we're called from import...
        my ($pkg, $file, $line, $sub) = caller(1);
        if($sub eq __PACKAGE__ . '::import' and $pkg ne 'main')
        {
            # Yep - insert ourselves in the upstream @ISA...
            my $isaref = \@{$pkg . '::ISA'};
            push @$isaref, $schema_class unless $pkg->isa($schema_class);
        }

        # Information methods
        *{$schema_class . '::_schema' } = sub { $schema; };
        *{$schema_class . '::_schema_class' } =
        *{$schema_class . '::_class' } = sub { $schema_class; };
        *{$schema_class . '::_limit_clause' } = sub { $limit_clause; };
        *{$schema_class . '::_from_dual' } = sub { $from_dual; };

        # A constructor/mutator
        *{$schema_method_name} = sub
        {
            my ($self) = @_;
            my $rv = $self->new;
            bless $rv, $schema_class unless $rv->isa($schema_class);
            return $rv;
        } ;
    }

    # Create the tables
    $schema_class->table(%$_) foreach @$tables;

    # Create the aliases, if we have any
    $schema_class->alias($_, $aliases->{$_}) foreach keys %$aliases;
    
    # Create any joins we might have
    $schema_class->join(%$_) foreach @$joins;

    return &{$schema_method_name}($self);
}

1;
