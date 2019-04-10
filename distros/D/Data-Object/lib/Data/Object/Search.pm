package Data::Object::Search;

use parent 'Data::Object::Array';

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  'bool'   => 'data',
  'qr'     => 'regexp',
  '@{}'    => 'self',
  fallback => 1
);

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

sub captures {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my @captures;

  for (my $i = 1; $i < @$last_match_end; $i++) {
    my $start = $last_match_start->[$i] || 0;
    my $end   = $last_match_end->[$i]   || 0;

    push @captures, substr "$string", $start, $end - $start;
  }

  return Data::Object::Export::deduce_deep([@captures]);
}

sub count {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[2]);
}

sub initial {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[6]);
}

sub last_match_end {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[4]);
}

sub last_match_start {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[3]);
}

sub named_captures {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[5]);
}

sub matched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::Export::deduce_deep(substr "$string", $start, $end - $start);
}

sub prematched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::Export::deduce_deep(substr "$string", 0, $start);
}

sub postmatched {
  my ($self) = @_;

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::Export::deduce_deep(substr "$string", $end);
}

sub regexp {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[0]);
}

sub string {
  my ($self) = @_;

  return Data::Object::Export::deduce_deep($self->[1]);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Search

=cut

=head1 ABSTRACT

Data-Object Regex Class

=cut

=head1 SYNOPSIS

  use Data::Object::Search;

  my $result = Data::Object::Search->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=cut

=head1 DESCRIPTION

Data::Object::Search provides routines for introspecting the results of an
operation involving a regular expressions. These methods work on data whose
shape conforms to the tuple defined in the synopsis.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 captures

  captures() : ArrayObject

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.

=over 4

=item captures example

  my $captures = $result->captures();

=back

=cut

=head2 count

  count() : NumObject

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation.

=over 4

=item count example

  my $count = $result->count();

=back

=cut

=head2 initial

  initial() : StrObject

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

=over 4

=item initial example

  my $initial = $result->initial();

=back

=cut

=head2 last_match_end

  last() : Any

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation.

=over 4

=item last_match_end example

  my $last_match_end = $result->last_match_end();

=back

=cut

=head2 last_match_start

  last() : Any

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

=over 4

=item last_match_start example

  my $last_match_start = $result->last_match_start();

=back

=cut

=head2 matched

  matched() : StrObject | UndefObject

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

=over 4

=item matched example

  my $matched = $result->matched();

=back

=cut

=head2 named_captures

  name() : StrObject


The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

=over 4

=item named_captures example

  my $named_captures = $result->named_captures();

=back

=cut

=head2 postmatched

  postmatched() : StrObject | UndefObject

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=over 4

=item postmatched example

  my $postmatched = $result->postmatched();

=back

=cut

=head2 prematched

  prematched() : StrObject | UndefObject

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=over 4

=item prematched example

  my $prematched = $result->prematched();

=back

=cut

=head2 regexp

  regexp() : RegexpObject

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation.

=over 4

=item regexp example

  my $regexp = $result->regexp();

=back

=cut

=head2 string

  string() : StrObject

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation.

=over 4

=item string example

  my $string = $result->string();

=back

=cut

=head1 ROLES

This package inherits all behavior from the folowing role(s):

=cut

=over 4

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Collection>

=item *

L<Data::Object::Rule::Comparison>

=item *

L<Data::Object::Rule::Defined>

=item *

L<Data::Object::Rule::List>

=back
