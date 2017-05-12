package DBIx::Class::RandomStringColumns;
use strict;
use warnings;

our $VERSION = '0.10';

use base qw/DBIx::Class/;

use String::Random;

our $LENGTH = 32;
our $SALT   = '[A-Za-z0-9]';

__PACKAGE__->mk_classdata( 'rs_definition' );

sub random_string_columns {
    my $self = shift;

    my $opt = pop @_;
    if ( ref $opt ne 'HASH' ) {
        push @_, $opt;
        $opt = {};
    }

    my $length = $opt->{length} || $LENGTH;
    my $salt   = $opt->{salt}   || $SALT;

    my $rs_definition = $self->rs_definition || {};
    for my $column (@_) {
        $self->throw_exception("column $column doesn't exist")
          unless $self->has_column($column);
        $rs_definition->{$column}->{length} = $length;
        $rs_definition->{$column}->{salt}   = $salt;
    }

    $self->rs_definition( $rs_definition );
}

sub insert {
    my $self = shift;
    for my $column ( keys( %{ $self->rs_definition || {} } ) ) {
        $self->store_column( $column, $self->get_random_string($column) )
          if $self->has_column($column) && !$self->get_column($column);
    }
    $self->next::method(@_);
}

sub get_random_string {
    my $self   = shift;
    my $column = shift;

    my $rs =
      $self->result_source->schema->resultset(
        $self->result_source->source_name );
    my $val;
    do {    # must be unique
        $val = String::Random->new->randregex(
            sprintf( '%s{%d}',
                $self->rs_definition->{$column}->{salt},
                $self->rs_definition->{$column}->{length},
            )
        );
    } while ( $rs->search( { "me.$column" => $val } )->count );

    return $val;
}

1;

__END__

=head1 NAME

DBIx::Class::RandomStringColumns - Implicit random string columns

=head1 SYNOPSIS

  pacakge CD;
  __PACKAGE__->load_components(qw/RandomStringColumns Core DB/);
  __PACKAGE__->random_string_columns('uid');

  pacakge Artist;
  __PACKAGE__->load_components(qw/RandomStringColumns Core DB/);
  __PACKAGE__->random_string_columns(['rid', {length => 10}]);

  package LoginUser
  __PACKAGE__->load_components(qw/RandomStringColumns Core DB/);
  __PACKAGE__->random_string_columns(
    ['rid', {length => 10}],
    ['login_id', {length => 15, solt => '[0-9]'}],
  );

=head1 DESCRIPTION

This L<DBIx::Class> component reassemble the behavior of
L<Class::DBI::Plugin::RandomStringColumn>, to make some columns implicitly created as random string.

Note that the component needs to be loaded before Core.

=head1 METHODS

=head2 insert

=head2 random_string_columns

  $pkg->random_string_columns('uid'); # uid column set random string.
  $pkg->random_string_columns(['rid', {length=>10}]); # set string length.
  # set multi column rule
  $pkg->random_string_columns(
    'uid',
    ['rid', {length => 10}],
    ['login_id', {length => 15, solt => '[0-9]'}],
  );

  this method need column name, and random string generate option.
  option is "length", and "solt".

=head2 get_random_string

=head1 AUTHOR

Kan Fushihara  C<< <kan __at__ mobilefactory.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Kan Fushihara C<< <kan __at__ mobilefactory.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

