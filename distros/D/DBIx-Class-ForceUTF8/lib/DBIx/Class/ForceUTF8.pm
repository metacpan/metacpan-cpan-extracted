package DBIx::Class::ForceUTF8;
use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.0.2';

use base qw/DBIx::Class/;

BEGIN {

    # Perl 5.8.0 doesn't have utf8::is_utf8()
    # Yes, 5.8.0 support for Unicode is suboptimal, but things like RHEL3 ship with it.
    if ($] <= 5.008000) {
        require Encode;
    } else {
        require utf8;
    }
}

=head1 NAME

DBIx::Class::ForceUTF8 - Force UTF8 (Unicode) flag on columns

=head1 SYNOPSIS

    package Artist;
    __PACKAGE__->load_components(qw/ForceUTF8 Core/);
    
    # then belows return strings with utf8 flag
    $artist->name;
    $artist->get_column('description');

    # with DBIx::Class::Schema::Loader
    package My::Schema;
    use base qw/DBIx::Class::Schema::Loader/;

    __PACKAGE__->loader_options(
        components => [qw/ForceUTF8/],
    );


=head1 DESCRIPTION

DBIx::Class::ForceUTF8 allows you to get columns data that have Unicode flag without specifying a column name.
Best used with DBIx::Class::Schema::Loader.

=head1 SEE ALSO

L<DBIx::Class::Schema::Loader>, L<DBIx::Class::UTF8Columns>.

=head1 EXTENDED METHODS

=head2 get_column

=cut

sub get_column {
    my ( $self, $column ) = @_;
    my $value = $self->next::method($column);

    if ( defined $value and !ref $value ) {
        if ($] <= 5.008000) {
            Encode::_utf8_on($value) unless Encode::is_utf8($value);
        } else {
            utf8::decode($value) unless utf8::is_utf8($value);
        }
    }

    $value;
}

=head2 get_columns

=cut

sub get_columns {
    my $self = shift;
    my %data = $self->next::method(@_);

    foreach my $col ( grep { !ref $data{$_} } keys %data ) {

        if ($] <= 5.008000) {
            Encode::_utf8_on($data{$col}) unless Encode::is_utf8($data{$col});
        } else {
            utf8::decode($data{$col}) unless utf8::is_utf8($data{$col});
        }
    }

    %data;
}

=head2 store_column

=cut

sub store_column {
    my ( $self, $column, $value ) = @_;

    if ( defined $value and !ref $value ) {

        if ($] <= 5.008000) {
            Encode::_utf8_off($value) if Encode::is_utf8($value);
        } else {
            utf8::encode($value) if utf8::is_utf8($value);
        }
    }

    $self->next::method( $column, $value );
}

=head1 AUTHOR

Takahiro Horikawa <horikawa.takahiro@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

