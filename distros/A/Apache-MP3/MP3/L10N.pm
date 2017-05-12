
use strict;
package Apache::MP3::L10N;
use Locale::Maketext;

require Apache::MP3::L10N::Aliases;

use vars qw(@ISA %Lexicon $VERSION);

@ISA = ('Locale::Maketext');
%Lexicon = (
  _AUTO => 1,
 '_VERSION' => __PACKAGE__ . ' v' . 
 ($VERSION=   '20020601'), # Last modified

 "_CREDITS_before_author" => "Apache::MP3 was written by ",
 "_CREDITS_author" =>        "Lincoln D. Stein",
 "_CREDITS_after_author" =>  ".",
 
);

sub encoding { "iso-8859-1" }   # Latin-1
  # Override as necessary if you use a different encoding

# Things overridden in RightToLeft.pm:
sub left      { 'left'  }
sub right     { 'right' }
sub direction { 'ltr'   }

sub must_escape { $_[0]{'must_escape'} || '' }
  # don't override that unless you know what you're doing.

1;
__END__

=head1 NAME

Apache::MP3::L10N - base class for Apache::MP3 interface localization

=head1 SYNOPSIS

  [nil]

=head1 DESCRIPTION

This module is the base class for generating language handles (via
L<Locale::Maketext>) which L<Apache::MP3> (and subclasses) use for
presenting their interface.

To localize this for your language of choice, see the source for
C<Apache/L10N/fr.pm> for an example lexicon that should contain
all the English phrases, and an example French translation.

For example, if you're localizing this to Swahili, you'd copy
C<Apache/L10N/fr.pm> to C<Apache/L10N/sw.pm> (since
L<I18N::LangTags::List> tells us that C<sw> is the language tag
for Swahili), and change its C<package Apache::MP3::L10N::fr;>
line to C<package Apache::MP3::L10N::sw;>, and then you'd replace
all the French phrases that are the values in C<%Lexicon> with
Swahili phrases.

For example, you'd change:

 'fetch'  => 'sauvegarder',

to:

 'fetch'  => 'lete',

if you considered "lete" (from the infinitive "kuleta", I<haul>)
to be a good translation of the English "fetch" in that context.

Email me (Sean) if you have any questions.

=head1 SEE ALSO

L<Apache::MP3>, L<Locale::Maketext>

=head1 AUTHOR

Copyright 2002, Sean M. Burke E<lt>sburkeE<64>cpan.orgE<gt>

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=cut

# "Try to make things that can become better in other people's
# minds than they were in yours."
#  -- Brian Eno, /Year with Swollen Appendices/, p165

