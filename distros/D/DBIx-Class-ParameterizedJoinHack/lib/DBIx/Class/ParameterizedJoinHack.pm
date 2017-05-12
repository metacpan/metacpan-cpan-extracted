package DBIx::Class::ParameterizedJoinHack;

use strict;
use warnings;
use base qw(DBIx::Class);

our $VERSION = '0.002001'; # 0.2.1
$VERSION = eval $VERSION;

our $STORE = '_parameterized_join_hack_meta_info';

__PACKAGE__->mk_group_accessors(inherited => $STORE);

sub parameterized_has_many {
  my ($class, $rel, $f_source, $cond, $attrs) = @_;

  die "Missing relation name for parameterized_has_many"
    unless defined $rel;
  die "Missing foreign source"
    unless defined $f_source;

  {
    my $cond_ref = ref($cond);
    $cond_ref = 'non-reference value'
      unless $cond_ref;
    die "Condition needs to be [ \\\@args, \&code ], not ${cond_ref}"
      unless $cond_ref eq 'ARRAY';
  }
  my ($args, $code) = @$cond;

  {
    my $arg_ref = ref($cond->[0]);
    $arg_ref = 'non-reference value'
      unless $arg_ref;
    die "Arguments must be declared as array ref of names, not ${arg_ref}"
      unless $arg_ref eq 'ARRAY';
    my $code_ref = ref($cond->[1]);
    $code_ref = 'non-reference value'
      unless $code_ref;
    die "Condition builder must be declared as code ref, not ${code_ref}"
      unless $code_ref eq 'CODE';
  }

  my $store = $class->$STORE({
    %{$class->$STORE||{}},
    $rel => { params => {}, args => $args },
  })->{$rel};

  my $wrapped_code = sub {
    my $params = $store->{params};
    my @missing = grep !exists $params->{$_}, @$args;
    die "Attempted to use parameterized rel ${rel} for ${class} without"
        ." passing parameters ".join(', ', @missing) if @missing;
    local *_ = $params;
    &$code;
  };

  $class->has_many($rel, $f_source, $wrapped_code, $attrs);
  return; # no, you are not going to accidentally rely on a return value
}

1;

=head1 NAME

DBIx::Class::ParameterizedJoinHack - Parameterized Relationship Joins

=head1 SYNOPSIS

    #
    #   The Result class we want to allow to join with a dynamic
    #   condition.
    #
    package MySchema::Result::Person;
    use base qw(DBIx::Class::Core);

    __PACKAGE__->load_components(qw(ParameterizedJoinHack));
    __PACKAGE__->table('person');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_nullable => 0,
            is_auto_increment => 1,
        },
        name => {
            data_type => 'text',
            is_nullable => 0,
        }
    );

    ...

    __PACKAGE__->parameterized_has_many(
        priority_tasks => 'MySchema::Result::Task',
        [['min_priority'] => sub {
            my $args = shift;
            return +{
                "$args->{foreign_alias}.owner_id" => {
                    -ident => "$args->{self_alias}.id",
                },
                "$args->{foreign_alias}.priority" => {
                    '>=' => $_{min_priority},
                },
            };
        }],
    );

    1;

    #
    #   The ResultSet class belonging to your Result
    #
    package MySchema::ResultSet::Person;
    use base qw(DBIx::Class::ResultSet);

    __PACKAGE__->load_components(qw(ResultSet::ParameterizedJoinHack));

    1;

    #
    #   A Result class to join against.
    #
    package MySchema::Result::Task;
    use base qw(DBIx::Class::Core);
    
    __PACKAGE__->table('task');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_nullable => 0,
            is_auto_increment => 1,
        },
        owner_id => {
            data_type => 'integer',
            is_nullable => 0,
        },
        priority => {
            data_type => 'integer',
            is_nullable => 0,
        },
    );

    ...

    1;

    #
    #   Using the parameterized join.
    #
    my @urgent = MySchema
        ->connect(...)
        ->resultset('Person')
        ->with_parameterized_join(
            priority_tasks => {
                min_priority => 300,
            },
        )
        ->all;

=head1 WARNING

This module uses L<DBIx::Class> internals and may break at any time.

=head1 DESCRIPTION

This L<DBIx::Class> component allows to declare dynamically parameterized
has-many relationships.

Add the component to your Result class as usual:

    __PACKAGE__->load_components(qw( ParameterizedJoinHack ));

See L</parameterized_has_many> for details on declaring relations.

See L<DBIx::Class::ResultSet::ParameterizedJoinHack> for ResultSet usage.

B<Note:> Currently only L</parameterized_has_many> is implemented, since
it is the most requested use-case. However, adding support for other
relationship types is possible if a use-case is found.

=head1 METHODS

=head2 parameterized_has_many

    __PACKAGE__->parameterized_has_many(
        $relation_name,
        $foreign_source,
        [\@join_arg_names, \&join_builder],
        $attrs,
    );

The C<$relation_name>, C<$foreign_source>, and C<$attrs> are passed
through to C<has_many> as usual. The third argument is an array reference
containing an (array reference) list of argument names and a code
reference used to build the join conditions.

The code reference will be called with the same arguments as if it had
been passed to C<has_many> directly, but the global C<%_> hash will
contain the named arguments for the join.

See the L</SYNOPSIS> for an example of a definition.

=head1 SPONSORS

Development of this module was sponsored by

=over

=item * Ctrl O L<http://ctrlo.com>

=back

=head1 AUTHOR

 Matt S. Trout <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

 Robert Sedlacek <r.sedlacek@shadowcat.co.uk>

=head1 COPYRIGHT

Copyright (c) 2015 the DBIx::Class::ParameterizedJoinHack L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
