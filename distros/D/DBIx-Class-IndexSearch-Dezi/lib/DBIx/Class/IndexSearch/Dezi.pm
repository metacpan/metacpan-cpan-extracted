package DBIx::Class::IndexSearch::Dezi;
use Moo;
extends 'DBIx::Class';

use Carp;
use Module::Load;

__PACKAGE__->mk_classdata( map_to                => undef );
__PACKAGE__->mk_classdata( query_parameters      => {} );
__PACKAGE__->mk_classdata( webservice_classname  => undef );
__PACKAGE__->mk_classdata( _index_fields         => {} );
__PACKAGE__->mk_classdata( _webservice           => undef );

=head1 NAME

DBIx::Class::IndexSearch::Dezi

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    package MyApp::Schema::Person; 
    use base 'DBIx::Class';
    
    __PACKAGE__->load_components(qw[
        IndexSearch::Dezi
        Core
    ]);
    
    __PACKAGE__->table('person');
    
    __PACKAGE__->add_columns(
        person_id => {
            data_type       => 'varchar',
            size            => '36',
        },
        name => {
            data_type => 'varchar',
            indexed => 1 
        },
        email => {
            data_type => 'varchar',
            size=>'128',
            indexed => 1
        },
    );
    
    __PACKAGE__->resultset_class('DBIx::Class::IndexSearch::ResultSet::Dezi');
    __PACKAGE__->belongs_to_index('FooClient', { server => 'http://localhost:6000', map_to => 'person_id' });

=head1 SUBROUTINES/METHODS

=head2 belongs_to_index ( $class, $webservice_class, \%parameters )

This sets up the the webservice to use and maps the webservice index
to the DB.

=cut
sub belongs_to_index {
    my ( $class, $webservice_classname, $parameters ) = @_;

    croak 'Please specify a webservice' if !$webservice_classname;
    croak 'Please supply hostname ' if !$parameters->{server};
    croak 'Please supply map_to ' if !$parameters->{map_to};

    $class->webservice_classname( $webservice_classname );
    $class->query_parameters( $parameters || {} );
    $class->map_to( $parameters->{map_to} || '' );
}

=head2 index_key_exists ( $class, $key )

Find if the key exists as a registered index field.

=cut
sub index_key_exists {
    my( $class, $key ) = @_;
    return exists $class->_index_fields->{ $key };
}

=head2 register_column ( $class, $webservice_class, \%parameters )

Override to the register_column method. Add any "indexed" fields we
want to search against Dezi.

=cut
sub register_column {
    my ( $class, $column, $info ) = @_;

    $class->next::method( $column, $info );

    if (exists $info->{ indexed }) {
        $class->set_index_field( $column => $info->{ indexed } );
    }
    
}

=head2 set_index_field ( $class, $key, $value )

Setter wrapper to register an indexed field.

=cut
sub set_index_field {
    my( $class, $key, $value ) = @_;
    $class->_index_fields->{ $key } = $value;
}

=head2 webservice ( $class )

Returns a webservice object.

=cut
sub webservice {
    my ( $class ) = @_;

    if ( !$class->_webservice && $class->webservice_classname ) {
        my $webservice_classname = $class->webservice_classname;

        load $webservice_classname;

        my $webservice_obj = $webservice_classname->new(server => $class->query_parameters->{server});
        $class->_webservice($webservice_obj);
    }

    return $class->_webservice;
}

=head1 AUTHOR

Logan Bell, C<< <loganbell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-indexsearch-dezi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-IndexSearch-Dezi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::IndexSearch::Dezi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-IndexSearch-Dezi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-IndexSearch-Dezi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-IndexSearch-Dezi>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-IndexSearch-Dezi/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Logan Bell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DBIx::Class::IndexSearch::Dezi
