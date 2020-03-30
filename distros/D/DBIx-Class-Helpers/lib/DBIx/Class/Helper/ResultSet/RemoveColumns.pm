package DBIx::Class::Helper::ResultSet::RemoveColumns;
$DBIx::Class::Helper::ResultSet::RemoveColumns::VERSION = '2.036000';
# ABSTRACT: Remove columns from a ResultSet

use strict;
use warnings;

use parent 'DBIx::Class::ResultSet';

sub _resolved_attrs {
   my $self = $_[0];

   my $attrs  = $self->{attrs}; # not copying on purpose...

   if ( !$attrs->{columns} && !$attrs->{select} && $attrs->{remove_columns} ) {
      my %rc = map { $_ => 1 } @{$attrs->{remove_columns}};
      $attrs->{columns} = [
         grep { !$rc{$_} } $self->result_source->columns
      ]
   }

   return $self->next::method;
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::ResultSet::RemoveColumns - Remove columns from a ResultSet

=head1 SYNOPSIS

 package MySchema::ResultSet::Bar;

 use strict;
 use warnings;

 use parent 'DBIx::Class::ResultSet';

 __PACKAGE__->load_components('Helper::ResultSet::RemoveColumns');

 # in code using resultset:
 my $rs = $schema->resultset('Bar')->search(undef, {
    remove_columns => ['giant_text_col', 'password'],
 });

=head1 DESCRIPTION

This component allows convenient removal of columns from a select.
Normally to do this you would do this by listing all of the columns
B<except> the ones you want to remove.  This does that part for you.
See L<DBIx::Class::Helper::ResultSet/NOTE> for a nice way to apply it to
your entire schema.

It doesn't get a lot more complicated than the synopsis.  If you are interested
in having more control, check out
L<DBIx::Class::Helper::ResultSet::AutoRemoveColumns>.

=over

=item *

Load the component

=item *

Put an C<ArrayRef> of columns to remove in the C<remove_columns> search attribute.

=item *

Profit.

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
