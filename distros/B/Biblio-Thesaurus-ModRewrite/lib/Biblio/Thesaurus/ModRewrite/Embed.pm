package Biblio::Thesaurus::ModRewrite::Embed;

use Filter::Simple;
use Data::Dumper;
     
use warnings;
use strict;

=head1 NAME

Biblio::Thesaurus::ModRewrite::Embed - a module to embed OML programs
in Perl code.

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Biblio::Thesaurus::ModRewrite::Embed;

  OML proc
  $city 'city-of' $country => sub { print "$city is in $country\n"; }.
  ENDOML

  proc('ontology.iso');

=head1 DESCRIPTION

This module can be used to embed OML programs in Perl source code. This
module works as a filter for the source code, so you should only need
to load it.

=head1 FUNCTIONS

=head2 buildOML

This function is used to create a new funcion to execute the OML code
found.

=cut

sub buildOML {
	(my $name, my $list, my $code) = @_;
	$list = '' unless $list;

	# begin
	my $c = "sub $name {\n";
	
	# handle ontology
	$c .= "\tmy \$ont = shift;\n";
	$c .= "\tuse Biblio::Thesaurus;\n";
	$c .= "\tuse Biblio::Thesaurus::ModRewrite;\n";
	$c .= "\tmy \$obj;\n";
	$c .= "\tif (ref(\$ont) eq 'Biblio::Thesaurus') {\n";
	$c .= "\t\t\$obj = \$ont;\n";
	$c .= "\t} else {\n";
	$c .= "\t\t\$obj = thesaurusLoad(\$ont);\n";
	$c .= "\t}\n\n";

	# handle OML code
	$c .= "my \$code=<<'EOF';\n";
	$c .= "$code";
	$c .= "EOF\n\n";

	# black magic
	$c .= "\tif(\"$list\" eq '') {\n";
	$c .= "\t\tmy \@ARGV = \@_;\n\n";
	$c .= "\t\t\$code =~ s/\\\$ARGV\\[(\\d+)\\]/\$ARGV[\$1]/ge;\n\n";
	$c .= "\t} else {\n";
	$c .= "\t\t\@tmp = split /,/, \"$list\";\n";
	$c .= "\t\tforeach (\@_) { my \$i = shift \@tmp;\n";
	$c .= "\t\t\t\$code =~ s/\\b\$i\\b/'\$_'/g;\n";
	$c .= "\t\t}\n";
	$c .= "\t}\n";

	# main
	$c .= "\$t = Biblio::Thesaurus::ModRewrite->new(\$obj);\n";
	$c .= "\$t->process(\$code);\n";

	# finish
	$c .="}\n";

	$c;
}

=head2 FILTER

This filters your Perl source code.

=cut

FILTER { 
	return if m/^(\s|\n)*$/;

	#print "BEFORE $_\n";
	s/^OML\s+(\w+)(\(([\w,]+)\))?\s*\n((?:.|\n)*?)^ENDOML/buildOML($1,$3,$4)/gem;
	#print "AFTER $_\n";

	$_;
};

=head1 EXAMPLES

Look in the F<examples> and F<bin> directory for sample programs.

=head1 AUTHOR

Nuno Carvalho, C<< <smash@cpan.org> >>

J.Joao Almeida, C<< <jj@di.uminho.pt> >>

Alberto Simoes, C<< <albie@alfarrabio.di.uminho.pt> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nuno Carvalho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
