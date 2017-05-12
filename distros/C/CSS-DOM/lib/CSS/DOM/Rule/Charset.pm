package CSS::DOM::Rule::Charset;

$VERSION = '0.16';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

use CSS::DOM::Util 'escape';
 use        CSS::DOM::Rule;

our @ISA = 'CSS::DOM::Rule';

use constant # Don't let this conflict with the superclass.
	cset => 2;
{ no strict 'refs'; delete ${__PACKAGE__.'::'}{cset} }

# overrides:

sub type { CSS::DOM::Rule::CHARSET_RULE }
sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		$old = "\@charset \""
			. escape($self->[cset],'"') ."\";\n";
	}
	if (@_) {
		require CSS::DOM::Parser;
		my $new_rule  =  $self->_parse(shift);
		@$self[cset] = @$new_rule[cset];
	}
	$old;
};


# CSSCharsetRule interface:

sub encoding {
	my $old = (my $self = shift)->[cset];
	@_ and $$self[cset] = shift;
	$old
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Rule::FontFace - CSS @font-face rule class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM;
  my $font_face_rule = CSS::DOM->parse(
      '@font-face { font-family: "bm"; src: url(blackmoor.ttf) }'
  )->cssRules->[0];

  $page_rule->style;        # a CSS::DOM::Style object
  $page_rule->style->src;   # 'url(blackmoor.ttf)'

=head1 DESCRIPTION

This module implements CSS @font-face rules for L<CSS::DOM>. It inherits 
from
L<CSS::DOM::Rule> and implements
the CSSFontFaceRule DOM interface.

=head1 THE METHOD

=over 4

=item style

Returns the CSS::DOM::Style object representing the declaration block
of this rule.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Style>

L<CSS::DOM::Rule>
