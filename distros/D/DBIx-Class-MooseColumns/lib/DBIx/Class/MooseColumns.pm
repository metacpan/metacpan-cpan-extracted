package DBIx::Class::MooseColumns;

use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use DBIx::Class::MooseColumns::Meta::Role::Attribute;

=head1 NAME

DBIx::Class::MooseColumns - Lets you write DBIC add_column() definitions as attribute options

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';


=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;

  use Moose;
  use DBIx::Class::MooseColumns;
  use namespace::autoclean;

  extends 'DBIx::Class::Core';

  __PACKAGE__->table('artist');

  has id => (
    isa => 'Int',
    is  => 'rw',
    add_column => {
      is_auto_increment => 1,
    },
  );

  has foo => (
    isa => 'Str',
    is  => 'rw',
    add_column => {
      data_type => 'datetime'
    },
  );

  has bar => (        # will call __PACKAGE__->add_column({})
    isa => 'Str',
    is  => 'rw',
    add_column => {
    },
  );

  has quux => (       # no __PACKAGE__->add_column() call
    isa => 'Str',
    is  => 'rw',
  );

  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->meta->make_immutable( inline_constructor => 0 );

  1;

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

This module allows you to put the arguments to
L<DBIx::Class::ResultSource/add_column> right into your attribute definitions
and will automatically call it when it finds an C<add_column> attribute option.
It also replaces the L<DBIx::Class>-generated accessor methods (these are
L<Class::Accessor::Grouped>-generated accessor methods under the hood) with the
L<Moose>-generated accessor methods so that you can use more of the wonderful
powers of L<Moose> (eg. type constraints, triggers, ...).

I<Note:> C<< __PACKAGE__->table(...) >> must go B<before> the C<has> stanzas
(the L<DBIx::Class::ResultSource/table> is magic and does much more than
setting the table name, thus the C<< __PACKAGE__->add_column(...) >> calls that
the C<has> triggers won't work before that).

I<Note:> C<< __PACKAGE__->set_primary_key(...) >> and C<<
__PACKAGE__->add_unique_constraint(...) >> calls must go B<after> the C<has>
stanzas (since they depend on the referred columns being registered via C<<
__PACKAGE__->add_column(...) >> and that call is done when the C<has> runs).

=head1 TODO

=over

=item *

convert the test harness to something sane - consider L<Fennec>?

=item *

delay ->add_column() calls until right after the ->table() call (collect the args and run them in an after method modifier of 'table', possibly batched in a single ->add_columns() call)

=back

=head1 SEE ALSO

L<DBIx::Class>, L<Moose>

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-moosecolumns at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-MooseColumns>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::MooseColumns

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-MooseColumns>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-MooseColumns>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-MooseColumns>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-MooseColumns/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

my %metaroles = (
  class_metaroles => {
    attribute => ['DBIx::Class::MooseColumns::Meta::Role::Attribute'],
  },
);

if ( $Moose::VERSION >= 1.9900 ) {
  $metaroles{role_metaroles} = {
    applied_attribute => ['DBIx::Class::MooseColumns::Meta::Role::Attribute'],
  };
}

Moose::Exporter->setup_import_methods(%metaroles);

1; # End of DBIx::Class::MooseColumns
