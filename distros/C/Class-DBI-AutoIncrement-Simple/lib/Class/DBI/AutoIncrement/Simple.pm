package Class::DBI::AutoIncrement::Simple;

use warnings;
use strict;
use base 'Class::DBI';
our $VERSION = '0.02';

sub __add_row {
  my $self = shift;
  my $method = shift;
  my $pk = $self->primary_column;
  $_[0]->{$pk} ||= ($self->maximum_value_of($pk)||0) + 1;
  if( $method eq 'create' ){
    return $self->SUPER::create(@_);
  }else{
    return $self->SUPER::insert(@_);
  }
}

sub insert {
  my $self = shift;
  return $self->__add_row('insert', @_);
}

sub create {
  my $self = shift;
  return $self->__add_row('create', @_);
}

1; # End of Class::DBI::AutoIncrement::Simple

=pod

=head1 NAME

Class::DBI::AutoIncrement::Simple - Add autoincrementing to a Class::DBI subclass

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Provides an alternative L<Class::DBI> base class that automatically uses an autoincremented value for the (single column) primary key when creating new rows.

    package My::DB::Base;
    use base 'Class::DBI::AutoIncrement::Simple';
    __PACKAGE__->connection("DBI:CSV:f_dir=data/");

    package My::DB::Table1;
    use base 'My::DB::Base';
    __PACKAGE__->table('table1');
    __PACKAGE__->columns(Primary => qw/ my_id /);
    __PACKAGE__->columns(Essential => qw/ first_name last_name / );

For newer versions of Class::DBI

    my $foo = My::DB::Table1->insert({first_name=>'foo', last_name=>'bar'});
    warn $foo->my_id;    # will be the autoincremented value

    my $bar = My::DB::Table1->insert({my_id => 1234, first_name=>'foo', last_name=>'bar'});
    warn $foo->my_id;    # will be 1234

For older versions of Class::DBI

    my $foo = My::DB::Table1->create({first_name=>'foo', last_name=>'bar'});
    warn $foo->my_id;    # will be the autoincremented value

    my $bar = My::DB::Table1->create({my_id => 1234, first_name=>'foo', last_name=>'bar'});
    warn $foo->my_id;    # will be 1234

=head1 METHODS

=head2 insert

Overloads the Class::DBI->insert() method to first (if not provided) give the primary key an autoincremented value, then calls insert() in the base class.

=head2 create

Same as L<insert> -- provided for backwards-compatibility of Class::DBI

=head1 NOTES

This requires/assumes that the class has a single-column primary key.

This could also be accomplished by just directly adding this method overload to your base or subclass:

  sub insert {
    my $self = shift;
    my $pk = $self->primary_column;
    $_[0]->{$pk} ||= ($self->maximum_value_of($pk)||0) + 1;
    return $self->SUPER::insert(@_);
  }

There is also L<Class::DBI::AutoIncrement> which is different in nature -- it works by multiple inheritance (you inherit from both it and Class::DBI) and so has some issues there (see its Limitations section); but it does have more features in that you can specify the start and step size of a sequence and do some caching.

But this module is meant to be "Simple" :)

=head1 PREREQUISITES

=over 4

=item L<Class::DBI>

=back

The following are required for the I<t/csv.t> test script:

=over 4

=item L<File::Temp>

=item L<File::Basename>

=item L<DBD::CSV>

And all of it's deps (DBD::File, SQL::Statement, etc).

=back


=head1 AUTHOR

David Westbrook, C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-autoincrement-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-AutoIncrement-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I'm also available by email or via '/msg davidrw' on L<http://perlmonks.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::DBI::AutoIncrement::Simple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-DBI-AutoIncrement-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-DBI-AutoIncrement-Simple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-AutoIncrement-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-AutoIncrement-Simple>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

