package DBIx::Class::ResultSet::I18NColumns;

use warnings;
use strict;
use base qw/ DBIx::Class::ResultSet /; 

=head1 NAME

DBIx::Class::ResultSet::I18NColumns - Internationalization for DBIx::Class ResultSet class

=head1 DESCRIPTION

See L<DBIx::Class::I18NColumns>

=head1 METHODS

=head2 language

Accessor for language.

=cut

__PACKAGE__->mk_group_accessors( 'simple' => qw/ language / );

=head1 OVERLOADED METHODS

=head2 new_result

Overloaded L<DBIx::Class::ResultSet/new_result> to let creation with language and i18n columns.

=cut

sub new_result {
    my $self = shift;

    my @args = $self->_extract_lang(@_);

    # extract i18n columns
    my $i18n_attr = {};
    if ( ref $args[0] eq 'HASH' ) {
        for my $attr ( keys %{$args[0]} ) {
            if ( $self->result_class->has_i18n_column($attr) ) {
                $i18n_attr->{$attr} = delete $args[0]->{$attr};
            }
        }
    }

    my $row = $self->next::method( @args );

    if ( $row && $self->language ) {
        $row->language( $self->language );
    }

    # store i18n extracted columns
    for my $attr ( keys %{$i18n_attr} ) {
        $row->set_column( $attr, $i18n_attr->{$attr} );
    }

    return $row;
}

=head2 create

Overloaded L<DBIx::Class::ResultSet/create> to let creation with language and i18n columns.

=cut

sub create {
    my $self = shift;

    my @args = $self->_extract_lang(@_);

    # extract i18n columns
    my $i18n_attr = {};
    if ( ref $args[0] eq 'HASH' ) {
        for my $attr ( keys %{$args[0]} ) {
            if ( $self->result_class->has_i18n_column($attr) ) {
                $i18n_attr->{$attr} = delete $args[0]->{$attr};
            }
        }
    }

    my $row = $self->next::method( @args );

    if ( $row && $self->language ) {
        $row->language( $self->language );
    }

    # store i18n extracted columns
    for my $attr ( keys %{$i18n_attr} ) {
        $row->set_column( $attr, $i18n_attr->{$attr} );
    }
    $row->update;

    return $row;
}

=head2 find

Overloaded L<DBIx::Class::ResultSet/find> to propagate language to returned L<row|DBIx::Class::Row>.

=cut

sub find {
    my $self = shift;

    my @args = $self->_extract_lang(@_);

    # extract i18n columns
    my $i18n_attr = {};
    if ( ref $args[0] eq 'HASH' ) {
        my %attr = %{$args[0]};
        for my $attr ( keys %attr ) {
            if ( $self->result_class->has_i18n_column($attr) ) {
                $i18n_attr->{$attr} = delete $attr{$attr};
            }
        }
        $args[0] = \%attr;
    }

    my $row = $self->next::method( @args );

    my $lang = $self->language;
    if ( $row && $self->language ) {
        $row->language( $self->language );
    }

    # do I have to filter by i18n columns?
    if ( $row && %$i18n_attr ) {
        my $lang = $self->language || $self->result_source->schema->_language_last_set;
        return undef unless ( $lang && $row->has_language($lang) );
        $row->language($lang);

        for my $attr ( keys %{$i18n_attr} ) {
            my $stored_value = $row->$attr || '';
            return undef 
                unless ( $stored_value eq $i18n_attr->{$attr} ); 
        }
    }
    return $row;
}

=head2 search

Overloaded L<DBIx::Class::ResultSet/search> to propagate language to returned L<resultset|DBIx::Class::ResultSet>.

=cut

sub search {
    my $self = shift;
    my $rs = $self->next::method( $self->_extract_lang(@_) );
    if ( $rs && $self->language ) {
        $rs->language( $self->language );
    }
    return $rs;
}

=head2 single

Overloaded L<DBIx::Class::ResultSet/single> to propagate language to returned L<row|DBIx::Class::Row>.

=cut

sub single {
    my $self = shift;
    my $row = $self->next::method( $self->_extract_lang(@_) );
    if ( $row && $self->language ) {
        $row->language( $self->language );
    }
    return $row;
}

=head2 next

Overloaded L<DBIx::Class::ResultSet/next> to propagate language to returned L<row|DBIx::Class::Row>.

=cut

sub next {
    my $self = shift;
    my $row = $self->next::method( @_ );
    if ( $row && $self->language ) {
        $row->language( $self->language );
    }
    return $row;
}

=head2 all

Overloaded L<DBIx::Class::ResultSet/all> to propagate language to L<rows|DBIx::Class::Row> returned on the array.

=cut

sub all {
    my $self = shift;
    my @rows = $self->next::method( @_ );
    if ( $self->language ) {
        $_->language( $self->language ) for @rows;
    }
    return @rows;
}

=head2 language_column
    
The name for the pseudo-column that holds the language descriptor.

=cut

sub language_column { 'language' }

sub _extract_lang {
    my $self = shift;
    my @args = @_;

    if ( ( ref $args[0] eq 'HASH' ) && ( my $lang = delete $args[0]->{ $self->language_column } ) ) {
        $self->language($lang);
        $self->result_source->schema->_language_last_set($lang);
    }

    return @args;
}

=head1 TODO

=over

=item *

Get language_column name from the ResultSource class.

=back

=head1 AUTHOR

Diego Kuperman, C<< <diego at freekeylabs.com > >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Diego Kuperman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of DBIx::Class::ResultSet::I18NColumns
