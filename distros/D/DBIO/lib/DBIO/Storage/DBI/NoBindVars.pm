package DBIO::Storage::DBI::NoBindVars;
# ABSTRACT: Some DBDs have poor to no support for bind variables

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Storage::DBI';
use mro 'c3';

use Scalar::Util ();


sub connect_info {
    my $self = shift;
    my $retval = $self->next::method(@_);
    $self->disable_sth_caching(1);
    $retval;
}


sub _prep_for_execute {
  my $self = shift;

  my ($sql, $bind) = $self->next::method(@_);

  return $self->_interpolate_bind_values($sql, $bind);
}


sub _prep_rendered_for_execute {
  my ($self, $sql, $bind) = @_;

  return $self->_interpolate_bind_values($sql, $bind);
}


sub _interpolate_bind_values {
  my ($self, $sql, $bind) = @_;

  my @sql_part = split_at_placeholders($sql);
  my $new_sql = '';

  $self->throw_exception(sprintf
    'placeholder count %d does not match bind count %d',
    $#sql_part, scalar @$bind,
  ) unless $#sql_part == @$bind;

  for (@$bind) {
    my $data = (ref $_->[1]) ? "$_->[1]" : $_->[1]; # always stringify, array types are currently not supported

    my $datatype = $_->[0]{sqlt_datatype};

    $data = $self->_prep_interpolated_value($datatype, $data)
      if $datatype;

    $data = $self->_get_dbh->quote($data)
      unless ($datatype and $self->interpolate_unquoted($datatype, $data) );

    $new_sql .= shift(@sql_part) . $data;
  }

  $new_sql .= join '', @sql_part;

  # the bind list is empty, and remembers the statement in placeholder form
  # and the values for the text of an error (_error_form_of_bind)
  return ($new_sql, DBIO::Storage::DBI::NoBindVars::Interpolated->new(
    $sql, [ map { $_->[1] } @$bind ],
  ));
}


sub _error_form_of_bind {
  my ($self, $sql, $bind) = @_;

  my $form = DBIO::Storage::DBI::NoBindVars::Interpolated->form_of($bind);
  return $form ? @$form : $self->next::method($sql, $bind);
}


# The one scanner rule. Returns [ $is_placeholder, $text, $offset ] for every
# token of the statement; only a free ? is a placeholder, quoted names,
# literals and comments come through as text.
sub _scan_sql {
  my ($sql) = @_;

  my @tok;
  while ($sql =~ /\G(?:
      ( "(?:[^"]|"")*(?:"|\z) | `(?:[^`]|``)*(?:`|\z) | '(?:[^']|'')*(?:'|\z)
        | \[(?:[^\]]|\]\])*\]                        # quoted: kept as text
        | --[^\n]* | \/\*.*?(?:\*\/|\z) )            # comment: kept as text
    | ( \? )                                          # free placeholder
    | ( [^"`'\[?\-\/]+ | . )                          # anything else
  )/gxs) {
    my $off = $-[0];
    if    (defined $1) { push @tok, [ 0, $1, $off ] }
    elsif (defined $2) { push @tok, [ 1, $2, $off ] }
    else               { push @tok, [ 0, $3, $off ] }
  }
  return @tok;
}

sub split_at_placeholders {
  my @part = ('');
  for my $tok (_scan_sql($_[0])) {
    if ($tok->[0]) { push @part, '' }
    else           { $part[-1] .= $tok->[1] }
  }
  return @part;
}


sub placeholder_offsets {
  return map { $_->[2] } grep { $_->[0] } _scan_sql($_[0]);
}


sub interpolate_unquoted {
  #my ($self, $datatype, $value) = @_;

  return 1 if (
    defined $_[2]
      and
    $_[1]
      and
    $_[2] !~ /\D/
      and
    $_[1] =~ /int(?:eger)? | (?:tiny|small|medium|big)int/ix
  );

  return 0;
}


sub _prep_interpolated_value {
  #my ($self, $datatype, $value) = @_;
  return $_[2];
}

# The empty bind list NoBindVars hands on. It behaves as the empty array and
# carries, apart from its own slots, the statement in placeholder form and the
# values that were written into the statement (inside-out, keyed by address).
package DBIO::Storage::DBI::NoBindVars::Interpolated;

my %form;

sub new {
  my ($class, $sql, $values) = @_;
  my $self = bless [], $class;
  $form{ Scalar::Util::refaddr($self) } = [ $sql, $values ];
  return $self;
}

sub form_of {
  my ($class, $bind) = @_;
  return undef unless Scalar::Util::blessed($bind) and $bind->isa($class);
  return $form{ Scalar::Util::refaddr($bind) };
}

sub DESTROY { delete $form{ Scalar::Util::refaddr($_[0]) } }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::NoBindVars - Some DBDs have poor to no support for bind variables

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

This class allows queries to work when the DBD or underlying library does not
support the usual C<?> placeholders, or at least doesn't support them very
well, as is the case with L<DBD::Sybase>

=head1 METHODS

=head2 connect_info

We can't cache very effectively without bind variables, so force the C<disable_sth_caching> setting to be turned on when the connect info is set.

=head2 _prep_for_execute

Manually subs in the values for the usual C<?> placeholders.

=head2 _prep_rendered_for_execute

The same substitution for a statement core rendered itself rather than
generated through C<sql_maker> -- the EXISTS statement
L<DBIO::ResultSet/results_exist> runs (ADR 0037). It does not pass through
L</_prep_for_execute>, so without this it would reach an engine with no usable
placeholders with its C<?> intact.

=head2 _interpolate_bind_values

Stringify the bind args, quote them via C<$dbh>, and manually insert them in
place of the C<?> placeholders. Returns the new SQL and an empty bind list; the
list is an object of C<DBIO::Storage::DBI::NoBindVars::Interpolated> that keeps
the statement in placeholder form and the values apart, for the text of an
error.

The placeholders are the free C<?> found by L</split_at_placeholders>; a C<?>
inside a quoted identifier or a string literal is part of the name or the
text. The number of placeholders has to equal the number of binds, otherwise
the statement is refused with C<placeholder count N does not match bind count
M>.

=head2 _error_form_of_bind

The statement of an error text is the statement in placeholder form with the
number of values written into it (C<VALUES (?, ?) with 2 bind values>), and
the values go to L<DBIO::Storage::DBI/_mask_error_values>: the statement that
reaches the engine carries them, the text of an error does not.

=head2 split_at_placeholders

  my @part = DBIO::Storage::DBI::NoBindVars::split_at_placeholders($sql);

A function, not a method of the storage. Walks the rendered statement and
returns the text between its placeholders, so the result has one element more
than the statement has placeholders (empty elements at either end are kept).
A placeholder is a C<?> outside any quoted identifier (C<"...">, C<`...`>,
C<[...]>, the closing quote doubled inside), outside any string literal
(C<'...'>, with C<''> for a quote inside) and outside any SQL comment (C<-->
to the end of the line, C</* ... */>). A C<?> in one of those stays in the
text, and so does a C<--> or C</*> inside a literal or a quoted identifier. A
comment left open at the end of the statement is text up to the end. A driver
with an interpolation path of its own uses this function to find its
placeholders instead of searching the text for C<?>, and compares their number
with the number of binds.

=head2 placeholder_offsets

  my @offset = DBIO::Storage::DBI::NoBindVars::placeholder_offsets($sql);

A function, not a method of the storage. Returns the character offset of every
free placeholder in the statement, in order. It applies the rule of
L</split_at_placeholders> (the two share one scanner), so C<substr($sql,
$offset, 1)> is C<?> for each offset and their number is the number of
placeholders.

=head2 interpolate_unquoted

This method is called by L</_interpolate_bind_values> (and so by both
L</_prep_for_execute> and L</_prep_rendered_for_execute>) for every bind
value that carries a data type, in
order to determine if its value should be quoted or not. The arguments
are the current column data type and the actual bind value. The return
value is interpreted as: true - do not quote, false - do quote. You should
override this in your Storage::DBI::<database> subclass, if your RDBMS
does not like quotes around certain datatypes (e.g. Sybase and integer
columns). The default method returns false, except for integer datatypes
paired with values containing nothing but digits.

 WARNING!!!

 Always validate that the bind-value is valid for the current datatype.
 Otherwise you may very well open the door to SQL injection attacks.

=head2 _prep_interpolated_value

Given a datatype and the value to be inserted directly into a SQL query, returns
the necessary string to represent that value (by e.g. adding a '$' sign)

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
