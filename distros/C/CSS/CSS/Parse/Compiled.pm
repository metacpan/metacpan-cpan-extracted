package CSS::Parse::Compiled;

$VERSION = 1.01;

use CSS::Parse;
@ISA = qw(CSS::Parse);

use strict;
use warnings;

use Carp qw(croak confess);

use CSS::Style;
use CSS::Selector;
use CSS::Property;
use CSS::Adaptor;

use CSS::Parse::CompiledGrammar;
   $Parse::RecDescent::skip = '';

use Data::Dumper;

sub parse_string {
	my $self = shift;
	my $source = shift;

	my $parser = CSS::Parse::CompiledGrammar->new();
	$self->{parent}->{styles} = $parser->stylesheet($source);
}

1;
__END__

=head1 NAME

CSS::Parse::Compiled - A CSS::Parse module using a compiled Parse::RecDescent grammar

=head1 SYNOPSIS

  use CSS;

  # Create a css stylesheet
  my $CSS = CSS->new({'parser' => 'CSS::Parse::Compiled'});

=head1 DESCRIPTION

This module is a parser for CSS.pm. Read the CSS.pm pod for more details

=head1 AUTHORS

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, http://www.w3.org/TR/REC-CSS1

=cut

