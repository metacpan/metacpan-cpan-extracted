package CSS::DOM::Rule::Page;

$VERSION = '0.17';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

use CSS::DOM::Exception qw/ SYNTAX_ERR /;
 use        CSS::DOM::Rule;

our @ISA = 'CSS::DOM::Rule';

use constant 1.03 our $_const = {
# Don't let this conflict with the superclass.
	styl => 2,
	selc => 3,
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

# overrides:

sub type { CSS::DOM::Rule::PAGE_RULE }
sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		$old = "$self->[selc] { "
			. $self->[styl]->cssText ." }\n";
	}
	if (@_) {
		require CSS::DOM::Parser;
		my $new_rule  =  $self->_parse(shift);
		@$self[styl,selc] = @$new_rule[styl,selc];
	}
	$old;
};


# CSSPageRule interface:

sub selectorText {	
	my $old = (my $self = shift)->[selc];
	if(@_){
		# ~~~ I need to make this use the parser’s tokenise func.
		#    need tests as well; this shouldn’t accept anything
		#    that would make it technically an unknown rule.
		(my $sel = shift) =~ 
		    /^[ \t\r\n\f]*\@page(?![_a-z\200-\377]|\\[^\r\n\f])/
		or die CSS::DOM::Exception->new(SYNTAX_ERR,
			'@page selectors must begin with "@page"');
		$self->[selc] = $sel ;
	}
	$old;
}

# ~~~ Do we need this?
#sub _set_selector_tokens {
#	
#}

sub style {
	$_[0]->[styl] ||= do {
		require CSS::DOM::Style;
		new CSS::DOM::Style shift
	};
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Rule::Page - CSS @page rule class for CSS::DOM

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

  use CSS::DOM;
  my $page_rule = CSS::DOM->parse(
      '@page :first { stuff: other stuff }'
  )->cssRules->[0];

  $page_rule->selectorText; # '@page :first'
  $page_rule->style;        # a CSS::DOM::Style object
  $page_rule->style->stuff; # 'other stuff'

=head1 DESCRIPTION

This module implements CSS @page rules for L<CSS::DOM>. It inherits 
from
L<CSS::DOM::Rule> and implements
the CSSPageRule DOM interface.

=head1 METHODS

=over 4

=item selectorText

Returns a string representing the selector(s). Pass an argument to set it.

=item style

Returns the CSS::DOM::Style object representing the declaration block
of this rule.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Style>

L<CSS::DOM::Rule>
