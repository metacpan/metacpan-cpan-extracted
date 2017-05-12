package Acme::Scurvy::Whoreson::BilgeRat;

$VERSION = '1.0';

use strict;
use warnings;
use overload (
	'""' => \&stringify,
	fallback => 1
);

=head1 NAME

Acme::Scurvy::Whoreson::BilgeRat - multi-lingual insult generator

=head1 SYNOPSIS

  use Acme::Scurvy::Whoreson::BilgeRat;
  
  my $insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new(
    language => 'pirate'
  );
  
  print $insultgenerator; # prints a piratical insult

=head1 DESCRIPTION

A multi-lingual insult generator, which takes pluggable backends to
generate insults in the language of your choice, written in honour of
International Talk Like A Pirate Day on Sept 19th 2003
L<http://www.talklikeapirate.com/>.  An example backend is provided
which implements the 'pirate' language.

Usage is very simple.  Instantiate an Acme::Scurvy::Whoreson::BilgeRat
object, passing a single named parameter - 'language' - to the constructor.
This tells it to use the A::S::W::B::Backend::[language] plugin module.
If that is missing, we assume you want the 'pirate' backend.

To generate an insult, simply mention your object in any place where it
will be turned into a string.  It uses the AWESOME POWER of operator
overloading to achieve this heroic feat.

=cut

sub new {
	my($class, %params, $backend) = @_;
	
	die("Read the fucking manual you shitwit and at least use the constructor right!")
	  if(!$class || join('', keys %params) !~ /^(language)?$/);
	
	$params{language} ||= 'pirate';
	
	eval "
		use Acme::Scurvy::Whoreson::BilgeRat::Backend::$params{language};
	";
	$@ && die("Bollocks! I can't find a language backend for '$params{language}'");
	
	$backend = "Acme::Scurvy::Whoreson::BilgeRat::Backend::$params{language}"->new();
	($backend && $backend->isa("Acme::Scurvy::Whoreson::BilgeRat::Backend::$params{language}")) ||
		die("For fuck's sake, the fucking backend's fucked");

	$backend;
}

sub stringify {
	my $self = shift;
	$self->generateinsult();
}

sub generateinsult {
	my($self, %usedwords, $insult) = (shift);
	foreach my $element (split(//, $self->{grammars}->[rand @{$self->{grammars}}])) {
		my $word = '';
		my $counter = 0;
		while(!$word || $usedwords{$word}) {
			$word = (uc $element eq 'N') ? $self->{nouns}->[rand @{$self->{nouns}}] :
				(uc$ element eq 'A') ? $self->{adjectives}->[rand @{$self->{adjectives}}] :
				die("The dickhead who wrote your backend fucked up");
			return '' if(++$counter == 100);
		}
		$usedwords{$word} = 1;
		$insult .= (($insult) ? ' ' : '').$word;
	}
	$insult;
}

=head1 PLUGINS

So, on to the most complex part of all this, which thankfully isn't that
complex.

To create a plugin, you create a bog-standard module, whose name is
Acme::Scurvy::Whoreson::BilgeRat::Backend::[your language name].  It should
be a subclass of A::S::W::B.  The constructor should return a blessed
object and must be called new().  You then have two options:

=over 4

=item use the built-in insult generator

In this case, you simply need to define a suitable grammar and list of
words to generate insults from.  You do this by having new() return
a blessed hashref with the following keys:

=over 4

=item grammars

A reference to a list of strings, each of which is a grammar describing a
valid way of constructing an insult, and may consist of the letters
'A' and 'N'.  A grammar is chosen at random when we generate an insult.
For each part of the grammar, a random adjective is chosen for each 'A' and
a random noun is chosen for each 'N'.

=item nouns

A list of nouns.

=item adjectives

A list of adjectives.

=back

You may have words appearing in both the nouns and the adjectives lists.
The default insult generator will ensure that it never uses the same word
twice in any one insult.  Of course, there are some situations where there
are simply not enough nouns or adjectives in the grammar, in which case
an empty insult is generated.

=item supply your own insult generator

In many cases, the default insult generator won't be sufficient for your
language, as you may need to decline your nouns and adjectives or do other
weird and wonderful manipulations.  In this case, you need to override the
generateinsult() method.  This is a bog-standard method, which will be
called with exactly one parameter - a reference to the object.  You must
return a string from this method.  How you generate that string is entirely
up to you, and you may need to do something different from what I have
described above in the constructor.  The only limitation on the constructor
for a backend is that it *must* return something that inherits from A::S::W::B,
and it will not be supplied with any parameters at all other than its own
class name.

=back

See the A::S::W::B::Backend::pirate module for an example.

=head1 BUGS

No bugs are known, but if you find any please let me know, and send a test
case and - if possible - a patch.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism.  And,
while this is free software (both free-as-in-beer and free-as-in-speech) I
also welcome payment.  In particular, your bug reports will get moved to
the front of the queue if you buy me something from my wishlist, which can
be found at L<http://www.cantrell.org.uk/david/shopping-list/wishlist>.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT

Copyright 2003 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

1;
