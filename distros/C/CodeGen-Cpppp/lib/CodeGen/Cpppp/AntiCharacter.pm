package CodeGen::Cpppp::AntiCharacter;

our $VERSION = '0.001'; # VERSION
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

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
