package CSS::Struct::Output::Indent::ANSIColor;

use base qw(CSS::Struct::Output::Indent);
use strict;
use warnings;

use Indent;
use Readonly;
use Term::ANSIColor;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $SPACE => q{ };

our $CSS_COMMENT = 'r064g085b107';
our $CSS_SELECTOR_ELEMENT = 'red';
our $CSS_SELECTOR_CLASS = 'r255g156b000';
our $CSS_SELECTOR_ID = 'r255g156b000';
our $CSS_AT_RULE_KEYWORD = 'r255g156b000';
our $CSS_AT_RULE_VALUE = 'yellow';
our $CSS_DEFINITION_KEY = 'green';
our $CSS_DEFINITION_KEY_PREFIX = 'blue';
our $CSS_DEFINITION_VALUE_NUMBER = 'red';
our $CSS_DEFINITION_VALUE_STRING = 'blue';

our $VERSION = 0.02;

# At-rules.
sub _put_at_rules {
	my ($self, $at_rule, $value) = @_;
	push @{$self->{'flush_code'}}, color($CSS_AT_RULE_KEYWORD).$at_rule.color('reset').
		' "'.color($CSS_AT_RULE_VALUE).$value.color('reset').'";';
	$self->{'processed'} = 1;
	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;
	if (! $self->{'skip_comments'}) {
		push @comments, $SPACE.$self->{'comment_delimeters'}->[1];
		unshift @comments, $self->{'comment_delimeters'}->[0].$SPACE;
		if ($self->{'processed'}) {
			push @{$self->{'flush_code'}}, $EMPTY_STR;
		}
		my $comment = color($CSS_COMMENT).
			(join $EMPTY_STR, @comments).
			color('reset');
		if (@{$self->{'tmp_code'}}) {
			my $sep = $EMPTY_STR;
			if ($self->{'comment_after_selector'} == 0) {
				$sep = $self->{'output_sep'};
				pop @{$self->{'tmp_code'}};
			}
			push @{$self->{'tmp_code'}}, ($sep) x 2, $comment,
				$self->{'output_sep'};
			$self->{'comment_after_selector'} += 4;
		} else {
			push @{$self->{'flush_code'}},
				$self->{'indent'}->get.$comment;
		}
		$self->{'processed'} = 0;
	}
	return;
}

# Definition.
sub _put_definition {
	my ($self, $key, $value) = @_;

	$self->_check_opened_selector;
	$self->_flush_tmp;
	push @{$self->{'flush_code'}},
		$self->{'indent'}->get.
		$self->_colorize_definition_key($key).
		':'.
		$SPACE.
		$self->_colorize_definition_value($value).
		';';
	$self->{'processed'} = 1;

	return;
}

# Selectors.
sub _put_selector {
	my ($self, $selector) = @_;

	$selector = $self->_split_selector($selector);

	push @{$self->{'tmp_code'}}, $selector, ',', ' ';
	$self->{'comment_after_selector'} = 0;
	$self->{'open_selector'} = 1;

	return;
}

sub _split_selector {
	my ($self, $selector) = @_;

	my @selector;
	if ($selector =~ m/\s+/ms) {
		@selector = split m/\s+/ms, $selector;
	} else {
		@selector = $selector;
	}

	my $ret_selector;	
	foreach my $one_selector (@selector) {
		if (defined $ret_selector) {
			$ret_selector .= ' ';
		}
		$ret_selector .= $self->_detect_selector($one_selector);
	}

	return $ret_selector;
}

sub _detect_selector {
	my ($self, $selector) = @_;

	if ($selector =~ m/^\./ms) {
		$selector = $self->_colorize_selector($selector, 'class');
	} elsif ($selector =~ m/^(.*)(#.*)$/ms) {
		$selector = $self->_colorize_selector($1, 'element').
			$self->_colorize_selector($2, 'id');
	} elsif ($selector =~ m/^(.*)(\..*)$/ms) {
		$selector = $self->_colorize_selector($1, 'element').
			$self->_colorize_selector($2, 'class');
	} else {
		$selector = $self->_colorize_selector($selector, 'element');
	}

	return $selector;
}

sub _colorize_selector {
	my ($self, $selector, $type) = @_;

	if ($type eq 'element') {
		$selector = color($CSS_SELECTOR_ELEMENT).$selector.color('reset');
	} elsif ($type eq 'class') {
		$selector = color($CSS_SELECTOR_CLASS).$selector.color('reset');
	} elsif ($type eq 'id') {
		$selector = color($CSS_SELECTOR_ID).$selector.color('reset');
	}

	return $selector;
}

sub _colorize_definition_key {
	my ($self, $key) = @_;

	if ($key =~ m/^--/ms) {
		$key = color($CSS_DEFINITION_KEY_PREFIX).$key.color('reset');
	} else {
		$key = color($CSS_DEFINITION_KEY).$key.color('reset');
	}

	return $key;
}

sub _colorize_definition_value {
	my ($self, $value) = @_;

	if ($value =~ m/^\d+$/ms) {
		$value = color($CSS_DEFINITION_VALUE_NUMBER).$value.color('reset');
	} else {
		$value = color($CSS_DEFINITION_VALUE_STRING).$value.color('reset');
	}

	return $value;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CSS::Struct::Output::Indent::ANSIColor - Indent printing 'CSS::Struct' structure to CSS code with ansi color output.

=head1 SYNOPSIS

 use CSS::Struct::Output::Indent::ANSIColor;

 my $css = CSS::Struct::Output::Indent::ANSIColor->new(%parameters);
 my $ret_or_undef = $css->flush($reset_flag);
 $css->put(@data);
 $css->reset;

=head1 METHODS

=head2 C<new>

 my $css = CSS::Struct::Output::Indent::ANSIColor->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<auto_flush>

 Auto flush flag.
 Default is 0.

=item * C<comment_delimeters>

 Reference to array with begin and end comment delimeter.
 Default value is ['/*', '*/'].
 Possible values are:
 - ['/*', '*/']
 - ['<!--', '-->'],

=item * C<next_indent>

 Indent string.
 Default value is TAB.

=item * C<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default is undef.

=item * C<skip_bad_types>

 Flag, that means bad 'CSS::Struct' types skipping.
 Default value is 0.

=item * C<skip_comments>

 Flag, that means comment skipping.
 Default value is 0.

=back

=head2 C<flush>

 my $ret_or_undef = $css->flush($reset_flag);

Flush CSS structure in object.
If defined 'output_handler' flush to its.
Or return CSS.
If enabled $reset_flag, then resets internal variables via reset method.

Returns output string or undef.

=head2 C<put(@data)>

 $css->put(@data);

Put CSS structure in format specified in L<CSS::Struct>.

Returns undef.

=head2 C<reset>

 $css->reset;

Resets internal variables.

Returns undef.

=head1 ERRORS

 From CSS::Struct::Output:
         Auto-flush can't use without output handler.
         Bad comment delimeters.
         Bad data.
         Bad number of arguments.
                 ('CSS::Struct' structure array),
         Bad type of data.
         Cannot write to output handler.
         No opened selector.
         Output handler is bad file handler.
         Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent::ANSIColor;

 my $css = CSS::Struct::Output::Indent::ANSIColor->new(
         'output_handler' => \*STDOUT,
 );

 $css->put(['c', 'Nice selector.']);
 $css->put(['a', '@import', 'file.css']);
 $css->put(['s', 'selector#id']);
 $css->put(['s', 'div div']);
 $css->put(['s', '.class']);
 $css->put(['s', 'p.class']);
 $css->put(['d', 'weight', '100px']);
 $css->put(['d', 'font-size', '10em']);
 $css->put(['d', '--border-color', 'hsl(0, 0%, 83%)']);
 $css->put(['e']);
 $css->flush;
 print "\n";

 # Output (in colors):
 # /* Nice selector. */
 # @import "file.css";
 # selector#id, div div, .class, p.class {
 #         weight: 100px;
 #         font-size: 10em;
 #         --border-color: hsl(0, 0%, 83%);
 # }

=head1 DEPENDENCIES

L<CSS::Struct::Output>,
L<Indent>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<CSS::Struct>

Struct oriented CSS manipulation.

=item L<CSS::Struct::Output>

Base class for CSS::Struct::Output::*.

=item L<CSS::Struct::Output::Raw>

Raw printing 'CSS::Struct' structure to CSS code.

=item L<CSS::Struct::Output::Indent>

Indent printing 'CSS::Struct' structure to CSS code.

=item L<CSS::Struct::Output::Structure>

Structure class for 'CSS::Struct' output.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CSS-Struct-Output-Indent-ANSIColor>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
