package DBIx::Class::ResultSet::ParameterizedJoinHack;

use strict;
use warnings;
use DBIx::Class::ParameterizedJoinHack;
use base qw(DBIx::Class::ResultSet);

sub _parameterized_join_store {
  $_[0]->result_source->result_class
       ->$DBIx::Class::ParameterizedJoinHack::STORE
}

sub with_parameterized_join {
  my ($self, $rel, $params) = @_;
  die "Missing relation name in with_parameterized_join"
    unless defined $rel;

  {
    my $params_ref = ref($params);
    $params_ref = 'non-reference-value'
      unless $params_ref;
    die "Parameters value must be a hash ref, not ${params_ref}"
      unless $params_ref eq 'HASH';
  }

  die "Parameterized join can only be used once per relation"
    if exists(($self->{attrs}{join_parameters} || {})->{$rel});

  $self->search_rs(
    {},
    { join => $rel,
      join_parameters => {
        %{$self->{attrs}{join_parameters}||{}},
        $rel => $params
      }
    },
  );
}

sub call_with_parameters {
  my ($self, $method, @args) = @_;
  my $params = $self->{attrs}{join_parameters}||{};
  my @param_names = keys %$params;
  my $store = $self->_parameterized_join_store;
  # This loop is implemented using "goto"; this means the "local" doesn't have
  # to be in a separate scope, which would defeat the point. Nor does "local
  # ... foreach ..." work; the localization doesn't survive the loop. The
  # alternative would be to use recursive subroutine calls, but that would
  # require not only the N save-stack entries for the localized parameters, but
  # N call frames too, so this approach saves both time and memory. It also
  # avoids any risk of a "deep recursion" warning if you have a lot of
  # parameters; and it avoids cluttering stack traces if the called method
  # throws an exception. The downside is obviously that it uses "goto" for an
  # otherwise-simple loop, but at least it's confined to this method. Further,
  # the result is more than twice as fast as the recursive approach even when
  # there are no parameters, and the "goto" version wins even more with larger
  # parameter lists.
  Loop:
    return $self->$method(@args)
      unless @param_names;
    my $key = shift @param_names;
    local $store->{$key}{params} = $params->{$key};
    goto Loop; # Watch Dijkstra roll in his grave
}

sub _resolved_attrs { my $self = shift; $self->call_with_parameters($self->next::can, @_) }
sub related_resultset { my $self = shift; $self->call_with_parameters($self->next::can, @_) }

1;

=head1 NAME

DBIx::Class::ResultSet::ParameterizedJoinHack

=head1 SYNOPSIS

    package MySchema::ResultSet::Person;
    use base qw(DBIx::Class::ResultSet);

    __PACKAGE__->load_components(qw(ResultSet::ParameterizedJoinHack));

    1;

=head1 DESCRIPTION

This is a ResultSet component allowing you to access the dynamically
parameterized relations declared with
L<DBIx::Class::ParameterizedJoinHack>.

Enable the component as usual with:
    
    __PACKAGE__->load_components(qw( ResultSet::ParameterizedJoinHack ));

in your ResultSet class.

See L<DBIx::Class::ParameterizedJoinHack> for declaration documentation,
a general overview, and examples.

=head1 METHODS

=head2 with_parameterized_join

    my $joined_rs = $resultset->with_parameterized_join(
        $relation_name,
        $parameters,
    );

This method constructs a ResultSet joined with the given C<$relation_name>
by the passed C<$parameters>. The C<$relation_name> is the name as
declared on the Result, C<$parameters> is a hash reference with the keys
being the parameter names, and the values being the arguments to the join
builder.

=head1 SPONSORS

Development of this module was sponsored by

=over

=item * Ctrl O L<http://ctrlo.com>

=back

=head1 AUTHOR

 Matt S. Trout <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2015 the DBIx::Class::ParameterizedJoinHack L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
