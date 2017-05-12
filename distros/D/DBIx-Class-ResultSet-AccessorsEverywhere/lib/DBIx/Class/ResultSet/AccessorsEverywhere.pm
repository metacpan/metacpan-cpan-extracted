package DBIx::Class::ResultSet::AccessorsEverywhere;

# ABSTRACT: Component for DBIx::Class that allows the use of accessor names in search/create/etc

use 5.010;
use strict;
use warnings;
use Carp;
no autovivification;

our $VERSION = '0.10';

use parent 'DBIx::Class::ResultSet';

# This is certainly buggy. It is just a proof of concept at the moment. I need
# to think through conflicting accessor/column names, other methods that need
# to be handled, etc.

sub search {
    my $self  = shift;
    my $where = shift;

    croak "search expects a hash ref or undef"
      unless !defined $where
      or ref $where eq 'HASH';

    my $new_where = $self->_convert_accessors_to_columns( $where // {} );
    return $self->next::method( $new_where, @_ );
}

sub new_result {
    my $self = shift;
    my $attr = shift;

    croak "new_result expects a hash ref or undef"
      unless !defined $attr
      or ref $attr eq 'HASH';

    my $new_attr = $self->_convert_accessors_to_columns( $attr // {} );
    return $self->next::method( $new_attr, @_ );
}

sub find {
    my $self = shift;
    my $attr = shift;

    $attr = $self->_convert_accessors_to_columns($attr) if ref $attr eq 'HASH';
    return $self->next::method( $attr, @_ );
}

sub _convert_accessors_to_columns {
    my ( $self, $orig ) = @_;
    my $map = $self->_get_accessor_map;

    my $new;
    my @keys = keys %$orig;
    for my $key (@keys) {
        my $new_key = $map->{$key} // $key;
        my $value = $orig->{$key};
        if ( ref $new->{$new_key} eq 'HASH' ) {
            $value = $self->_convert_accessors_to_columns($value);
        }
        $new->{$new_key} = $value;
    }
    return $new;
}

sub _get_accessor_map {
    my $self = shift;

    my $columns_info = $self->result_source->columns_info;
    my %col_mapping = map { $columns_info->{$_}->{accessor} => $_ }
      grep { defined $columns_info->{$_}->{accessor} }
      keys %$columns_info;

    return \%col_mapping;
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::ResultSet::AccessorsEverywhere - Component for DBIx::Class that allows the use of accessor names in search/create/etc

=head1 VERSION

version 0.10

=head1 STATUS

=for html <a href="https://travis-ci.org/mvgrimes/DBIC-ResultSet-AccessorsEverywhere"><img src="https://travis-ci.org/mvgrimes/DBIC-ResultSet-AccessorsEverywhere.svg?branch=master" alt="Build Status"></a>
<a href="https://metacpan.org/pod/DBIx::Class::ResultSet::AccessorsEverywhere"><img alt="CPAN version" src="https://badge.fury.io/pl/DBIC-ResultSet-AccessorsEverywhere.svg" /></a>

=head1 DESCRIPTION

    package Schema::ResultSet::User;
    use parent 'DBIx::Class::ResultSet';
    __PACKAGE__->load_components('AccessorsEverywhere');
    1;

    package Schema::Result::User;
    use parent qw/DBIx::Class::Core/;
    __PACKAGE__->table("users");
    __PACKAGE__->add_columns(
        id => {
            data_type         => "integer",
            is_auto_increment => 1,
            is_nullable       => 0,
        },
        'the_firstNameX' => {   # a really poorly named column in the db
            accessor    => 'first_name',     # a "perlish" accessor
            data_type   => "varchar",
            is_nullable => 1,
            size        => 255
        },
    );
    __PACKAGE__->set_primary_key("id");
    1;

    ## Your app:
    $schema->resultset('User')->create({ first_name => 'Bill' });
    $schema->resultset('User')->search({ first_name => 'Bill' });

By specifying the C<accessor> attribute when defining a table schema,
L<DBIx::Class> can change the name of accessors it creates for those columns.
This can be extremely helpful when the database fields are poorly named and
not under your control. Unfortunately, DBIx::Class expects the table column
names when creating new entries, searching, etc.

C<DBIx::Class::AccessorsEverywhere> is component that can be loaded into your
ResultSet classes that allows the use of the accessor names instead in
create, search, etc. operations.

This is an early release. Don't expect this to work everywhere. The following
DBIx::Class methods have been tested, others might work, but need to be tested.

    $rs->create({ accessor_name => 'value' });
    $rs->search({ accessor_name => 'value' });

=head1 SEE ALSO

L<DBIx::Class>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/DBIC-ResultSet-AccessorsEverywhere/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/DBIC-ResultSet-AccessorsEverywhere>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
