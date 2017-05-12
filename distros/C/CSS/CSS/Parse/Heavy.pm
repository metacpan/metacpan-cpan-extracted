package CSS::Parse::Heavy;

$VERSION = 1.01;

use CSS::Parse;
@ISA = qw(CSS::Parse);

use strict;
use warnings;

use Carp qw(croak confess);
use Parse::RecDescent;
   $Parse::RecDescent::skip = '';

use CSS::Parse::PRDGrammar;
use CSS::Style;
use CSS::Selector;
use CSS::Property;
use CSS::Adaptor;

use Data::Dumper;


sub parse_string {
	my $self = shift;
	my $source = shift;

	#$::RD_HINT = 1;
	#$::RD_TRACE = 1;
	#$::RD_AUTOACTION = 'use Data::Dumper; print Dumper(@item)."\n";';
	$::RD_AUTOACTION = 'print "token: ".shift @item; print " : @item\n"';

	my $parser = new Parse::RecDescent($CSS::Parse::PRDGrammar::GRAMMAR);
	$self->{parent}->{styles} = $parser->stylesheet($source);
}

1;
__END__

=head1 NAME

CSS::Parse::Heavy - A CSS::Parse module using Parse::RecDescent

=head1 SYNOPSIS

  use CSS;

  # Create a css stylesheet
  my $CSS = CSS->new({'parser' => 'CSS::Parse::Heavy'});

=head1 DESCRIPTION

This module is a parser for CSS.pm. Read the CSS.pm pod for more details

=head1 AUTHORS

Copyright (C) 2001-2002, Allen Day <allenday@ucla.edu>

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, http://www.w3.org/TR/REC-CSS1

=cut

