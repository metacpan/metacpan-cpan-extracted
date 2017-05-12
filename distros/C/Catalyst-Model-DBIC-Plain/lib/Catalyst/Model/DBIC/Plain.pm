package Catalyst::Model::DBIC::Plain;

use strict;
use base qw/Catalyst::Model DBIx::Class::Schema/;
use NEXT;

our $VERSION = '0.02';

=head1 NAME

Catalyst::Model::DBIC::Plain - DBIC Model Class

=head1 SYNOPSIS

    # lib/MyApp/Model/DBIC.pm
    package MyApp::Model::DBIC;
    use base 'Catalyst::Model::DBIC::Plain';

    my @conn_info = ( $dsn, $username, $password, \%dbi_attributes );

    __PACKAGE__->load_classes;
    __PACKAGE__->compose_connection(__PACKAGE__, @conn_info);

    1;

    # lib/MyApp/Model/DBIC/User.pm
    package MyApp::Model::DBIC::User;
    use base 'DBIx::Class::Core';

    __PACKAGE__->table('user');
    __PACKAGE__->add_columns(qw/id username password email clearance/);
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->add_relationship(
        clearance => 'MyApp::Model::DBIC::Clearance',
        { 'foreign.id => 'self.clearance' }
    );

    # lib/MyApp/Controller/MyController.pm
    $c->comp('DBIC')->class('user')->search(...);

    # or
    MyApp::Model::DBIC::User->search(...);

=head1 DESCRIPTION

This is the C<DBIx::Class> model class for Catalyst. Whilst it allows you to
use DBIC as your model in Catalyst, it does not make your tables classes
Catalyst-specific, so you can still use them in a non-Catalyst context.

=head2 new

Catalystifies DBIx::Class and makes the model model class a component.

=cut

sub new {
    my ( $self, $c ) = @_;
    $self = $self->NEXT::new($c);

    return $self;
}

=head1 SEE ALSO

L<Catalyst>, L<DBIx::Class> 

=head1 TODO

Write real tests.

=head1 AUTHOR

Danijel Milicevic, C<info@danijel.de>

=head1 THANK YOU

Dan Kubb, Matt S. Trout

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
