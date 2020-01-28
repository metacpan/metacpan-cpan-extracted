package Data::Perl::Role::String;
$Data::Perl::Role::String::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl scalar strings.

use strictures 1;

use Role::Tiny;

sub new { bless \(my $s = $_[1]), $_[0] }

sub inc { ++${$_[0]} }

sub append { ${$_[0]} = ${$_[0]} . $_[1] }

sub prepend { ${$_[0]} = $_[1] . ${$_[0]} }

sub replace {
  if (ref($_[2]) eq 'CODE') {
    ${$_[0]} =~ s/$_[1]/$_[2]->()/e;
  }
  else {
    ${$_[0]} =~ s/$_[1]/$_[2]/;
  }
  ${$_[0]};
}

sub match {
  ${$_[0]} =~ /$_[1]/;
}

sub chop { CORE::chop ${$_[0]} }

sub chomp { CORE::chomp ${$_[0]} }

sub clear { ${$_[0]} = '' }

sub length { CORE::length ${$_[0]} }

sub substr {
  if (@_ >= 4) {
    substr ${$_[0]}, $_[1], $_[2], $_[3];
  }
  elsif (@_ == 3) {
    substr ${$_[0]}, $_[1], $_[2];
  }
  else {
    substr ${$_[0]}, $_[1];
  }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::String - Wrapping class for Perl scalar strings.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/string/;

  my $string = string("foo\n");

  $string->chomp; # returns 1, $string == "foo"

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with scalar strings.

=head1 PROVIDED METHODS

=over 4

=item * B<new($value)>

Constructs a new Data::Perl::String object, optionally initialized to $value if
passed in, and returns it.

=item * B<inc>

Increments the value stored in this slot using the magical string autoincrement
operator. Note that Perl doesn't provide analogous behavior in C<-->, so
C<dec> is not available. This method returns the new value.

This method does not accept any arguments.

=item * B<append($string)>

Appends to the string, like C<.=>, and returns the new value.

This method requires a single argument.

=item * B<prepend($string)>

Prepends to the string and returns the new value.

This method requires a single argument.

=item * B<replace($pattern, $replacement)>

Performs a regexp substitution (L<perlop/s>). There is no way to provide the
C<g> flag, but code references will be accepted for the replacement, causing
the regex to be modified with a single C<e>. C</smxi> can be applied using the
C<qr> operator. This method returns the new value.

This method requires two arguments.

=item * B<match($pattern)>

Runs the regex against the string and returns the matching value(s).

This method requires a single argument.

=item * B<chop>

Just like L<perlfunc/chop>. This method returns the chopped character.

This method does not accept any arguments.

=item * B<chomp>

Just like L<perlfunc/chomp>. This method returns the number of characters
removed.

This method does not accept any arguments.

=item * B<clear>

Sets the string to the empty string (not the value passed to C<default>).

This method does not have a defined return value.

This method does not accept any arguments.

=item * B<length>

Just like L<perlfunc/length>, returns the length of the string.

=item * B<substr>

This acts just like L<perlfunc/substr>. When called as a writer, it returns
the substring that was replaced, just like the Perl builtin.

This method requires at least one argument, and accepts no more than three.

=back

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<MooX::HandlesVia>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

