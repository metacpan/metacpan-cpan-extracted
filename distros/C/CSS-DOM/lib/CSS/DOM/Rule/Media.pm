package CSS::DOM::Rule::Media;

$VERSION = '0.16';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

use CSS::DOM;
use CSS::DOM::Exception qw/ SYNTAX_ERR INDEX_SIZE_ERR /;
 use        CSS::DOM::Rule;

our @ISA = 'CSS::DOM::Rule';

use constant 1.03 our $_const = {
# Don't let this conflict with the superclass.
	ruls => 2,
	medi => 3,
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

# overrides:
sub type { CSS::DOM::Rule::MEDIA_RULE }
sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		$old = '@media ' . (
			$self->[medi] ? $self->[medi]->mediaText : ''
		) . " {\n";
		(my $rules = join '',map $_->cssText, @{$self->[ruls]||[]})
			=~ s/^(?!$)/\t/gm;
		$old .= "$rules}\n";
	}
	if (@_) {
		my $new_rule  =  $self->_parse(shift);
		@$self[ruls,medi] = @$new_rule[ruls,medi];
	}
	$old;
};


# CSSMediaRule interface:

# These methods are identical to those in CSS::DOM, but we’ve had to copy &
# paste them here, because the constants have different values. Even if we
# were to change them to have the same values, it would be a maintenance
# nightmare.

sub media {
	wantarray ? @{$_[0]->[medi]||return} :
		($_[0]->[medi] ||= (
			require CSS::DOM::MediaList,
			CSS::DOM::MediaList->new
		))
}

sub cssRules { 
	wantarray
		? @{shift->[ruls]||return}
		: (shift->[ruls]||=new CSS::DOM::RuleList);
}

sub insertRule { # This is supposed to raise an HIERARCHY_REQUEST_ERR if
                 # the rule cannot be inserted at the specified  index;
                 # e.g.,  if an  @import  rule is inserted after a stan-
                 # dard rule. But we don’t do that, in order to maintain
                 # future compatibility.
	my ($self, $rule_string, $index) = @_;
	
	require CSS::DOM::Parser;
	my ($at,$rule);
	{
		local *@;
		$rule = CSS::DOM::Parser::parse_statement($rule_string);
		$at = $@
	}
	$at and die new CSS::DOM::Exception SYNTAX_ERR, $at;

	$rule->_set_parentStyleSheet($self->parentStyleSheet);
	$rule->_set_parentRule($self);

	my $list = $self->cssRules; # cssRules takes care of ||=
	splice @$list, $index, 0, $rule;

	$index < 0        ? $#$list + $index :
	$index <= $#$list ? $index           :
	                    $#$list
}

sub deleteRule {
	my ($self,$index) = @_;
	my $list = $self->[ruls];
	$index > $#$list and die CSS::DOM::Exception->new(
		INDEX_SIZE_ERR,
		"The index passed to deleteRule ($index) is too large"
	);
	splice @$list, $index, 1;
	return # nothing;
}

sub _set_parentStyleSheet {
	my $self = shift;
	$self->SUPER::_set_parentStyleSheet(@_);
	$_->_set_parentStyleSheet(@_) for @{$self->[ruls]};
}

                              !()__END__()!

=head1 NAME

CSS::DOM::Rule::Media - CSS @media rule class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM;
  my $media_rule = CSS::DOM->parse(
      '@media print { body { background: none } }'
  )->cssRules->[0];

  # OR:
  use CSS::DOM::Rule::Media;
  my $media_rule = new CSS::DOM::Rule::Media $parent;
  push @{$media_rule->media}, 'print';
  $media_rule->insertRule('body { background: none }')

=head1 DESCRIPTION

This module implements CSS C<@media> rules for L<CSS::DOM>. It inherits 
from
L<CSS::DOM::Rule> and implements
the CSSMediaRule DOM interface.

=head1 METHODS

=over 4

=item media

Returns the MediaList associated with the @media rule (or a plain list in
list context). This defaults to an
empty list. You can pass a comma-delimited string to the MediaList's
C<mediaText> method to set it.

=item cssRules

In scalar context, this returns a L<CSS::DOM::RuleList> object (simply a
blessed
array reference) of L<CSS::DOM::Rule> objects. In list context it returns a
list.

=item insertRule ( $css_code, $index )

Parses the rule contained in the C<$css_code>, inserting it the @media
rule's list of subrules at the given C<$index>.

=item deleteRule ( $index )

Deletes the rule at the given C<$index>.

=back

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Rule>

L<CSS::DOM::MediaList>
