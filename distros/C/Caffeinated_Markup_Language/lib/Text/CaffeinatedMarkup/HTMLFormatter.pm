package Text::CaffeinatedMarkup::HTMLFormatter;

use v5.10;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use Moo;
use Text::CaffeinatedMarkup::PullParser;
use HTML::Escape qw/escape_html/;


my %tags = (
	STRONG_OPEN		=> '<strong>',
	STRONG_CLOSE 	=> '</strong>',
	EMPHASIS_OPEN	=> '<em>',
	EMPHASIS_CLOSE 	=> '</em>',
	UNDERLINE_OPEN	=> '<u>',
	UNDERLINE_CLOSE => '</u>',
	DEL_OPEN		=> '<del>',
	DEL_CLOSE	 	=> '</del>',

	PARAGRAPH_OPEN 	=> '<p>',
	PARAGRAPH_CLOSE	=> '</p>',

	BLOCKQUOTE_OPEN	=> '<blockquote>',
	BLOCKQUOTE_CLOSE=> '</blockquote>',

	BLOCKQUOTE_CITE_OPEN	=> '<cite>',
	BLOCKQUOTE_CITE_CLOSE	=> '</cite>',
);


has 'tag_stack'				=> (is=>'rw',default=>sub{[]});
has 'is_paragraph_open'		=> (is=>'rw');
has 'num_breaks'			=> (is=>'rw');

has 'is_in_row'				=> (is=>'rw');
has 'is_in_column'			=> (is=>'rw');
has 'row_has_num_columns'	=> (is=>'rw');
has 'row_columns'			=> (is=>'rw');

sub format {
	my ($self, $pml) = @_;

	my $parser = Text::CaffeinatedMarkup::PullParser->new(pml => $pml);

	my @tokens = $parser->get_all_tokens;
	
	my $output_html 	= '';
	my $cur_column_html = '';
	my $html   			= \$output_html;

	$self->num_breaks(0);

	$self->is_paragraph_open(0);
	$self->is_in_row(0);
	$self->row_has_num_columns(-1);
	$self->row_columns([]);	
		
	foreach my $token (@tokens) {

		my $type = $token->{type};

		if ($type eq 'NEWLINE') {
			# Start storing breaks. We output as soon as we get something different
			# (see the else). If there's only one then you get a BR, otherwise you
			# get a paragraph.
			$self->num_breaks( $self->num_breaks+1 );
			next;			
		}
		else {
			unless ($type eq 'HEADER') {

				if ($self->num_breaks == 1) {
					$$html .= '<br>';
				}
				elsif ($self->num_breaks > 1) {
					$$html .= $self->_close_paragraph if $self->is_paragraph_open;
					$$html .= $self->_open_paragraph;
				}
			}
			$self->num_breaks(0);
		}

		if ($type eq 'QUOTE') {

			$self->_close_paragraph if $self->is_paragraph_open;

			$$html .= $tags{BLOCKQUOTE_OPEN};
			$$html .= $token->{body};

			if ($token->{cite}) {
				$$html .= $tags{BLOCKQUOTE_CITE_OPEN}.$token->{cite}.$tags{BLOCKQUOTE_CITE_CLOSE};
			}

			$$html .= $tags{BLOCKQUOTE_CLOSE};
		}

		if ($type eq 'ROW') {			
			if ($self->is_in_row) {
				# Finalise row

				if ($self->is_in_column) {
					$cur_column_html .= $self->_close_paragraph if $self->is_paragraph_open;					
					# Already in a column, so output it to the column store				
					push @{$self->row_columns}, $cur_column_html;
					$cur_column_html = '';	
				}

				$html = \$output_html;

				my $num_columns = $self->_num_columns_in_cur_row;



				$$html .= '<div class="clearfix col-'.$num_columns.'">'."\n";

				foreach my $column (@{$self->row_columns}) {
					$$html .= '<div class="column">' . "\n$column" . "</div>\n";					
				}

				$$html .= "</div>\n"; # End of row

				# Reset the columns when we close out the row rather than
				# when starting so that you can always query "num columns"
				# and it will be right in context for wherever the parsing is.
				$self->row_columns([]);
				$self->is_in_column(0);
				$self->is_in_row(0);
				
			}
			else {				
				$$html .= $self->_close_paragraph if $self->is_paragraph_open;
				$self->is_in_row(1);
			}
			next;
		}

		if ($type eq 'COLUMN') {			
			# TODO error if not in row!			
			$html = \$cur_column_html;		

			if ($self->is_in_column) {
				$cur_column_html .= $self->_close_paragraph if $self->is_paragraph_open;				
				# Already in a column, so output it to the column store				
				push @{$self->row_columns}, $cur_column_html;
				$cur_column_html = '';	
			}
						
			$self->is_in_column(1);
			$self->row_has_num_columns( $self->row_has_num_columns+1 );			
		}

		if ($type =~ /^(STRONG|EMPHASIS|UNDERLINE|DEL)$/o) {
			TRACE "Type [$1]";			
			$$html .= $self->_match_tag($1);
			next;
		}

		if ($type eq 'LINK') {
			# TODO - target
			my $href = $token->{href};
			my $text = $token->{text} || $token->{href};
			$$html .= qq|<a href="$href" target="_new">$text</a>|;
			next;
		}

		if ($type eq 'IMAGE') {
			my @options;
			if ($token->{options}) {				
				@options = split /,/,$token->{options};				
			}			

			my $align  = '';
			my $height = '';
			my $width  = '';

			foreach my $option (@options) {
				$align = ' class="pulled-left"'  if $option eq '<<';
				$align = ' class="pulled-right"' if $option eq '>>';
				$align = ' class="stretched"'    if $option eq '<>';
				$align = ' class="centered"'     if $option eq '><';

				if ($option =~ /^H(.+)$/) { $height = qq| height="$1px"| }
				if ($option =~ /^W(.+)$/) { $width  = qq| width="$1px"|  }
			}
			
			$$html .= '<img src="'.$token->{src}.'"'.$align.$width.$height.'>';
			next;
		}

		if ($type eq 'HEADER') {
			$$html .= "\n<h".$token->{level}.'>'.$token->{text}.'</h'.$token->{level}.">\n";
			next;
		}

		if ($type eq 'STRING') {
			$$html .= $self->_open_paragraph unless $self->is_paragraph_open;
			$$html .= escape_html($token->{content});
			next;
		}



		# Shouldn't get here!
		# TODO error

	}

	# If there's a paragraph open, close it!
	$output_html .= $tags{PARAGRAPH_CLOSE} if $self->is_paragraph_open;

	return $output_html;
}

# ------------------------------------------------------------------------------

sub _num_columns_in_cur_row {
	my ($self) = @_;
	return scalar @{$self->row_columns};
}

# ------------------------------------------------------------------------------

sub _match_tag {
	my ($self, $type) = @_;

	if (@{$self->tag_stack} && $self->tag_stack->[0] eq $type) {		
		# Close tag
		$self->_pop_stack;
		return $tags{$type."_CLOSE"};
	}
	else {		
		# Open tag
		my $html = '';		
		# If a paragraph isn't open then we need to open one!
		$html = $self->_open_paragraph unless $self->is_paragraph_open;		
		$self->_push_stack($type);
		return $html . $tags{$type."_OPEN"};
	}
	return;
}

# ------------------------------------------------------------------------------

sub _push_stack {
	my ($self, $type) = @_;
	unshift @{$self->tag_stack}, $type;
}

# ------------------------------------------------------------------------------

sub _pop_stack {
	my ($self) = @_;
	return shift @{$self->tag_stack};
}

# ------------------------------------------------------------------------------

sub _open_paragraph {
	my ($self) = @_;
	die "Can't open paragraph - already open!" if $self->is_paragraph_open;
	$self->_push_stack('PARAGRAPH');
	$self->is_paragraph_open(1);
	return $tags{PARAGRAPH_OPEN};
}

# ------------------------------------------------------------------------------

sub _close_paragraph {
	my ($self) = @_;
	die "Can't close paragraph - already closed!" unless $self->is_paragraph_open;
	die "Can't close paragraph - bad stack match" unless $self->tag_stack->[0] eq 'PARAGRAPH';
	$self->_pop_stack;
	$self->is_paragraph_open(0);
	return $tags{PARAGRAPH_CLOSE}."\n";
}

1;

__END__

=pod

=head1 Title

Text::CaffeinatedMarkup::HTMLFormatter - HTML formatter for the Caffeinated Markup Language

=head1 Synopsis

  use Text::CaffeinatedMarkup::HTMLFormatter;

  my $formatter = Text::CaffeinatedMarkup::HTMLFormatter->new;

  my $to_format = 'Some **stuff** to be //parsed//';

  my $html = $formatter->format($to_format);

=head1 Description

Provides formatting to HTML for the I<Caffeinated Markup Language>. Implemented using
the L<Text::CaffeinatedMarkup::PullParser>.

For details on the syntax that B<CML> implements, please see the
L<Github wiki|https://github.com/necrophonic/text-caffeinatedmarkup/wiki>.

=head1 Methods

This module provides the following methods.

=head2 format

  my $html = $formatter->format( 'something to format' );

Takes a raw string in I<Caffeinated Markup> format and returns a string of encoded HTML.


=head1 Mappings

The various markup elements are mapped to HTML by this formatter as follows.

=head3 strong

  **foo** -> <strong>foo</strong>

=head3 emphasis

  //foo// -> <em>foo</em>

=head3 underline

  __foo__ -> <u>foo</u>

=head3 delete

  --foo-- -> <del>foo</del>

=head3 section divider

  ~~ -> <hr>

=head3 blockquote

  ""foo""     -> <blockquote>foo</blockquote>
  ""foo|bar"" -> <blockquote>foo<cite>bar</cite></blockquote>

=head3 headers

  # foo    -> <h1>foo</h1>
  ## foo   -> <h2>foo</h2>
  ### foo  -> <h3>foo</h3>

=head3 hyperlinks

  [[http://www.google.com]]        -> <a href="http://www.google.com">http://www.google.com</a>
  [[http://www.google.com|google]] -> <a href="http://www.google.com">google</a>

=head3 images

  {{foo.jpg}}            -> <img src="foo.jpg">
  {{foo.jpg|<<,H10,W10}} -> <img src="foo.jpg" class="pulled-left" width="10px" height="10px">

=head3 newlines and paragraphs

  \n    -> <br>
  \n\n  -> <p>  # (3+ \n still becomes single <p>)

=head3 rows and columns

  ==\n||foo\n||bar\n== -> <div class="clearfix col-2">
                          <div class="column">foo</div>
                          <div class="column">bar</div>
                          </div>


=head1 See Also

L<The Github wiki|https://github.com/necrophonic/text-caffeinatedmarkup/wiki>

=head1 Author

J Gregory <jgregory@cpan.org>

=cut
