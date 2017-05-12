package DBIx::Class::CustomPrefetch;

use Sub::Name;
use warnings;
use strict;
use base qw(DBIx::Class);
use Module::Load;
use Sub::Name;
use DBIx::Class::ResultSet::CustomPrefetch;
my $rs_class = 'DBIx::Class::ResultSet::CustomPrefetch';

=head1 NAME

DBIx::Class::CustomPrefetch - Custom prefetches for DBIx::Class

=head1 DESCRIPTION

DBIx::Class onle allows joins for prefetches. But sometimes you can't use JOIN for prefetch. E.g. for prefetching
many related objects to resultset with paging.

Also you can use this module to create cross-database prefetches.

This module provides other logic for prefetching data to resultsets.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    package MyApp::Schema::Foo;

    __PACKAGE__->load_components( qw(Core CustomPrefetch) );
    __PACKAGE__->add_column( qw(id artist_id) );
    __PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::CustomPrefetch' );
    __PACKAGE__->custom_relation( artist => sub { MyOtherResultSetClass->new } => {
        'foreign.id' => 'self.artist_id'
    });

And your code:

    my $resultset = $schema->resultset('Foo')->search( undef, { rows => 10 } );
    foreach ($resultset->all) {
        say $_->artist->name;
    }

will make only two SQL requests:

    SELECT id, artist_id FROM foo LIMIT 10;
    SELECT * FROM artists WHERE id IN (1, 2, 3, 5, 8, 13, 21, 34, 55, 89);

=head1 METHODS

=head2 custom_relation

Makes IN relation. In can be has_one, might_have or many_to_many

Args: $relation_name, $resultset_callback, $condition

=cut

sub custom_relation {
    die 'Usage: __PACKAGE__->custom_relation( name, resultset, columns );' if scalar(@_) != 4;
    my ( $class, $name, @relation_args ) = @_;
    $class->result_source_instance->{_custom_relations} ||= {};
    $class->result_source_instance->{_custom_relations}->{$name} =
      [ $name, @relation_args ];
    my $resultset = $relation_args[0];
    my ( $foreign_column, $self_column ) = %{ $relation_args[1] };
    $foreign_column =~ s/foreign.//;
    $self_column    =~ s/self.//;
    no strict 'refs';
    *{"${class}::$name"} = subname $name => sub {
        my ($self,$arg)    = @_;
        my $name    = [ caller(0) ]->[3];
        my $package = __PACKAGE__;
        $name =~ s/^${package}:://;
        if (@_ > 1) {
            return $self->{"__cr_$name"} = $arg;
        }
        return $self->{"__cr_$name" } if exists $self->{"__cr_$name"};
        my $rs = $resultset->($self->result_source->schema);
        return unless $rs;
        $rs->find( { $foreign_column => $self->get_column($self_column) } );
    };
    return;
}

=head1 AUTHOR

Andrey Kostenko, C<< <andrey at kostenko.name> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-customprefetch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-CustomPrefetch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::CustomPrefetch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-CustomPrefetch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-CustomPrefetch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-CustomPrefetch>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-CustomPrefetch/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Andrey Kostenko, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of DBIx::Class::CustomPrefetch
