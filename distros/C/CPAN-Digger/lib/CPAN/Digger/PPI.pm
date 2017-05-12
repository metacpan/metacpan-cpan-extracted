package CPAN::Digger::PPI;
use 5.008008;
use Moose;

use PPI::Document;
use PPI::Find;

use Perl::MinimumVersion;

our $VERSION = '0.08';

has 'infile' => ( is => 'rw', isa => 'Str' );
has 'ppi'    => ( is => 'rw', isa => 'PPI::Document' );

sub min_perl {
	my ($self) = @_;
	my $pm     = Perl::MinimumVersion->new( $self->ppi );
	my @vm     = $pm->version_markers;
	return ( $pm->minimum_version, \@vm );
}

sub read_file {
	my ($self) = @_;

	my $file = $self->infile;
	my $text = do {
		open my $fh, '<', $file or die;
		local $/ = undef;
		<$fh>;
	};
	return $text;
}

sub get_ppi {
	my ($self) = @_;

	if ( not $self->ppi ) {
		my $text = $self->read_file;
		my $ppi  = PPI::Document->new( \$text );
		die if not defined $ppi;
		$ppi->index_locations;
		$self->ppi($ppi);
	}
	return $self->ppi;
}

sub get_syntax {
	my ($self) = @_;

	my $ppi  = $self->get_ppi;
	my $html = <<"END_HTML";
END_HTML

	my @tokens = $ppi->tokens;
	my $current_row;
	foreach my $t (@tokens) {

		my ( $row, $rowchar, $col ) = @{ $t->location };

		my $css     = $self->_css_class($t);
		my $content = $t->content;
		chomp $content;

		# TODO set the width of the rownumber constant
		# TODO allow the user to turn on/off row numbers
		#      (this should be some javascript setting hide/show)
		if ( not defined $current_row or $current_row < $row ) {
			if ( defined $current_row ) {
				$html .= "</div>\n"; #close the row;
			}
			$current_row = $row;
			$html .= qq(<div class="row">$current_row );
		}


		# TODO: how handle tabs and indentation in general?? for now we replace TABs by 4 spaces
		if ( $t->isa('PPI::Token::Whitespace') ) {
			$content =~ s/\t/    /s;
			if ( length $content > 1 ) {
				$content = qq(<pre class="ws">$content</pre>);
			}
		}

		if ( $css eq 'keyword' or $css eq 'core' or $css eq 'pragma' ) {
			$content = qq(<a>$content</a>);
		}

		$html .= qq(<div class="$css">$content</div>);

		#		if ($row > $first and $row < $first + 5) {
		#			print "$row, $rowchar, ", $t->length, "  ", $t->class, "  ", $css, "  ", $t->content, "\n";
		#		}
		#		last if $row > 10;
		#my $color = $colors{$css};
		#if ( not defined $color ) {
		#	TRACE("Missing definition for '$css'\n") if DEBUG;
		#	next;
		#}
		#next if not $color;
	}
	$html .= "</div>\n"; #close the last row;

	return $html;
}

sub _css_class {
	my $self  = shift;
	my $Token = shift;

	if ( $Token->isa('PPI::Token::Word') ) {

		# There are some words we can be very confident are
		# being used as keywords
		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $Token->content =~ /^(?:sub|return)$/ ) {
				return 'keyword';
			} elsif ( $Token->content =~ /^(?:undef|shift|defined|bless)$/ ) {
				return 'core';
			}
		}
		if ( $Token->previous_sibling and $Token->previous_sibling->content eq '->' ) {
			if ( $Token->content =~ /^(?:new)$/ ) {
				return 'core';
			}
		}
		if ( $Token->parent->isa('PPI::Statement::Include') ) {
			if ( $Token->content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $Token->content eq $Token->parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Variable') ) {
			if ( $Token->content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Compound') ) {
			if ( $Token->content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Package') ) {
			if ( $Token->content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal coloring
	my $css = ref $Token;
	$css =~ s/^.+:://;
	$css;
}

1;
