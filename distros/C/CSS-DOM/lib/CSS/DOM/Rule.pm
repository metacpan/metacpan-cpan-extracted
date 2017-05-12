package CSS::DOM::Rule;

$VERSION = '0.16';

use warnings;
use strict;

use Carp 'croak';
use CSS::DOM::Constants;
use CSS::DOM::Exception qw/ SYNTAX_ERR INVALID_MODIFICATION_ERR /;
use Exporter 5.57 'import';
use Scalar::Util 'weaken';

*EXPORT_OK = $CSS::DOM::Constants::EXPORT_TAGS{rule};
our %EXPORT_TAGS = (all => \our @EXPORT_OK);

use constant 1.03 our $_const = {
# Don’t let these conflict with subclasses!
	prnt => 0,
	shet => 1,
	typs => 2, # token types   These two are not used by subclassed,
	tokn => 3, # tokens        so there’s no chance of a conflict.
};
{ no strict; delete @{__PACKAGE__.'::'}{_const => keys %{our $_const}} }

sub new {
	my $self = bless[],shift;
	my $parent = shift || return $self;
	if($parent->isa('CSS::DOM::Rule')) {
		weaken($$self[shet] = $parent->parentStyleSheet);
		weaken($$self[prnt] = $parent);
	}
	else {
		weaken($$self[shet] = $parent)
	}
	$self;
}

sub type { UNKNOWN_RULE }

# This is used by cssText, both this class’s and subclasses’:
sub _parse { # This method parses the code passed to it and checks to see
             # whether the retval is the same class as  $self,  throwing
             # errors as appropriate.  It returns the new rule resulting
             # from the parse. Each subclass is responsible for extorting
             # the rule data from the new rule.
	my $self = shift;
	require CSS::DOM::Parser;
	my $new_rule  =  CSS::DOM::Parser'parse_statement(shift)
		|| die CSS::DOM::Exception->new(SYNTAX_ERR, $@);

	ref $new_rule eq ref $self or die CSS::DOM::Exception->new(
		INVALID_MODIFICATION_ERR,
		"The rule cannot be converted to a different type."
	);
	$new_rule;
};

sub cssText {
	my $self = shift;
	my $old;
	if(defined wantarray) {
		$old = join '', @{$self->[tokn]},;
		$old .= ';' unless $self->[typs] =~ /[;}]\z/;
		$old .= "\n";
	}
	if (@_) {
		my $new_rule  =  $self->_parse(shift);
		@$self[typs,tokn] = @$new_rule[typs,tokn];
	}
	$old;
};


sub parentStyleSheet { shift->[shet]||() }
sub parentRule       { shift->[prnt]||() }

sub _set_parentStyleSheet { weaken(shift->[shet] = pop) }
sub _set_parentRule       { weaken(shift->[prnt] = pop) }

sub _set_tokens { @{+shift}[typs,tokn] = @_[1,2]; }
  
                              !()__END__()!

=head1 NAME

CSS::DOM::Rule - CSS rule class for CSS::DOM

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

  use CSS::DOM::Rule ':all'; # import constants

  use CSS::DOM;
  $sheet = new CSS::DOM;
  $sheet->insertRule('bla blah blah {}');
  $rule = $sheet->cssRules->[0];
  
  $rule->type; # STYLE_RULE
  $rule->cssText; # 'bla blah blah {}' or similar
  $rule->cssText('p { margin: 0 }'); # replace it
  $rule->parentStyleSheet; # $sheet

=head1 DESCRIPTION

This module provides the CSS rule class for L<CSS::DOM>. It implements
the CSSRule and CSSUnknownRule DOM interfaces.

=head1 METHODS

=head2 Constructor

Only call the constructor on this class to create an 'unknown' rule. You have to
call the constructor on a particular subclass to get another type. Normally
you do not need to 
call this directly anyway. (See L<CSS::DOM>'s 
C<parse> and C<insertRule> methods.) But just in case you do want to call 
it, here it
is:

  new CSS::DOM::Rule $parent; # unknown rule
  
  require CSS::DOM::Rule::Style
  new CSS::DOM::Rule::Style $parent;
  # etc.

C<$parent> is the parent rule, if the rule is nested, or the parent style
sheet otherwise.

=head2 Object Methods

=over 4

=item type

Returns one of the constants below indicating the type of rule.

=item cssText

Returns this rule's CSS code. If you pass an argument, it will be parsed as
the new CSS code for this rule (replacing the existing data), and the old
value will be returned. This method will die if the replacement CSS code
creates a different type of rule.

=item parentStyleSheet

This returns the style sheet to which the rule belongs.

=item parentRule

This returns the rule's parent rule, if there is one, or an empty list
otherwise. There is only a parent rule if this one is nested, e.g., inside
a media rule.

=back

=head1 EXPORTS

The following constants that indicate the type of rule will be exported on
request (individually or with the ':all' tag):

  UNKNOWN_RULE
  STYLE_RULE    
  CHARSET_RULE  
  IMPORT_RULE   
  MEDIA_RULE    
  FONT_FACE_RULE
  PAGE_RULE

=head1 SEE ALSO

L<CSS::DOM>

L<CSS::DOM::Rule::Style>

L<CSS::DOM::Rule::Media>

L<CSS::DOM::Rule::Page>

L<CSS::DOM::Rule::Import>
