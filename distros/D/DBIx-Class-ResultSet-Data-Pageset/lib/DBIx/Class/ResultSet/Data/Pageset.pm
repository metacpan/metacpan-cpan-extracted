package DBIx::Class::ResultSet::Data::Pageset;

use strict;
use warnings;

use base qw( DBIx::Class::ResultSet );

use Data::Pageset ();

our $VERSION = '0.06';

=head1 NAME

DBIx::Class::ResultSet::Data::Pageset - Get a Data::Pageset pager from a resultset

=head1 SYNOPSIS

    # in your resultsource class
    __PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::Data::Pageset' );
    
    # in your calling code
    my $rs = $schema->resultset('Foo')->search( { }, { pages_per_set => 5 } );
    my $pager = $rs->pageset;
    
    # sliding pager
    my $rs2 = $schema->resultset('Foo')->search( { }, { pageset_mode => 'slide' } );

=head1 DESCRIPTION

This is a simple way to allow you to get a L<Data::Pageset> object for paging
rather than the standard L<Data::Page> object.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=head1 METHODS

=head2 pageset( )

Returns a L<Data::Pageset> object for paging. This will grab the C<pages_per_set>
option (default: C<10>) and the C<pageset_mode> option (default: C<fixed>) from the
resultset attributes.

=cut

sub pageset {
    my( $self ) = @_;
    my $pager = $self->pager;
    my $attrs = $self->{attrs};

    return Data::Pageset->new( {
        ( map { $_ => $pager->$_ } qw(
            entries_per_page
            total_entries
            current_page
        ), ),
        pages_per_set => $attrs->{ pages_per_set } || 10,
        mode          => $attrs->{ pageset_mode }  || 'fixed',
    } );
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<DBIx::Class>

=item * L<Data::Pageset>

=back

=cut

1;
