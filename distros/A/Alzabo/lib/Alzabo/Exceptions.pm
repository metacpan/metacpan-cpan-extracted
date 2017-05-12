package Alzabo::Exceptions;

use strict;
use vars qw($VERSION);

use Alzabo::Utils;


$VERSION = 2.0;

my %e;

BEGIN
{
    %e = ( 'Alzabo::Exception' =>
           { description =>
             'Generic exception within the Alzabo API.  Should only be used as a base class.',
             alias => 'exception',
           },

           'Alzabo::Exception::Driver' =>
           { description => 'An attempt to eval a string failed',
             fields => [ 'sql', 'bind' ],
             isa => 'Alzabo::Exception',
             alias => 'driver_exception',
           },

           'Alzabo::Exception::Eval' =>
           { description => 'An attempt to eval a string failed',
             isa => 'Alzabo::Exception',
             alias => 'eval_exception',
           },

           'Alzabo::Exception::Logic' =>
           { description =>
             'An internal logic error occurred (presumably, Alzabo was asked to do something that cannot be done)',
             isa => 'Alzabo::Exception',
             alias => 'logic_exception',
           },

           'Alzabo::Exception::NoSuchRow' =>
           { description => 'An attempt to fetch data from the database for a primary key that did not exist in the specified table',
             isa => 'Alzabo::Exception',
             alias => 'no_such_row_exception',
           },

           'Alzabo::Exception::Params' =>
           { description => 'An exception generated when there is an error in the parameters passed in a method of function call',
             isa => 'Alzabo::Exception',
             alias => 'params_exception',
           },

           'Alzabo::Exception::NotNullable' =>
           { description => 'An exception generated when there is an attempt is made to set a non-nullable column to NULL',
             isa => 'Alzabo::Exception::Params',
             fields => [ 'column_name', 'table_name', 'schema_name' ],
             alias => 'not_nullable_exception',
           },

           'Alzabo::Exception::Panic' =>
           { description => 'An exception generated when something totally unexpected happens',
             isa => 'Alzabo::Exception',
             alias => 'panic_exception',
           },

           'Alzabo::Exception::RDBMSRules' =>
           { description => 'An RDBMS rule check failed',
             isa => 'Alzabo::Exception',
             alias => 'rdbms_rules_exception',
           },

           'Alzabo::Exception::RDBMSRules::RecreateTable' =>
           { description =>
             'An exception generated to indicate the a table needs to be recreated as part of a schema SQL diff',
             isa => 'Alzabo::Exception',
             alias => 'recreate_table_exception',
           },

           'Alzabo::Exception::ReferentialIntegrity' =>
           { description =>
             'An operation was attempted that would violate referential integrity',
             isa => 'Alzabo::Exception',
             alias => 'referential_integrity_exception',
           },

           'Alzabo::Exception::SQL' =>
           { description =>
             'An exception generated when there a logical error in a set of operation on an Alzabo::SQLMaker object',
             isa => 'Alzabo::Exception',
             alias => 'sql_exception',
           },

           'Alzabo::Exception::Storable' =>
           { description => 'An attempt to call a function from the Storable module failed',
             isa => 'Alzabo::Exception',
             alias => 'storable_exception',
           },

           'Alzabo::Exception::System' =>
           { description => 'An attempt to interact with the system failed',
             isa => 'Alzabo::Exception',
             alias => 'system_exception',
           },

           'Alzabo::Exception::VirtualMethod' =>
           { description =>
             'Indicates that the method called must be subclassed in the appropriate class',
             isa => 'Alzabo::Exception',
             alias => 'virtual_method_exception',
           },

         );
}

use Exception::Class (%e);

Alzabo::Exception->Trace(1);

sub import
{
    my ($class, %args) = @_;

    my $caller = caller;
    if ( $args{abbr} )
    {
        foreach my $name ( ref $args{abbr} ? @{ $args{abbr} } : $args{abbr} )
        {
            no strict 'refs';
            die "Unknown exception abbreviation '$name'" unless defined &{$name};
            *{"${caller}::$name"} = \&{$name};
        }
    }
    {
        no strict 'refs';
        *{"${caller}::isa_alzabo_exception"} = \&isa_alzabo_exception;
        *{"${caller}::rethrow_exception"} = \&rethrow_exception;
    }
}

sub isa_alzabo_exception
{
    my ($err, $name) = @_;
    return unless defined $err;

    my $class =
        ! $name
          ? 'Alzabo::Exception'
          : $name =~ /^Alzabo::Exception/
          ? $name
          : "Alzabo::Exception::$name";

    {
        no strict 'refs';
        die "no such exception class $class"
            unless defined(${"${class}::VERSION"});
    }

    return Alzabo::Utils::safe_isa($err, $class);
}

sub rethrow_exception
{
    my $err = shift;

    return unless $err;

    if ( Alzabo::Utils::safe_can( $err, 'rethrow' ) )
    {
        $err->rethrow;
    }
    elsif ( ref $err )
    {
        die $err;
    }
    Alzabo::Exception->throw( error => $err );
}


package Alzabo::Exception;

sub format
{
    my $self = shift;

    if (@_)
    {
        $self->{format} = shift eq 'html' ? 'html' : 'text';
    }

    return $self->{format} || 'text';
}

sub as_string
{
    my $self = shift;

    my $stringify_function = "as_" . $self->format;

    return $self->$stringify_function();
}

sub as_text
{
    return $_[0]->full_message . "\n\n" . $_[0]->trace->as_string;
}

sub as_html
{
    my $self = shift;

    my $msg = $self->full_message;

    require HTML::Entities;
    $msg = HTML::Entities::encode_entities($msg);
    $msg =~ s/\n/<br>/;

    my $html = <<"EOF";
<html><body>
<p align="center"><font face="Verdana, Arial, Helvetica, sans-serif"><b>System error</b></font></p>
<table border="0" cellspacing="0" cellpadding="1">
 <tr>
  <td nowrap align="left" valign="top"><b>error:</b>&nbsp;</td>
  <td align="left" valign="top" nowrap>$msg</td>
 </tr>
 <tr>
  <td align="left" valign="top" nowrap><b>code stack:</b>&nbsp;</td>
  <td align="left" valign="top" nowrap>
EOF

    foreach my $frame ( $self->trace->frames )
    {
        my $filename = HTML::Entities::encode_entities( $frame->filename );
        my $line = $frame->line;

        $html .= "$filename: $line<br>\n";
    }

    $html .= <<'EOF';
  </td>
 </tr>
</table>

</body></html>
EOF

    return $html;
}

package Alzabo::Exception::Driver;

sub full_message
{
    my $self = shift;

    my $msg = $self->error;
    $msg .= "\nSQL: " . $self->sql if $self->sql;

    if ( $self->bind )
    {
        my @bind = map { defined $_ ? $_ : '<undef>' } @{ $self->bind };
        $msg .= "\nBIND: @bind" if @bind;
    }

    return $msg;
}

1;

=head1 NAME

Alzabo::Exceptions - Creates all exception subclasses used in Alzabo.

=head1 SYNOPSIS

  use Alzabo::Exceptions;

=head1 DESCRIPTION

Using this class creates all the exceptions classes used by Alzabo
(via the L<C<Exception::Class>|Exception::Class> class).

See L<C<Exception::Class>|Exception::Class> for more information on
how this is done.

=head1 EXCEPTION CLASSES

=over 4

=item * Alzabo::Exception

This is the base class for all exceptions generated within Alzabo (all
exceptions should return true for C<< $@->isa('Alzabo::Exception') >>
except those that are generated via internal Perl errors).

=item * Alzabo::Exception::Driver

An error occured while accessing a database.  See
L<C<Alzabo::Driver>|Alzabo::Driver> for more details.

=item * Alzabo::Exception::Eval

An attempt to eval something returned an error.

=item * Alzabo::Exception::Logic

Alzabo was asked to do something logically impossible, like retrieve
rows for a table without a primary key.

=item * Alzabo::Exception::NoSuchRow

An attempt was made to fetch data from the database with a primary key
that does not actually exist in the specified table.

=item * Alzabo::Exception::NotNullable

An attempt was made to set a non-nullable column to C<NULL>.  The
"column_name", "table_name", and "schema_name" fields can be used to
identify the exact column.

=item * Alzabo::Exception::Panic

This exception is thrown when something completely unexpected happens
(think Monty Python).

=item * Alzabo::Exception::Params

This exception is thrown when there is a problem with the parameters
passed to a method or function.  These problems can include missing
parameters, invalid values, etc.

=item * Alzabo::Exception::RDBMSRules

A rule for the relevant RDBMS was violated (bad schema name, table
name, column attribute, etc.)

=item * Alzabo::Exception::ReferentialIntegrity

An insert/update/delete was attempted that would violate referential
integrity constraints.

=item * Alzabo::Exception::SQL

An error thrown when there is an attempt to generate invalid SQL via
the Alzabo::SQLMaker module.

=item * Alzabo::Exception::Storable

A error when trying to freeze, thaw, or clone an object using
Storable.

=item * Alzabo::Exception::System

Some sort of system call (file read/write, stat, etc.) failed.

=item * Alzabo::Exception::VirtualMethod

A virtual method was called.  This indicates that this method should
be subclassed.

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
