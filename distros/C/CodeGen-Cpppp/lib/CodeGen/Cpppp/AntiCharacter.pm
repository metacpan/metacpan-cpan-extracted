package CodeGen::Cpppp::AntiCharacter;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: AntiCharacters combine with characters to produce nothing

use v5.20;
use warnings;
use Carp;
use overload
   '.' => \&concat,
   '""' => sub { $_[0][2] };


sub new {
   my ($class, $negate, $skip)= @_;
   $skip //= '';
   ref $negate eq 'Regexp' or croak "Expected qr// for negation argument";
   bless [ $negate, $skip, '' ], $class;
}

sub concat {
   my ($negate, $skip, $suffix)= @{$_[0]};
   if ($_[2]) { # $string . $anticharacter; perform character destruction
      my $tmp= $_[1];
      # does this entire string consist of 'skip' pattern?  If so, need to
      # try again later.
      if (!length $tmp || $tmp =~ /^$skip\Z/) {
         return bless [ $negate, $skip, $tmp . $suffix ], ref $_[0];
      }
      # Does it match the pattern we're trying to cancel?
      if ($tmp =~ /($negate)$skip\Z/) {
         substr($tmp, $-[1], $+[1] - $-[1], '');
         # Did it run into the start of the string, and could it cancel more?
         if ($-[1] == 0
            && (substr($_[1],0,1) . $_[1]) =~ /^($negate)$skip\Z/
         ) {
            return bless [ $negate, $skip, $tmp . $suffix ], ref $_[0];
         }
      }
      return $tmp . $suffix;
   }
   else { # $anticharacter . $string; carry suffix for later
      return bless [ $negate, $skip, $suffix . $_[1] ], ref $_[0];
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Cpppp::AntiCharacter - AntiCharacters combine with characters to produce nothing

=head1 SYNOPSIS

  my $anticomma= CodeGen::Cpppp::AntiCharacter->new(qr/,/);
  say '1,2,3,' . $anticomma;  # 1,2,3\n
  say '1,2,3' . $anticomma;   # 1,2,3\n
  
  my $antiword= CodeGen::Cpppp::AntiCharacter->new(qr/\w+/);
  say "apple,bananna" . $antiword; # apple,\n
  
  # skip over whitespace, but preserve the whitespace
  my $anticomma= CodeGen::Cpppp::AntiCharacter->new(qr/,/, qr/\s*/);
  say "1,2,\n  " . $anticomma;  # "1,2\n  \n"

=head1 DESCRIPTION

Anticharacter is an object that eliminates characters at the end of a string
when it is concatenated to that string.  It has an optional second parameter
of characters to ignore while looking for the characters to remove.

If the concatenation does not remove all of the target characters, the
concatenation returns another object which can continue the hunt.

Anticharacters do not work with C<join>, only with regular concatenation.
Stringifying an anticharacter ends the search and returns a simple string
of anything that had accumulated during the search for the characters to remove.

=head1 CONSTRUCTOR

=head2 new

  $antichar= $class->new( $negate_regex, $skip_regex = undef );

Return a new AntiCharacter object.  The C<$negate_regex> is required, and should
be the pattern you want to find on the end of a string as if you had written

    s/$negate_regex\Z//

The optional C<$skip_regex> is a pattern to ignore, as if you had written

    s/$negate_regex($skip_regex)\Z/$1/

=head1 METHODS

=head2 concat

This is the method invoked when an AntiCharacter is concatenated with anything else.

  $maybe_antichar= $antichar->concat( $other_thing, $reverse );

If reverse is false, meaning C<$other_thing> is being appended to the antichar,
the result is a new AntiCharacter with that string as an additional suffix.

If reverse is true, meaning C<$other_thing> is a prefix of the AntiCharacter,
this checks to see if the C<$negate_regex> can be applied and I<does not> reach
the start of the string, meaning it has negated exactly what it was supposed to.
In that case it returns a plain string.  If the entire string would be consumed,
it returns another anticharacter in case further concatenations find a larger
match to remove.  If the negate pattern does not match, this returns a plain
string assuming the anticharacter will never match.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.005

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
