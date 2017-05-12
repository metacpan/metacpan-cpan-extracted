package Alzabo::Schema;

use strict;
use vars qw($VERSION %CACHE);

use Alzabo;
use Alzabo::Config;
use Alzabo::Driver;
use Alzabo::Exceptions ( abbr => 'params_exception' );
use Alzabo::RDBMSRules;
use Alzabo::SQLMaker;
use Alzabo::Utils;

use File::Spec;

use Params::Validate qw( :all );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

use Storable ();
use Tie::IxHash ();

$VERSION = 2.0;

1;

sub _load_from_file
{
    my $class = shift;

    my %p = validate( @_, { name => { type => SCALAR },
                          } );

    # Making these (particularly from files) is expensive.
    return $class->_cached_schema($p{name}) if $class->_cached_schema($p{name});

    my $schema_dir = Alzabo::Config::schema_dir;
    my $file =  $class->_schema_filename( $p{name} );

    -e $file or Alzabo::Exception::Params->throw( error => "No saved schema named $p{name} ($file)" );

    my $version_file = File::Spec->catfile( $schema_dir, $p{name}, "$p{name}.version" );

    my $version = 0;

    my $fh = do { local *FH; };
    if ( -e $version_file )
    {
        open $fh, "<$version_file"
            or Alzabo::Exception::System->throw( error => "Unable to open $version_file: $!\n" );
        $version = join '', <$fh>;
        close $fh
            or Alzabo::Exception::System->throw( error => "Unable to close $version_file: $!" );
    }

    if ( $version < $Alzabo::VERSION )
    {
        require Alzabo::BackCompat;

        Alzabo::BackCompat::update_schema( name => $p{name},
                                           version => $version );
    }

    open $fh, "<$file"
        or Alzabo::Exception::System->throw( error => "Unable to open $file: $!" );
    my $schema = Storable::retrieve_fd($fh)
        or Alzabo::Exception::System->throw( error => "Can't retrieve from filehandle" );
    close $fh
        or Alzabo::Exception::System->throw( error => "Unable to close $file: $!" );

    my $rdbms_file = File::Spec->catfile( $schema_dir, $p{name}, "$p{name}.rdbms" );
    open $fh, "<$rdbms_file"
        or Alzabo::Exception::System->throw( error => "Unable to open $rdbms_file: $!\n" );
    my $rdbms = join '', <$fh>;
    close $fh
        or Alzabo::Exception::System->throw( error => "Unable to close $rdbms_file: $!" );

    $rdbms =~ s/\s//g;

    ($rdbms) = $rdbms =~ /(\w+)/;

    # This is important because if the user is using MethodMaker, they
    # might be calling this as My::Schema->load_from_file ...
    bless $schema, $class;

    $schema->{driver} = Alzabo::Driver->new( rdbms => $rdbms,
                                             schema => $schema );

    $schema->{rules} = Alzabo::RDBMSRules->new( rdbms => $rdbms );

    $schema->{sql} = Alzabo::SQLMaker->load( rdbms => $rdbms );

    $schema->_save_to_cache;

    return $schema;
}

sub _cached_schema
{
    my $class = shift->isa('Alzabo::Runtime::Schema') ? 'Alzabo::Runtime::Schema' : 'Alzabo::Create::Schema';

    validate_pos( @_, { type => SCALAR } );
    my $name = shift;

    my $schema_dir = Alzabo::Config::schema_dir();
    my $file = $class->_schema_filename($name);

    if (exists $CACHE{$name}{$class}{object})
    {
        my $mtime = (stat($file))[9]
            or Alzabo::Exception::System->throw( error => "can't stat $file: $!" );

        return $CACHE{$name}{$class}{object}
            if $mtime <= $CACHE{$name}{$class}{mtime};
    }
}

sub _schema_filename
{
    my $class = shift;

    return $class->_base_filename(shift) . '.' . $class->_schema_file_type . '.alz';
}

sub _base_filename
{
    shift;
    my $name = shift;

    return File::Spec->catfile( Alzabo::Config::schema_dir(), $name, $name );
}

sub _save_to_cache
{
    my $self = shift;
    my $class = $self->isa('Alzabo::Runtime::Schema') ? 'Alzabo::Runtime::Schema' : 'Alzabo::Create::Schema';
    my $name = $self->name;

    $CACHE{$name}{$class} = { object => $self,
                              mtime => time };
}

sub name
{
    my $self = shift;

    return $self->{name};
}

sub db_schema_name
{
    my $self = shift;

    return
        ( exists $self->{db_schema_name}
          ? $self->{db_schema_name}
          : $self->name
        );
}

sub has_table
{
    my $self = shift;

    validate_pos( @_, { type => SCALAR } );

    return $self->{tables}->FETCH(shift);
}

use constant TABLE_SPEC => { type => SCALAR };

sub table
{
    my $self = shift;
    my ($name) = validate_pos( @_, TABLE_SPEC );

    return
        $self->{tables}->FETCH($name) ||
            params_exception "Table $name doesn't exist in $self->{name}";
}

sub tables
{
    my $self = shift;

    return $self->table(@_) if @_ == 1;
    return map { $self->table($_) } @_  if @_ > 1;
    return $self->{tables}->Values;
}

sub begin_work
{
    shift->driver->begin_work;
}
*start_transaction = \&begin_work;

sub rollback
{
    shift->driver->rollback;
}

sub commit
{
    shift->driver->commit;
}
*finish_transaction = \&commit;

sub run_in_transaction
{
    my $self = shift;
    my $code = shift;

    $self->begin_work;

    my @r;
    if (wantarray)
    {
        @r = eval { $code->() };
    }
    else
    {
        $r[0] = eval { $code->() };
    }

    if (my $e = $@)
    {
        eval { $self->rollback };
        if ( Alzabo::Utils::safe_can( $e, 'rethrow' ) )
        {
            $e->rethrow;
        }
        else
        {
            Alzabo::Exception->throw( error => $e );
        }
    }

    $self->commit;

    return wantarray ? @r : $r[0];
}

sub driver
{
    my $self = shift;

    return $self->{driver};
}

sub rules
{
    my $self = shift;

    return $self->{rules};
}

sub quote_identifiers { $_[0]->{quote_identifiers} }

sub sqlmaker
{
    my $self = shift;
    my %p = validate( @_, { quote_identifiers =>
                            { type    => BOOLEAN,
                              default => $self->{quote_identifiers},
                            },
                          },
                    );

    return $self->{sql}->new( driver => $self->driver,
                              quote_identifiers => $p{quote_identifiers},
                            );
}

__END__

=head1 NAME

Alzabo::Schema - Schema objects

=head1 SYNOPSIS

  use base qw(Alzabo::Schema);

=head1 DESCRIPTION

This is the base class for schema objects..

=head1 METHODS

=head2 name

Returns a string containing the name of the schema.

=head2 table ($name)

Returns an L<C<Alzabo::Table>|Alzabo::Table> object representing the
specified table.

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the schema does not contain the table.

=head2 tables (@optional_list)

If no arguments are given, this method returns a list of all
L<C<Alzabo::Table>|Alzabo::Table> objects in the schema, or in a
scalar context the number of such tables.  If one or more arguments
are given, returns a list of table objects with those names, in the
same order given (or the number of such tables in a scalar context,
but this isn't terribly useful).

An L<C<Alzabo::Exception::Params>|Alzabo::Exceptions> exception is
throws if the schema does not contain one or more of the specified
tables.

=head2 has_table ($name)

Returns a boolean value indicating whether the table exists in the
schema.

=head2 begin_work

Starts a transaction.  Calls to this function may be nested and it
will be handled properly.

=head2 rollback

Rollback a transaction.

=head2 commit

Finishes a transaction with a commit.  If you make multiple calls to
C<begin_work()>, make sure to call this method the same number of
times.

=head2 run_in_transaction ( sub { code... } )

This method takes a subroutine reference and wraps it in a transaction.

It will preserve the context of the caller and returns whatever the
wrapped code would have returned.

=head2 driver

Returns the L<C<Alzabo::Driver>|Alzabo::Driver> object for the schema.

=head2 rules

Returns the L<C<Alzabo::RDBMSRules>|Alzabo::RDBMSRules> object for the
schema.

=head2 sqlmaker

Returns the L<C<Alzabo::SQLMaker>|Alzabo::SQLMaker> object for the
schema.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
