=head1 NAME

DBIx::SQLEngine::Driver::Trait::DatabaseFlavors - For minor variations in a database

=head1 SYNOPSIS

  # Classes can import this behavior if they have further subclasses
  use DBIx::SQLEngine::Driver::Trait::DatabaseFlavors ':all';
  


=head1 DESCRIPTION

This package supports configurations of drivers or database servers which differ from the generic implementation provided by their driver. 

=head2 Variations Within a Driver Class 

Beyond the fundamental subclassing based on driver type lies a more subtle range of variations. 

How do we compensate for different versions of a database system? For example, newer versions of MySQL support a number of features that the old ones don't: transactions were added in 3.23 (for some table types); union selects were added in 4.0; and stored procedures are being added in 5.0. Similarly DBD::SQLite's functionality is limited by the version of the SQLite C library is in use, and DBD::AnyData's level of functionality depends on which version of SQL::Statement is installed. 

Similarly, how do we detect driver/server combinations that need extra help? For example, placeholders will fail for Linux users of DBD::Sybase connecting to MS SQL Servers on Windows, so they need a special subclass which uses the NoPlaceholders trait.

This is handled by the "dbms_flavor" interface. When a flavor is selected, detected, or defaulted, the driver in question is reblessed into an appropriate subclass, such as Driver::MySQL::3_23, Driver::MySQL::5_0, or Driver::Sybase::MSSQL.

=head2 About Driver Traits

You do not need to use this package directly; it is used internally by those driver subclasses which need it. 

For more information about Driver Traits, see L<DBIx::SQLEngine::Driver/"About Driver Traits">.

=cut

########################################################################

package DBIx::SQLEngine::Driver::Trait::DatabaseFlavors;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT_OK = qw( 
  _init 
  default_dbms_flavor detect_dbms_flavor 
  select_dbms_flavor select_default_dbms_flavor select_detect_dbms_flavor
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict;
use Carp;

########################################################################

########################################################################

=head1 INTERNAL CONNECTION METHODS (DBI DBH)

=head2 Initialization and Reconnection

=over 4

=item _init()

  $sqldb->_init () 

Calls select_default_dbms_flavor().

Internal method, called by DBIx::AnyDBD after connection is made and class hierarchy has been juggled.

=back

=cut

sub _init {
  (shift)->select_default_dbms_flavor()
}

########################################################################

=head1 DRIVER AND DATABASE FLAVORS

=head2 Detecting DBMS Flavors

=over 4

=item default_dbms_flavor()

  $sqldb->default_dbms_flavor() : $flavor_name

Subclass hook. Default returns empty string, to not select any flavor.

=item detect_dbms_flavor()

  $sqldb->detect_dbms_flavor() : $flavor_name

Subclass hook. Default returns empty string, to not select any flavor.

=back

=cut

sub default_dbms_flavor { '' }

sub detect_dbms_flavor  { '' }

########################################################################

=head2 Applying DBMS Flavors

=over 4

=item select_dbms_flavor()

  $sqldb->select_dbms_flavor( $flavor_name )

Reblesses the driver to a subclass based on the flavor name.

=item select_default_dbms_flavor()

  $sqldb->select_default_dbms_flavor( )

Calls select_dbms_flavor() with the result of default_dbms_flavor().

=item select_detect_dbms_flavor()

  $sqldb->select_detect_dbms_flavor( )

Calls select_dbms_flavor() with the result of detect_dbms_flavor() or default_dbms_flavor().

=back

=cut

sub select_dbms_flavor {
  my ($self, $flavor) = @_;
  my $class = ref( $self ) or croak("This is not a class method");
  # warn "Reblessing object of class '$class'\n";
  $class =~ s/(Driver::\w+)::.*$/$1/;
  my $flavor_class = $class . ( $flavor ? "::$flavor" : '' );
  # warn "          ... new class is '$flavor_class'\n";
  bless $self, $flavor_class;
}

sub select_default_dbms_flavor {
  my $self = shift;
  $self->select_dbms_flavor( $self->default_dbms_flavor() );
}

sub select_detect_dbms_flavor {
  my $self = shift;
  $self->select_dbms_flavor( $self->detect_dbms_flavor() or
			    $self->default_dbms_flavor() )
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
