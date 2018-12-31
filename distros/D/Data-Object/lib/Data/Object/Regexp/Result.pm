# ABSTRACT: Regexp Result Object for Perl 5
package Data::Object::Regexp::Result;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Class;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

extends 'Data::Object::Array';

our $VERSION = '0.61'; # VERSION

method captures () {

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my @captures;

  for (my $i = 1; $i < @$last_match_end; $i++) {
    my $start = $last_match_start->[$i] || 0;
    my $end   = $last_match_end->[$i]   || 0;

    push @captures, substr "$string", $start, $end - $start;
  }

  return Data::Object::deduce_deep([@captures]);

}

method count () {

  return Data::Object::deduce_deep($self->[2]);

}

method initial () {

  return Data::Object::deduce_deep($self->[6]);

}

method last_match_end () {

  return Data::Object::deduce_deep($self->[4]);

}

method last_match_start () {

  return Data::Object::deduce_deep($self->[3]);

}

method named_captures () {

  return Data::Object::deduce_deep($self->[5]);

}

method matched () {

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::deduce_deep(substr "$string", $start, $end - $start);

}

method prematched () {

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::deduce_deep(substr "$string", 0, $start);

}

method postmatched () {

  my $string = $self->initial;

  my $last_match_start = $self->last_match_start;
  my $last_match_end   = $self->last_match_end;

  my $start = $last_match_start->[0] || 0;
  my $end   = $last_match_end->[0]   || 0;

  return Data::Object::deduce_deep(substr "$string", $end);

}

method regexp () {

  return Data::Object::deduce_deep($self->[0]);

}

method string () {

  return Data::Object::deduce_deep($self->[1]);

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Regexp::Result - Regexp Result Object for Perl 5

=head1 VERSION

version 0.61

=head1 SYNOPSIS

  use Data::Object::Regexp::Result;

  my $result = Data::Object::Regexp::Result->new([
    $regexp,
    $altered_string,
    $count,
    $last_match_end,
    $last_match_start,
    $named_captures,
    $initial_string
  ]);

=head1 DESCRIPTION

Data::Object::Regexp::Result provides routines for introspecting the
results of an operation involving a regular expressions. These methods work on
data whose shape conforms to the tuple defined in the synopsis.

=head1 METHODS

=head2 captures

  # given the expression qr/(.* test)/
  # given the string "example test matching"

  $result->captures; # ['example test']

The captures method returns the capture groups from the result object which
contains information about the results of the regular expression operation.

=head2 count

  # given the expression qr/.* test/
  # given the string "example test matching"

  $result->count; # 1

The count method returns the number of match occurrences from the result object
which contains information about the results of the regular expression
operation.

=head2 initial

  # given the expression qr/.* test/
  # given the string "example test matching"

  $result->replace($string, 'love', 'g');

  $result->string;  # 'love matching'
  $result->initial; # 'example test matching'

The initial method returns the unaltered string from the result object which
contains information about the results of the regular expression operation.

=head2 last_match_end

  # given the expression qr/(.* test)/
  # given the string "example test matching"

  $result->last_match_end;

The last_match_end method returns an array of offset positions into the string
where the capture(s) stopped matching from the result object which contains
information about the results of the regular expression operation.

=head2 last_match_start

  # given the expression qr/(.* test)/
  # given the string "example test matching"

  $result->last_match_start;

The last_match_start method returns an array of offset positions into the
string where the capture(s) matched from the result object which contains
information about the results of the regular expression operation.

=head2 matched

  # given the expression qr/.* test/
  # given the string "example test matching"

  $result->matched; # "example test"

The matched method returns the portion of the string that matched from the
result object which contains information about the results of the regular
expression operation.

=head2 named_captures

  # given the expression qr/(?<stuff>.* test)/
  # given the string "example test matching"

  $result->named_captures; # { stuff => "example test" }

The named_captures method returns a hash containing the requested named regular
expressions and captured string pairs from the result object which contains
information about the results of the regular expression operation.

=head2 postmatched

  # given the expression qr/(.* test)/
  # given the string "example test matching"

  $result->postmatched; # " matching"

The postmatched method returns the portion of the string after the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=head2 prematched

  # given the expression qr/(test .*)/
  # given the string "example test matching"

  $result->prematched; # "example "

The prematched method returns the portion of the string before the regular
expression matched from the result object which contains information about the
results of the regular expression operation.

=head2 regexp

  # given the expression qr/.* test/
  # given the string "example test matching"

  $result->regexp; # qr/.* test/

The regexp method returns the regular expression used to perform the match from
the result object which contains information about the results of the regular
expression operation.

=head2 string

  # given the expression qr/(.* test)/
  # given the string "example test matching"

  $result->string; # "example test matching"

The string method returns the string matched against the regular expression
from the result object which contains information about the results of the
regular expression operation.

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <al@iamalnewkirk.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
