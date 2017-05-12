use 5.12.0;
use warnings;

package Data::TagHive;
{
  $Data::TagHive::VERSION = '0.003';
}
# ABSTRACT: hierarchical tags with values

use Carp;


sub new {
  my ($class) = @_;

  return bless { state => {} } => $class;
}

my $tagname_re  = qr{ [a-z] [-a-z0-9_]* }x;
my $tagvalue_re = qr{ [-a-z0-9_]+ }x;
my $tagpair_re  = qr{ $tagname_re (?::$tagvalue_re)? }x;
my $tagstr_re   = qr{ \A $tagpair_re (?:\.$tagpair_re)* \z }x;

sub _assert_tagstr {
  my ($self, $tagstr) = @_;
  croak "invalid tagstr <$tagstr>" unless $tagstr =~ $tagstr_re;
}

sub _tag_pairs {
  my ($self, $tagstr) = @_;

  $self->_assert_tagstr($tagstr);

  my @tags = map { my @pair = split /:/, $_; $#pair = 1; \@pair }
             split /\./, $tagstr;

  return @tags;
}

sub __differ {
  my ($x, $y) = @_;

  return 1 if defined $x xor defined $y;
  return unless defined $x;

  return $x ne $y;
}


sub add_tag {
  my ($self, $tagstr) = @_;

  my $state = $self->{state};

  my @tags  = $self->all_tags;
  my @pairs = $self->_tag_pairs($tagstr);

  my $stem = '';

  while (my $pair = shift @pairs) {
    $stem .= '.' if length $stem;

    my $key   = $stem . $pair->[0];
    my $value = length($pair->[1]) ? $pair->[1] : undef;

    CONFLICT: {
      if (exists $state->{ $key }) {
        my $existing = $state->{ $key };

        # Easiest cases: if they're both undef, or are eq, no conflict.
        last CONFLICT unless __differ($value, $existing);

        # Easist conflict case: we want to set tag:value1 but tag:value2 is
        # already set.  No matter whether there are descendants on either side,
        # this is a
        # conflict.
        croak "can't add <$tagstr> to taghive; conflict at $key"
          if defined $value and defined $existing and $value ne $existing;

        my $more_to_set = defined($value)         || @pairs;
        my $more_exists = defined($state->{$key}) || grep { /\A\Q$key./ } @tags;

        croak "can't add <$tagstr> to taghive; conflict at $key"
          if $more_to_set and $more_exists;
      }
    }


    $state->{ $key } = $value;

    $stem = defined $value ? "$key:$value" : $key;

    $state->{$stem} = undef;
  }
}


sub has_tag {
  my ($self, $tagstr) = @_;

  my $state = $self->{state};

  $self->_assert_tagstr($tagstr);
  return 1 if exists $state->{$tagstr};
  return;
}


sub delete_tag {
  my ($self, $tagstr) = @_;

  $self->_assert_tagstr($tagstr);

  my $state = $self->{state};
  my @keys  = grep { /\A$tagstr(?:$|[.:])/ } keys %$state;
  delete @$state{ @keys };

  if ($tagstr =~ s/:($tagvalue_re)\z//) {
    delete $state->{ $tagstr } if $state->{$tagstr} // '' eq $1;
  }
}


sub all_tags {
  my ($self) = @_;
  return keys %{ $self->{state} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagHive - hierarchical tags with values

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Data::TagHive;

  my $taghive = Data::TagHive->new;

  $taghive->add_tag('book.topic:programming');

  $taghive->has_tag('book'); # TRUE

=head1 OVERVIEW

Data::TagHive is the bizarre, corrupted union of L<String::TagString> and
L<Data::Hive>.  It combines the "simple list of strings" of the former with the
"hierarchical key-value/value pairs" of the latter, using a different interface
from either.

It's probably better than that sounds, though.

A Data::TagHive object represents a set of tags.  Each tag is a string that
represents a structure of nested key-value pairs.  For example, a library book
might be tagged:

  book.pages.size:letter
  book.pages.count:180
  book.type:hardcover
  book.topic:programming.perl.cpan

Each tag is a set of key-value pairs.  Later pairs are qualified by earlier
pairs.  Values are optional.  Keys and values are separated by colons.
Key-value pairs are separated by dots.

A tag is considered present if it was set explicitly or if any more-specific
subtag of it was set.  For example, if we had explicitly added all the tags
shown above, a tag hive would then report true if asked whether each of the
following tags were set:

  book
  book.pages
  book.pages.size
  book.pages.size:letter
  book.pages.count
  book.pages.count:180
  book.type
  book.type:hardcover
  book.topic
  book.topic:programming
  book.topic:programming.perl
  book.topic:programming.perl.cpan

=head1 METHODS

=head2 add_tag

  $taghive->add_tag( $tagstr );

This method adds the given tag (given as a string) to the hive.  It will fail
if there are conflicts.  For example, if "foo:bar" is already set, "foo:xyz"
cannot be set.  Each tag can only have one value.

Tags without values may be given values through C<add_tag>, but only if they
have no tags beneath them.  For example, given a tag hive with "foo.bar"
tagged, "foo.bar:baz" could be added, but not "foo:baz"

=head2 has_tag

  if ($taghive->has_tag( $tagstr )) { ... }

This method returns true if the tag hive has the tag.

=head2 delete_tag

  $taghive->delete_tag( $tagstr );

This method deletes the tag from the hive, along with any tags below it.

If your hive has "foo.bar:xyz.abc" and you C<delete_tag> "foo.bar" it will be
left with nothing but the tag "foo"

=head2 all_tags

This method returns, as a list of strings, all the tags set on the hive either
explicitly or implicitly.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
