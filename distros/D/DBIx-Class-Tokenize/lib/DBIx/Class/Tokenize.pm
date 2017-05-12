package DBIx::Class::Tokenize;

use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata( '__columns_to_tokenize' => {} );

our $VERSION = '0.01';

=head1 NAME

DBIx::Class::Tokenize - Automatically tokenize a column on creation

=head1 DESCRIPTION

This component simply creates a clean token based on a field on insertion.  The
simple use case is having a long name that is displayable, like "Catalyst Book"
that you want to change to "catalyst_book".   Rather than do that by hand
every time you create a record, this component does it for you.

=head1 SYNOPSIS

 package MyApp::Schema::Book;

 __PACKAGE__->load_components( qw(Tokenize ... Core) );
 __PACKAGE__->add_columns(
     id   => { data_type => 'integer', is_auto_increment => 1 },
     name => { data_type => 'varchar', size => 128, 
        # Update the 'token' field on create
        token_field => 'token' },
     token => { data_type => 'varchar', size => 128, is_nullable => 0 }
 );

 ...

 my $row = $schema->resultset('Book')->create({ name => "Catalyst Book" });
 
 print $row->token; # Prints "catalyst_book

=cut

sub register_column {
    my ( $self, $column, $info, @rest ) = @_;
    
    $self->next::method($column, $info, @rest);
    return unless $info->{token_field};
    return unless defined($info->{data_type});
    return unless $info->{data_type} =~ /^(var)?char$/i;

    my $token = $info->{token_field} || 'token';

    $self->__columns_to_tokenize->{$column} = $token;
}

sub insert {
    my ( $self, $attrs ) = ( shift, shift );

    foreach my $key ( keys %{ $self->__columns_to_tokenize } ) {
        my $dest  = $self->__columns_to_tokenize->{$key};
        # Don't overwrite if there is something already there
        next if defined $self->get_column($dest);
        $self->$dest( $self->tokenize( $key ) );
    }
    $self->next::method(@_);
}

=head1 METHODS

=head2 tokenize

This method is what performs the actual conversion to the tokenized form.  It is
easy to override so that you can change things around to suit your particular
table.  Whatever is returned is inserted into the configured C<token_field>.

An example of extending this method would be to traverse a tree in a row
that uses L<DBIx::Class::Tree::AdjacencyList> and tokenize the parents as well.

=cut

sub tokenize {
    my ( $self, $key ) = @_;
    
    my $field = $self->get_column($key);

    # Should we throw an exception, or just return undef?
    return undef unless $field;

    $field = lc($field);
    $field =~ s/\s+/_/g;
    $field =~ s/[^\w]/_/g;
    return $field;
}

=head1 AUTHOR

J. Shirley, C<< <jshirley at coldhardcode.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-controller-rest-dbi
c-item at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Tokenize>.  I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Tokenize

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Tokenize>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Tokenize>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Tokenize>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Tokenize>

=back


=head1 ACKNOWLEDGEMENTS

This is a Cold Hard Code, LLC module - http://www.coldhardcode.com

=head1 COPYRIGHT & LICENSE

Copyright 2008 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
