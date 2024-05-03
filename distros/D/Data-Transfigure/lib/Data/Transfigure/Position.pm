package Data::Transfigure::Position 1.03;
use v5.26;
use warnings;

# ABSTRACT: a compound transfigurator that specifies one or more locations within the data structure to apply to

=head1 NAME

Data::Transfigure::Position - a compound transfigurator that specifies one or more 
locations within the data structure to apply to

=head1 SYNOPSIS

    Data::Transfigure::Position->new(
      position => '/*/author',
      transfigurator => Data::Transfigure::Type->new(
        type => 'Result::Person',
        handler => sub ($data) {
          sprintf("%s, %s", $data->lastname, $data->firstname)
        }
      )
    ); # applies to any 2nd-level hash key "author", but only if that value's
       # type is 'Result::Person', and then performs a custom stringification

    Data::Transfigure::Position->new(
      position => '/book/author',
      transfigurator => Data::Transfigure::Default->new(
        handler => sub ($data ) {
          {
            firstname => $data->names->{first} // '',
            lastname  => $data->names->{last} // '',
          }
        }
      )
    ); # applies only to the node at $data->{book}->{author}, and tries to 
       # hash-ify the value there, regardless of its type.

=head1 DESCRIPTION

C<Data::Transfigure::Position> is a compound transfigurator, meaning that it both is,
and has, a transfigurator. The transfigurator you give it at construction can be of 
any type, with its own handler and match criteria. The 
C<Data::Transfigure::Position>'s handler will become the one from the supplied
transfigurator, so C<handler> should not be specified when creating this 
transfigurator.

This construction is used so that transfigurators can be treated like building
blocks and in some cases inserted to apply to the entire tree, but in other
scenarios, used much more specifically.

=cut

use Object::Pad;

class Data::Transfigure::Position : does(Data::Transfigure::Node) {
  use Data::Transfigure::Constants;

=head1 FIELDS

=head2 position (required parameter)

Ex. C<"/book/author">, C<"/*/*/title">, C<"/values/0/id">

A position specifier for a location in the data structure. The forward slash
character is used to delineate levels, which are hashes or arrays. The asterisk
character can be used to represent "anything" at that level, whether hash key
or array index.

Cam be an arrayref of position specifiers to match any of them.

=head2 transfigurator (required parameter)

A C<Data::Transfigure> transfigurator conforming to the C<Data::Transfigure::Node> 
role. Weird things will happen if you provide a 
C<Data::Transfigure::Tree> -type transfigurator, so you probably shouldn't do
that.

=cut

  field $position : param;
  field $transfigurator : param;

  my sub wildcard_to_regex ($str) {
    $str =~ s|[.]|\\.|g;
    $str =~ s|[*]{2}|.*|g;
    $str =~ s|(?<![.])[*]|[^/]*|g;
    return qr/^$str$/;
  }

  sub BUILDARGS ($class, %params) {
    $class->SUPER::BUILDARGS(
      position       => $params{position},
      transfigurator => $params{transfigurator},
      handler        => sub (@args) {
        $params{transfigurator}->transfigure(@args);
      }
    );
  }

=head1 applies_to( %params )

C<$params{position}> must exist, as well as any params required by the supplied
transfigurator.

Passes C<%params> to the instance's transfigurator's C<applies_to> method - if that
results in C<$NO_MATCH>, then that value is returned by this method.

Then, the C<position(s)> is/are checked against C<$params{position}>. If 
any matches exactly, returns C<$MATCH_EXACT_POSITION>. Otherwise, if any matches
with wildcard evaluation, returns C<$MATCH_WILDCARD_POSITION>.

If no positions match, returns C<$NO_MATCH>

=cut

  method applies_to(%params) {
    die('position is a required parameter for Data::Transfigure::Position->applies_to') unless (exists($params{position}));
    my $loc = $params{position};

    my $rv       = $NO_MATCH;
    my $tf_match = $transfigurator->applies_to(%params);
    return $rv if ($tf_match == $rv);
    my @paths = ref($position) eq 'ARRAY' ? $position->@* : ($position);

  PATH: foreach (@paths) {
      return $MATCH_EXACT_POSITION | $tf_match if ($loc eq $_);
      my $re = wildcard_to_regex($_);
      $rv = $MATCH_WILDCARD_POSITION | $tf_match if ($loc =~ $re);
    }
    return $rv;
  }

}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
