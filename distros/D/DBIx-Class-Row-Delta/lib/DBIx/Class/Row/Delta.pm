package DBIx::Class::Row::Delta;
$DBIx::Class::Row::Delta::VERSION = '0.0.5';
use Moose;

=head1 NAME

DBIx::Class::Row::Delta - Keep track of and report on changes to a
DBIC row object.

=head1 DESCRIPTION

Record an initial set of values for a DBIC row, and later on get a
string with the changed values.

=head1 SYNOPSIS

  use DBIx::Class::Row::Delta;

  my $book = $book_rs->find(321);
  my $book_notes_delta = DBIC::Row::Delta->new({
      dbic_row    => $book,
      changes_sub => sub {
          my ($row) = @_;
          return {
              "Book Type"     => $row->book_type->type,
              "Book Title"    => $row->book_title->title // "N/A",
              "Delivery Date" => $row->delivery_date->ymd,
          };
      },
  });

  # ...
  # Do stuff to $book, ->update(), etc.
  # ...

  # Note: this will discard_changes on $book.
  my $changes_string = $book_notes_delta->changes;
  # e.g.
  # Book SKU (1933021-002 => 1933023-001), Delivery Date (2012-01-18 => 2012-01-22)

=cut

has dbic_row           => (is => "rw", required => 1);

has changes_sub        => (is => "ro", isa => "CodeRef", required => 1);

has _initial_key_value => (is => "rw", isa => "HashRef", default => sub { +{} });

no Moose;

=head1 METHODS

=head2 new({ $dbic_row!, &$changes_sub! }) : $new_object | die

Create a new object. Start by taking a snapshot of the contents of
$dbic_row by calling $changes_sub->($dbic_row).

The sub ref $changes_sub should return a hash ref with keys and values
that describe the state of the object. If the values look weird when
stringified, you're responsible for formatting them properly. All the
hash ref values should be strings or undef.

Both dbic_row and changes_sub are required.

=cut

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    $self->_initial_key_value(
        $self->changes_sub->( $self->dbic_row ),
    );
}

=head2 changes() : $delta_string | undef

Return a string representation of the diff between the initial
snapshot and the current state of $dbic_row, or return undef if they
are the same. Only the changed values are reported.

Example:

    Book SKU (1933021-002 => 1933023-001), Delivery Date (2012-01-18 => 2012-01-22)

Note: This will start by calling $dbic_row->discard to refresh the
data properly.

=cut

sub changes {
    my $self = shift;
    my $delta_key_value = $self->delta_key_value();
    keys %$delta_key_value or return undef; ## no critic
    return $self->changes_from_delta($delta_key_value);
}

sub delta_key_value {
    my $self = shift;

    my $dbic_row = $self->dbic_row;
    $dbic_row->discard_changes();
    my $current_key_value = $self->changes_sub->( $dbic_row );

    return $self->diff( $self->_initial_key_value, $current_key_value );
}

sub diff {
    my $self = shift;
    my ($before_key_value, $after_key_value) = @_;
    return {
        map { $_ => $after_key_value->{$_} }
        grep { ($after_key_value->{$_} // "") ne ($before_key_value->{$_} // "") }
        keys %$after_key_value
    };
}

sub changes_from_delta {
    my $self = shift;
    my ($delta_key_value) = @_;
    my $initial_key_value = $self->_initial_key_value;
    return join(
        ", ",
        (
            map {
                "$_(" . empty($initial_key_value->{$_}) . " => "
                      . empty($delta_key_value->{$_}) . ")";
            }
            sort keys %$delta_key_value
        ),
    );
}

sub empty {
    my ($value) = @_;
    defined $value or return "''";
    return $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-row-delta at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Row-Delta>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Row::Delta


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Row-Delta>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Row-Delta>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Row-Delta>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Row-Delta/>

=back


=head1 CONTRIBUTE

The source for this module is on GitHub: https://github.com/jplindstrom/p5-DBIx-Class-Row-Delta

Patches welcome, etc.


=head1 AUTHOR

Johan Lindstrom - C<johanl@cpan.org> on behalf of
Net-A-Porter - L<http://www.net-a-porter.com/>



=head1 LICENSE AND COPYRIGHT

Copyright 2012- Net-A-Porter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.



=head1 ACKNOWLEDGEMENTS

Thanks to Net-A-Porter for providing time during one of the regular
Hack-days.


=cut
