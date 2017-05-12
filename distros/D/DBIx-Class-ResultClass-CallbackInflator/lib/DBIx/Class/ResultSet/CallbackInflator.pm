use strict;
use warnings;

package DBIx::Class::ResultSet::CallbackInflator;

use DBIx::Class::ResultClass::CallbackInflator;

sub inflator {
  my ($self, $callback, @args) = @_;
  my $result_instance = DBIx::Class::ResultClass::CallbackInflator
    ->new(callback=>$callback, args=>\@args);
  return $self->search(+{}, +{result_class=>$result_instance});
}

1;

=head1 NAME

DBIx::Class::ResultSet::CallbackInflator - Easy way to use DBIx::Class::ResultClass::CallbackInflator

=head1 SYNOPSIS

Given a L<DBIx::Class::ResultSet> that consumes this component, such as the
following:

    package MySchema::ResultSet::Peson;

    use strict;
    use warnings;
    use parent 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('ResultSet::CallbackInflator');

    ## Additional custom resultset methods, if any

    1;

Then later when you have a resultset of that class:

    my $rs = $schema->resultset('Person')
      ->inflator(sub {
        my ($cb, $source, $data, $optional_prefetch, @args) = @_;
        return $data;
      }, @args);

When the resultset in C<$rs> is unrolled the callback will be run for each row returned from
the query and you can customize the response (must be a reference).  For example you might use
this to change or add to the existing C<$data> for a purpose that is meaningful to your
application.

B<NOTE> Currently we localize C<%_> in the callback coderef to be C<%$data> to make it
easier to do the most standard (I think) types of transformations.
    
=head1 DESCRIPTION

Lets you decide how a resultset inflates any data in rows from the database table
it is pointing at (with any prefetch information included) by using a coderef
which will in in place of 'inflate_result'.

This is basically sugar for L<DBIx::Class::ResultClass::CallbackInflator>

=head1 METHODS

This component defines the following methods.

=head2 inflator

Allows you to use a callback as a custom inflator class.  Example:

    $rs->inflator(sub {
      my ($cb, $result_source, \%columndata, \%prefetcheddata, @args) = @_;
      return ...
    })->all;

Should return a reference to the representation of the row that you are seeking.

B<NOTE>: The last argument C<\%prefetcheddata> is optional.  If there isn't any the
location in C<@_> will be undef so that any @args passed will be in expected position.

B<NOTE>: The call to ->inflator returns the original resultset to allow for easy
chaining.

=head1 AUTHOR

See L<DBIx::Class::ResultClass::CallbackInflator>.

=head1 COPYRIGHT & LICENSE

See L<DBIx::Class::ResultClass::CallbackInflator>.

=cut
