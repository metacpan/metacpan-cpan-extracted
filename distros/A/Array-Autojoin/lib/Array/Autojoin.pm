
require 5;
package Array::Autojoin;
use strict;
use vars qw($VERSION @ISA @EXPORT);
# Time-stamp: "2004-12-29 19:47:36 AST"
$VERSION = '0.03';
require Exporter;
@ISA = ('Exporter');
@EXPORT = ('mkarray');

sub mkarray { bless [@_], 'Array::Autojoin::X' }

{
  # And then the class for that:

  package Array::Autojoin::X;

  # TODO: Hmm, methods for *=, +=, etc?

  use overload(

    '""' => sub {    join ', ', @{$_[0]}},

    '0+' => sub {0 + ( $_[0][0] || 0  ) },
     # stringifies and then just numerifies, but feh.

    'fallback' => 1,  # turn on cleverness

    'bool', => sub {  # true iff there's any true items in it
      for (@{$_[0]}) { return 1 if $_ };
      return '';
    },

    '.=' => sub {  # sure, why not.
      if(@{$_[0]}) { $_[0][-1] .= $_[1] } else { push @{$_[0]}, $_[1] }
      $_[0];
    },  # but can't overload ||= or the like

  );
}

1;

__END__

=head1 NAME

Array::Autojoin -- arrayrefs that stringify as join(", ", @$it)

=head1 SYNOPSIS

  use Array::Autojoin;
  my $headword = "biscocho";
  my $gloss = mkarray("cookie", "biscuit");
  print "$headword\: $gloss.\n";
  
   # Prints "biscocho: cookie, biscuit.\n";

=head1 DESCRIPTION

This extremely short and simple module provides one exported function,
C<mkarray( ...items... )>, which makes an arrayref (containing those
items) belonging to a class that does nothing other than specifying
to Perl that when you want the string value of that arrayref, instead
of giving something like "ARRAY(0x171568f)", it returns a happy
string consisting of C<join(', ', @$arrayref)>.

Also, rather incidentally:

* In boolean context (like C<print "Yow!" if $arrayref>), the
boolean value is true iff the reference is to an array containing
at least one boolean-true value.  So:

  mkarray()            is boolean-false -- no values at all
  mkarray('','','','') is boolean-false -- no values are true
  mkarray('',0,undef ) is boolean-false -- no values are true
  mkarray('', 123    ) is boolean-true -- there's a true value (123)
  mkarray("PIE"      ) is boolean-true -- there's a true value ("PIE")

* In numeric scalar context -- where C<join(', ', @$arrayref)> would be
unhelpful -- you get the numeric value of the first item (or zero
if there's no items):

  my $z = mkarray(3,7,19,63,30);
  print 39 + $z;   # numeric $z yields 3, so this prints 42

* ".=" is overloaded to append to the last element (or in the case
of an empty array, to create a new element):

  my $headword = "biscocho";
  my $gloss = mkarray("cookie", "biscuit");
  $headword .= "!";
  $gloss    .= "!";
  
  print "$headword\: $gloss\n";
   # Prints "biscocho!: cookie, biscuit!\n"

  push @$gloss, "hooboy";
   # see, can still treat it like a normal array ref

  printf "Count of glosses: %d\n", scalar(@$gloss);
   # Prints:  Count of glosses: 3

  print "Gloss bits: ", map("<$_> ", @$gloss), "\n";
   # Prints:  Gloss bits: <cookie> <biscuit!> <hooboy> 

=head1 NOTES

* If you want to know how this class works, look at its source, and cf.
L<the "overload" man page|overload>.

* If you want a class that works sort of like this one, but different, then
feel free to make your own, using this class as a model.

* Remember, once you stringify something, it's not an object anymore!

  use strict;
  my $gloss = mkarray("cookie", "biscuit");
  $gloss = "<" . $gloss . ">";
   # and shazam, it's stringified, and the string gotten from
   #  putting "<" and ">" around it, is put back into $gloss,
   #  replacing the arrayref.
  print "It's $gloss!\n";
   # It's <cookie, biscuit>!
  printf "Count of glosses: %d\n", scalar(@$gloss);
   # DIES with:  Can't use string ("<cookie, biscuit>") as an ARRAY
   #              ref while "strict refs" in use [at ...]

=head1 SEE ALSO

L<overload>, L<Data::MultiValuedHash>

=head1 COPYRIGHT

Copyright 2001 Sean M. Burke.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

 # So there

