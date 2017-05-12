package CPAN::Digger::Syntax;
use 5.008008;
use Moose;
use warnings FATAL => 'all';

our $VERSION = '0.08';

extends 'CPAN::Digger';

has 'infile'  => ( is => 'ro', isa => 'Str' );
has 'outfile' => ( is => 'ro', isa => 'Str' );

# based on Padre::Document::Perl::PPILexer

use CPAN::Digger::Index;

use PPI::Document;
use autodie;


sub process {
	my ( $self, %opt ) = @_;

	my $tt = $self->get_tt;

	my $infile  = CPAN::Digger::Index::_untaint_path( $opt{infile} );
	my $outfile = CPAN::Digger::Index::_untaint_path( $opt{outfile} );

	open my $fh, '<', $infile;
	my @rows = <$fh>;
	close $fh;
	my $text = join '', @rows;

	#	my $text = do { open my $fh, '<', $infile; local $/ = undef; <$fh> };
	my $ppi_doc = PPI::Document->new( \$text );
	if ( not defined $ppi_doc ) {
		die sprintf( 'PPI::Document Error %s', PPI::Document->errstr );
	}
	my @tokens = $ppi_doc->tokens;
	$ppi_doc->index_locations;

	#print "First $first lines $lines\n";
	my $current_row = 0;
	my $html        = '';
	foreach my $t (@tokens) {

		#print $t->content;
		my ( $row, $rowchar, $col ) = @{ $t->location };

		#		next if $row < $first;
		#		next if $row > $first + $lines;
		my $css = $self->_css_class($t);

		#		if ($row > $first and $row < $first + 5) {
		#			print "$row, $rowchar, ", $t->length, "  ", $t->class, "  ", $css, "  ", $t->content, "\n";
		#		}
		#		last if $row > 10;
		my $len = $t->length;
		$row--;
		$rowchar--;

		# logger
		#		printf("%s, %s, %s, %s   %s\n", $row, $rowchar, $col, $len, $css);
		#		printf("[%s]", $rows[$row]);
		#		printf("<%s>", substr($rows[$row], $rowchar, $len));

		#$html .= sprintf('<div class="%s">%s</div>', $css, substr($rows[$row], $rowchar, $len));
		$html .= sprintf( '<div class="%s">', $css );
		while ( length( $rows[$row] ) < $rowchar + $len ) {
			$html .= substr( $rows[$row], $rowchar );
			$len -= length substr( $rows[$row], $rowchar );
			$row++;
		}
		if ($len) {
			$html .= substr( $rows[$row], $rowchar, $len );
		}
		$html .= '</div>';
	}


	my %data = (
		filename => $opt{infile},
		code     => $html,
	);
	$tt->process( 'syntax.tt', \%data, $outfile ) or die $tt->error;

	#	open my $out, '>', $outfile;
	#	print $out $html;
	return 1;
}

sub _css_class {
	my ( $self, $Token ) = @_;
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
