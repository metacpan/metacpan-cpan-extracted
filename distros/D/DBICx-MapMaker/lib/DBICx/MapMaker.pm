package DBICx::MapMaker;
BEGIN {
  $DBICx::MapMaker::VERSION = '0.03';
}
# ABSTRACT: automatically create a DBIx::Class mapping table
use Moose;

our $VERSION;
our $AUTHORITY = 'CPAN:JROCKWAY';

# avoid clogging up our methods
my $other = sub { return 'right' if shift eq 'left'; return 'left' };

for my $direction (qw/left right/){
    my $other = $other->($direction);
    my $oname = "${other}_name";

    has "${direction}_class" => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has "${direction}_name" => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

    has "${direction}_to_map_relation" => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->$oname . '_map';
        }
    );

    has "${other}s_from_${direction}" => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;
            return $self->$oname . 's';
        },
    );

    # TODO support extra columns

    # XXX: hack
    has "suppress_${direction}_m2m" => (
        is      => 'ro',
        isa     => 'Bool',
        default => sub { undef },
    );
}

has tablename => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($l,$r) = ($self->left_name, $self->right_name);
        return "map_${l}_${r}";
    },
);

# load up the classes
sub BUILD {
    my $self = shift;
    for my $class (map { $self->$_ } qw/left_class right_class/){
        Class::MOP::load_class($class);
    }
}

sub setup_table {
    my ($self, $class) = @_;
    $class->load_components(qw/Core/);
    $class->table($self->tablename);

    my ($left_class, $right_class) = ($self->left_class, $self->right_class);
    my ($left_name, $right_name) = ($self->left_name, $self->right_name);

    my $l_info = $left_class->column_info($left_class->primary_columns);
    my $r_info = $right_class->column_info($right_class->primary_columns);

    # NOTE:
    # we never want auto-incrementing
    # in a mapping table, so explicitly disable it
    $class->add_columns(
        $left_name  => { %$l_info, is_auto_increment => 0, is_nullable => 0, },
        $right_name => { %$r_info, is_auto_increment => 0, is_nullable => 0, },
    );
    $class->set_primary_key($left_name, $right_name);

    # us -> them
    $class->belongs_to( $left_name  => $left_class  );
    $class->belongs_to( $right_name => $right_class );

    # them -> us
    my $lmap = $self->left_to_map_relation;
    my $rmap = $self->right_to_map_relation;
    $left_class->has_many(  $lmap => $class, $left_name  );
    $right_class->has_many( $rmap => $class, $right_name );

    # many2many
    my $rights_from_left = $self->rights_from_left;
    my $lefts_from_right = $self->lefts_from_right;

    $left_class->many_to_many( $rights_from_left  => $lmap => $right_name )
      unless $self->suppress_left_m2m;

    $right_class->many_to_many( $lefts_from_right => $rmap => $left_name  )
      unless $self->suppress_right_m2m;
}

1;



=pod

=head1 NAME

DBICx::MapMaker - automatically create a DBIx::Class mapping table

=head1 VERSION

version 0.03

=head1 SYNOPSIS

A common SQL pattern is the "many to many" relationship; a row in the
"left table" may point to many rows in the "right table", and a row in
the "right table" may point to many rows in the "left table".  This
module automatically creates a L<DBIx::Class|DBIx::Class> result
source for that table, and sets up the six necessary relationships.

Here's how to use it.  Imagine you have some tables called
C<MySchema::A> and C<MySchema::B>, each with a primary key, that you'd
like to join.  To create the mapping table, you'll write a module like
this:

  package MySchema::MapAB;
  use DBICx::MapMaker;
  use base 'DBIx::Class';

  my $map = DBICx::MapMaker->new(
      left_class  => 'MySchema::A',
      right_class => 'MySchema::B',
      left_name   => 'a',
      right_name  => 'b',
  );

  $map->setup_table(__PACKAGE__);

Then, you can:

  my $a = $schema->resultset('A')->find(1);
  $a->b_map; # the mapping table
  $a->bs;    # a list of bs that this a has

  my $b = $schema->resultset('B')->find(42);
  $b->a_map; # the mapping table
  $b->as;    # a list of as that this b has

=head1 METHODS

=head2 new

Create a C<MapMaker>.  See L</ATTRIBUTES> below for a description of
the attributes you can pass to the constructor.

=head2 setup_table($class)

Makes C<$class> into the mapping table.  C<$class> should be a
subclass of C<DBIx::Class>.

=head1 ATTRIBUTES

Here are the attributes that you can pass to the constructor:

=head2 left_class right_class

The class name of the left/right table (the tables that have a m2m
relationship between them).

Required.

=head2 left_name right_name

The column name for the left/right table's primary key in the map
table.

Required.

=head2 left_to_map_relation right_to_map_relation

The name of the relationship from the left/right table to the map
table.

Optional.  Defaults to the name of the opposite table's name with
C<_map> appended.  (If C<right_name> is C<foo>, then
C<left_to_map_relation> will be C<foo_map>.)

=head2 rights_from_left lefts_from_right

The name of the m2m relationship.  C<rights_from_left> is the method
you'll call on a C<left> row to get the corresponding C<right>s.
(C<lefts_from_right> is the opposite.)

Optional.  Defaults to the name of the row returned with "s" appended.
If C<left_name> is "foo", then C<lefts_from_right> will be "foos" by
default.

=head2 tablename

The name of the created mapping table.

Optional.  Defaults to "map_C<left_name>_C<right_name>".  (With C<foo>
and C<bar>, C<map_foo_bar>.)

=head1 AUTHORS

Jonathan Rockway C<< <jrockway@cpan.org> >>

Stevan Little C<< <stevan.little@iinteractive.com> >>

Adam Herzog C<< <adam@adamherzog.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

