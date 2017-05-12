package Catalyst::Model::DBIDM;

use strict;
use warnings;

use base qw/ Catalyst::Model /;
use NEXT;
use DBI;
use Carp;

=head1 NAME

Catalyst::Model::DBIDM - DBIx::DataModel model class

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

=over

=item 1

Create the DBIx::DataModel schema in MyApp/Schema.pm:

    package MyApp::Schema;
    use DBIx::DataModel;

    DBIx::DataModel->Schema('MyApp::DM');

    MyApp::DM->Table(qw/ MyApp::DM::Employee   employee   emp_id /);
    MyApp::DM->Table(qw/ MyApp::DM::Department department dpt_id /);
    ...

Notice that the DBIx::DataModel schema is MyApp::DM, not MyApp::Model::DM. It is usable
as a standalone schema, without the need for Catalyst. In fact, it does not
even need to be in the MyApp namespace.

=item 2

To expose it to Catalyst as a model, create a DM model in MyApp/Model/DM.pm:

    package MyApp::Model::DM;
    use base qw/ Catalyst::Model::DBIDM /;

    use MyApp::Schema; # to create the classes MyApp::DM

    __PACKAGE__->config(
        schema_class => 'MyApp::DM',
        connect_info => [
            'dbi:...',
            'username',
            'password',
            { RaiseError => 1 },
        ],
    );

=back

Now you have a working model, bound to your DBIx::DataModel schema, that can be
accessed the Catalyst way, using $c->model().

    my $employee = $c->model('DM::Employee')->fetch(1);

C<< $c->model('DM') >> merely returns the string "MyApp::DM", i.e., the name of
the DBIx::DataModel schema, but it also ensures that it is connected to the
database, as configured in the C<connect_info> configuration entry.

C<< $c->model('DM::Employee') >> (or any other table declared in MyApp::Schema)
does the same (returns the string "MyApp::DM::Employee", and connects to the
database if need be).

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item new

Constructor. It creates an C<ACCEPT_CONTEXT> method for the C<MyApp::Model::DM> class and
for pseudo-classes for each of the schema's tables (C<MyApp::Model::DM::Employee>,
C<MyApp::Model::DM::Department>, etc.)

This allows the Catalyst application to invoke C<< $c->model('DM::Employee') >>
prior to calling C<< $c->model('DM') >> and still have the schema initialised properly.

The C<ACCEPT_CONTEXT> methods invoke the connect_if_not() method before
returning the Schema class name or the Table class name:

    $c->model('DM');            # "MyApp::DM"
    $c->model('DM::Employee');  # "MyApp::DM::Employee"

The pseudo-classes name are elaborated as follows:

=over 5

=item 1

Take the class name as returned by the Schema's tables() method
(C<MyApp::DM::Employee>).

=item 2

Remove the Schema class name (C<MyApp::DM::>), if possible, which leaves C<Employee>.

=item 3

Prepend with the Model class name (C<MyApp::Model::DM::>), resulting in
C<MyApp::Model::DM::Employee>, which can be called with
C<< $c->model('DM::Employee') >>.

=back

The Table class names need not be in the same namespace as the Schema class: if
the substitution at step 2 fails, the Model class name is prepended to the full
Table class name.

    # In MyApp::Schema
    DBIx::DataModel->Schema('MyApp::DM');
    MyApp::DM->Table(qw/ Employee employee emp_id /);

    # In MyApp::Model::DM
    use base qw/ Catalyst::Model::DBIDM /;
    __PACKAGE__->config(
        schema_class => 'MyApp::DM',
        ...
    );

    # In some controller code
    $c->model('DM::Employee')->fetch(1);   # Employee->fetch(1);

=cut

sub new {
    my $self  = shift->NEXT::new(@_);
    my $class = ref($self);

    (my $model_name = $class) =~ s/^[\w:]+::(?:Model|M):://;

    my $schema_class = $self->{schema_class}
        or croak "->config->{schema_class} must be defined for this model";

    no strict 'refs';
    *{"${class}::ACCEPT_CONTEXT"} = sub {
        my ($this, $c) = @_;
        $self->connect_if_not($c, $schema_class);
        return $schema_class;
    };

    foreach my $table_class ( $schema_class->tables ) {
        (my $table_model_name = $table_class) =~ s/^${schema_class}:://;
        *{"${class}::${table_model_name}::ACCEPT_CONTEXT"} = sub {
            my ($this, $c) = @_;
            $self->connect_if_not($c, $schema_class);
            return $table_class;
        };
    }
    return $self;
}

=item connect_if_not

Initialises the Schema (i.e., connects to the database), if not already done.
This method returns immediately if the Schema class already has a dbh() (See
L<DBIx::DataModel>). If not, it creates a database handler by invoking
C<< DBI->connect >> with the C<connect_info> parameters from the configuration.

This method receives C<$c> and the Schema class name as arguments.

=cut

sub connect_if_not {
    my ($self, $c, $schema_class) = @_;
    return if $schema_class->dbh;
    if ( $self->{connect_info} ) {
        $schema_class->dbh( DBI->connect( @{$self->{connect_info}} ) );
    }
}

=back

=head1 SEE ALSO

L<Catalyst::Manual>,
L<Catalyst::Helper::Model::DBIDM>

=head1 AUTHOR

Cedric Bouvier, C<< <cbouvi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-model-dbidm at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-DBIDM>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::DBIDM

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-DBIDM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-DBIDM>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-DBIDM>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-DBIDM>

=back

=head1 ACKNOWLEDGEMENTS

Praises go to Laurent Dami for writing DBIx::DataModel, and to Brandon L Black,
for writing Catalyst::Model::DBIC::Schema, a great source of inspiration.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Cedric Bouvier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Model::DBIDM
