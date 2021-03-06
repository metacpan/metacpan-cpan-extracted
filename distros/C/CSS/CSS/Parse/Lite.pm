package CSS::Parse::Lite;

$VERSION = 1.02;

use CSS::Parse;
@ISA = qw(CSS::Parse);

use strict;
use warnings;

use Carp;
use CSS::Style;
use CSS::Selector;
use CSS::Property;

# The main parser
sub parse_string {
	my $self = shift;
	my $string = shift;

	$string =~ s/\r\n|\r|\n/ /g;

	# Split into styles
	foreach ( grep { /\S/ } split /(?<=\})/, $string ) {
		unless ( /^\s*([^{]+?)\s*\{(.*)\}\s*$/ ) {
			croak( "Invalid or unexpected style data '$_'" );
		}
		$self->add_style($1, $2);
	}	
}

# add a style to the style list
sub add_style {
	my $self = shift;
	my $style = shift;
	my $contents = shift;

	my $style_obj = new CSS::Style({
		'adaptor'	=> $self->{parent}->{adaptor}
	});

	# parse the selectors
	for(split(/\s*,\s*/, $style)){
		my $selector_obj = new CSS::Selector({'name' => $_});
		$style_obj->add_selector($selector_obj);
	}

	# parse the properties
	foreach ( grep { /\S/ } split /\;/, $contents ) {
		unless ( /^\s*([\w._-]+)\s*:\s*(.*?)\s*$/ ) {
			croak( "Invalid or unexpected property '$_' in style '$style'" );
		}
		my $property_obj = new CSS::Property({
			'property'	=> $1,
			'value'		=> $2,
			'adaptor'	=> $style_obj->{adaptor},
		});
		$style_obj->add_property($property_obj);
	}

	push @{$self->{parent}->{styles}}, $style_obj;
}

1;

__END__

=head1 NAME

CSS::Parse::Lite - A CSS::Parse module using regular expressions

=head1 SYNOPSIS

  use CSS;

  # Create a css stylesheet
  my $CSS = CSS->new({'parser' => 'CSS::Parse::Lite'});

=head1 DESCRIPTION

This module is a parser for CSS.pm. Read the CSS.pm pod for more details

=head1 AUTHOR

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, http://www.w3.org/TR/REC-CSS1

=cut
