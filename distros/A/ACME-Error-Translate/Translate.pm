package ACME::Error::Translate;

use strict;
no  strict 'refs';

use vars qw[$VERSION];
$VERSION = '0.01';

use Lingua::Translate;

{
  my $translator = undef;
  sub import {
    my $class = shift;
    $translator = Lingua::Translate->new( src => 'en', dest => shift );
  }

  *die_handler = *warn_handler = sub {
    if ( $translator ) {
      return map $translator->translate( $_ ), @_;
    } else {
      return @_;
    }
  };
}

1;
__END__

=head1 NAME

ACME::Error::Translate - Language Translating Backend for ACME::Error

=head1 SYNOPSIS

  use ACME::Error Translate => de;

  die "Stop!"; # Anschlag!

=head1 DESCRIPTION

Translates error messages from the default English to the language of your
choice using L<Lingua::Translate>.  As long as the backend used by
L<Lingua::Translage> understands your two letter language code, you're ok.

By default the backend is Babelfish.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 SEE ALSO

perl(1), ACME::Error, Lingua::Translate.

=cut
