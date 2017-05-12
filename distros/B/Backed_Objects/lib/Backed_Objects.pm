package Backed_Objects;

use warnings;
use strict;

=head1 NAME

Backed_Objects - Create static files from a database.

=head1 VERSION

Version 1.16

=cut

our $VERSION = '1.16';

=head1 SYNOPSIS

Create static files from a database.
Update the files every time when you update the database.

It can be used with any kind of database, for example SQL databases,
Berkeley databases, data stored in .ini files, etc.

=head1 USAGE OF THE CLASS

The class C<Backed_Objects> is an abstract base class and you need to
derive your class from it. For further suppose you developed a class
C<HTML_DB> derived from C<Backed_Objects>. We will call HTML (for example)
files which are updated by this module I<the view>.

All methods can be called either as object methods or as class methods.

Calling these as class methods may be convienient when you do not need to
specify additional parameters to be put into an object.

Thus the following alternatives are possible:

  HTML_DB->output_all_and_order;

or

  my $obj = HTML_DB->new;
  $obj->output_all_and_order;

Examples below assume that you are familiar with SQL and C<DBI> module.

=head1 Database update methods

The class C<Backed_Objects> offers you flexibility on the way how you
update your database.

One variant is to override C<do_insert>, C<do_update>, C<do_delete>, C<post_process> methods,
so that they will update your database when C<insert>, C<update>, C<delete>
methods are called.

The other variant is to update the database yourself and I<afterward>
to call C<insert>, C<update>, C<delete> which will call the default
do-nothing C<do_insert>, C<do_update>, C<do_delete>, C<post_process> methods.

=head1 The object and the ID

A database stores objects, every object stored in a database has an ID.
An object may be without an ID when it is not yet stored into the DB, but
you must assign an ID to an object when you store it in the DB, either
by overriding C<do_insert> method which should set the object ID or yourself
in your own code (without overriding C<do_insert>). C<HTML_DB> must have
C<id> method which receives an object and return its ID.

The interface of this module does not specify what objects are. Objects may
be hashes or any other data structures.

Every object inserted into the database has ID (which may be a natural number,
but is not required to be a number).

Sometimes you may want the objects and IDs to be the same. For example, it is
often OK for an object and an ID to be a row ID in a SQL database. Or you may
want an object to be a hash representing a row in an SQL DB.

Sometimes a middle solution is fit: Store an object as a hash with some
values from the database and read the rest values from the DB when needed,
using the ID stored in the object.

An other possibililty for an object is to be a hash based on user input in
a HTML form.

=head1 METHODS

=head2 id

This abstract (not defined in C<Backed_Objects> method) must be defined to
return the ID of an object.

Examples:

  sub id {
    my ($self, $obj) = @_;
    return $obj->{id};
  }

or

  # Objects are simple IDs
  sub id {
    my ($self, $obj) = @_;
    return $obj;
  }

=head2 all_ids

This abstract (not defined in C<Backed_Objects> method) must return a list of
all IDs in the database.

  sub all_ids {
    my ($self) = @_;
    return @{ $dbh->selectcol_arrayref("SELECT id FROM table") };
  }

=cut

=head2 do_select

This abstract method should return an object from the DB having a given ID.

  sub do_select {
    my ($self, $id) = @_;
    return $dbh->selectrow_hashref("SELECT * FROM table WHERE id=?", undef, $id);
  }

or

  # Objects are simple IDs
  sub do_select {
    my ($self, $id) = @_;
    return $id;
  }

=head2 select

This method returns an object from the DB or C<undef> if the ID is absent
(undefined or zero).

See its implementation:

  sub select {
    my ($self, $id) = @_;
    return undef unless $id;
    return $self->do_select($id);
  }

=cut

sub select {
  my ($self, $id) = @_;
  return undef unless $id;
  return $self->do_select($id);
}

=head2 do_insert, do_update, do_delete, post_process

By default these methods do nothing. (In this case you need to update database
yourself, before calling C<insert>, C<update>, or C<delete> methods.)

You may override these methods to do database updates:

  sub do_insert {
    my ($self, $obj) = @_;
    my @keys = keys %$obj;
    my @values = values %$obj;
    my $set = join ', ', map { "$_=?" } @keys;
    $dbh->do("INSERT table SET $set", undef, @values);
    $obj->{id} = $dbh->last_insert_id(undef, undef, undef, undef);
  }

  sub do_update {
    my ($self, $obj) = @_;
    my @keys = keys %$obj;
    my @values = values %$obj;
    my $set = join ', ', map { "$_=?" } @keys;
    $dbh->do("UPDATE table SET $set WHERE id=?", undef, @values, $obj->{id});
  }

  sub do_delete {
    my ($self, $id) = @_;
    $dbh->do("DELETE FROM table WHERE id=?", undef, $id);
  }

  sub post_process {
    my ($self, $obj) = @_;
    ...
  }

C<do_insert> should set object ID after it is saved into the database.

C<post_process> is called by C<insert> after the object is inserted into
the database (and the object ID is set). It can be used for amending the
object with operations which require some object ID, for example for
uploading files into a folder with name being based on the ID.

C<post_process> is also called by C<update>.

=cut

sub do_insert { }
sub do_update { }
sub do_delete { }
sub post_process { }

=head2 outputter

This method should return a value used to output a view of the DB
(for example it may be used to output HTML files and be a hash whose values
are HTML templates).

Example:

  use File::Slurp;

  sub outputter {
    my ($self) = @_;
    my $template_dir = "$ENV{DOCUMENT_ROOT}/templates";
    return { main_tmpl => read_file("$template_dir/main.html"),
             announce_tmpl => read_file("$template_dir/announce.html") };
  }

The default implementation returns C<undef>.

=cut

sub outputter { }

=head2 insert, update, delete

  HTML_DB->insert($obj);
  HTML_DB->update($obj);
  HTML_DB->delete($id);

These functions update the view based on the value C<$obj> from the DB.
They are to be called when an object is inserted, updated, or deleted in
the DB.

If you've overridden the C<do_insert>, C<do_update>, or C<do_delete> methods,
then C<insert>, C<update>, or C<delete> methods update the database before
updating the view.

Note that C<insert> methods calls both C<on_update> and C<on_insert> methods
(as well as some other methods, see the source).

C<insert> and C<update> also call C<post_process>.

C<update> also calls C<before_update> before calling C<do_update>.
The C<before_update> method can be used to update the data based on
old data in the DB, before the DB is updated by C<do_update>.

=cut

# Calls both on_update() and on_insert()
sub insert {
  my ($self, $obj) = @_;
  die "Inserting an object into DB second time!" if $self->id($obj);
  $self->do_insert($obj);
  $self->post_process($obj);
  $self->on_insert($obj);
  $self->on_update($obj);
  $self->on_order_change;
  $self->on_any_change;
}

sub update {
  my ($self, $obj) = @_;
  die "Updating an object not in DB!" unless $self->id($obj);
  $self->before_update($obj);
  $self->do_update($obj);
  $self->post_process($obj);
  $self->on_update($obj);
  $self->on_any_change;
}

sub delete {
  my ($self, $id) = @_;
  $self->do_delete($id);
  $self->on_order_change;
  $self->on_delete($id);
  $self->on_any_change;
}

=head2 on_update, on_update_one

C<on_update> method it called when an object in the database is updated or after
a new object is inserted.

C<on_update_one> is the method called by C<on_update>. The C<on_update_one>
method is meant to update view of one object. Contrary to this, C<on_update>
may be overridden to update several objects by calling C<on_update_one> several
times. For example, when updating title of a HTML file, we may want to update
two more HTML files with titles of prev/next links dependent on the title of
this object.

By default C<on_update_one> calls the C<output> method to update the view of the
object.

=cut

sub on_update {
  my ($self, $obj) = @_;
  $self->on_update_one($obj);
}

sub on_update_one {
  my ($self, $obj) = @_;
  $self->output(scalar($self->outputter), $obj, 1);
}

=head2 on_insert, on_delete, on_order_change, before_update

  sub on_insert {
    my ($self, $obj) = @_;
    ...
  }

  sub on_delete {
    my ($self, $id) = @_;
    ...
  }

  sub on_order_change {
    my ($self) = @_;
    ...
  }

  sub before_update {
    my ($self, $obj) = @_;
    ...
  }

These methods (doing nothing by default) are called correspondingly when:

=over

=item inserting a new object into the database;

=item deleting an object from the database;

=item changing order of objects in the database (including the case of inserting a new object).

=item before calling C<do_update> to update the database.

=back

By default these methods do nothing.

You may update your view in your overrides of these methods.

C<before_update> is called by C<update> (but not by C<insert>) before updating
the DB with C<do_update>.

=cut

sub on_insert { }
sub on_delete { }
sub on_order_change { }
sub before_update { }

=head2 on_any_change

  sub on_any_change {
    my ($self) = @_;
    ...
  }

This method is called after every change of the database, for example,
after insertion, deletion, update, etc.

=cut

sub on_any_change { }

=head2 do_output

  sub do_output {
    my ($self, $outputter, $obj, $update) = @_;
    ...
  }

This is the main method to output your files (the view).

It receives the object and the outputter returned by the C<outputter> method.

$update is TRUE only if it is called from C<update> method. It can be used
not to update what needs not updating. (TODO: Document it better.)

=cut

sub do_output { }

=head2 order_change

  HTML_DB->order_change;

Call C<order_change> after you changed the order of objects in the
database (but not after calling C<insert> or C<delete> method which call
C<order_change> automatically).

=cut

sub order_change {
  my ($self) = @_;
  $self->on_order_change;
  $self->on_any_change;
}

=head2 output_by_id

An internal function.

=cut

sub output_by_id {
  my ($self, $id, $outputter) = @_;
  $outputter = $self->outputter unless $outputter;
  my $obj = $self->select($id);
  $self->output($outputter, $obj);
}

=head2 output_all

  HTML_DB->output_all;
  HTML_DB->output_all_and_order;

C<output_all> updates the entire set of your files based on the
data in the DB.

C<output_all_and_order> additionally updates data dependent on the order
of objects in the DB.

Use these methods to update your all files (for example, after your template
changed).

=cut

sub output_all {
  my ($self) = @_;
  my @ids = $self->all_ids;
  my $outputter = $self->outputter;
  for my $id (@ids) {
    $self->output_by_id($id, $outputter);
  }
  $self->on_any_change;
}

# Is it better to first call output_all and then on_order_change, or the reverse
sub output_all_and_order {
  my ($self) = @_;
  $self->output_all;
  $self->on_order_change;
}

=head2 save

  HTML_DB->save($obj);

This saves an object into the DB: updates it if it is already in the DB
(has an ID) or inserts it into the DB if it has an undefined ID.

The actual code:

  sub save {
    my ($self, $obj) = @_;
    if($self->id($obj)) {
      $self->update($obj);
    } else {
      $self->insert($obj);
    }
  }

=cut

sub save {
  my ($self, $obj) = @_;
  if($self->id($obj)) {
    $self->update($obj);
  } else {
    $self->insert($obj);
  }
}

=head2 output

An internal function.

=cut

sub output {
  my ($self, $outputter, $obj, $update) = @_;
  die "Object has no ID!" unless $self->id($obj);
  $self->do_output(scalar($outputter), $obj, $update);
}

=head1 AUTHOR

Victor Porton, C<< <porton@narod.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-backed_objects at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Backed_Objects>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

In the current version of C<Backed_Objects> there are no provision for passing
file handles for example got from a HTML form with a C<file> control.
A complexity is that usually to upload a file we need to already know the
ID of a row in a database what is possible only I<after> inserting into the DB.
Your suggestions how to deal with this problem are welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Backed_Objects


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Backed_Objects>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Backed_Objects>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Backed_Objects>

=item * Search CPAN

L<http://search.cpan.org/dist/Backed_Objects/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Victor Porton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Backed_Objects
