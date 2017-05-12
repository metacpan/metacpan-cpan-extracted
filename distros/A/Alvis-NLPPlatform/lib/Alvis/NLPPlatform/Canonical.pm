package Alvis::NLPPlatform::Canonical;
use strict;
use warnings;


our $VERSION=$Alvis::NLPPlatform::VERSION;

sub CleanUp
{
    
    my ($canonical, $preserveWhiteSpace) = @_;

#     my $tmp_str;

    if (!$preserveWhiteSpace) {
	warn "\nRemoving White Spaces\n";
	
	$canonical =~ s/^[\s\t]*(<[^>]+>)[\s\t\n]*(\n)/$1$2/go;
	$canonical =~ s/(\n)[\s\t\n]*(<[^>]+>)[\s\t]*(\n)/$1$2$3/go;
	$canonical =~ s/(\n)[\s\t\n]*(<[^>]+>)[\s\t]*/$1$2/go;
    }
    $canonical =~ s/<section[^>]*>//go;
    


    $canonical =~ s/<\/?list>/\n/go;
    $canonical =~ s/<\/?item>/\n/go;
    $canonical =~ s/<\/?canonicalDocument>/\n/go;
    $canonical =~ s/<\/?ulink[^>]*>//go;
    if (!$preserveWhiteSpace) {
	$canonical =~ s/\n+/\n/go;
	$canonical =~ s/^\n//go;
	$canonical =~ s/^\n$//go;
    }
    
    my $pos = 0;
    my $str = $canonical;
    my $pos_section = -1;
    my $pos_prec_section = 0;

    Alvis::NLPPlatform::XMLEntities::decode($str);
    $canonical = "";

    while(($pos_section = index($str, "</section>", $pos_prec_section)) > -1) {
	$canonical .= substr($str, $pos_prec_section, $pos_section - $pos_prec_section);
 	chomp $canonical;
 	if ($pos_section != $pos_prec_section) {
 	    $canonical .= "\n";
 	}
	if (!$preserveWhiteSpace) {
	    $canonical =~ s/\n+/\n/go;
	    $canonical =~ s/^\n//go;
	    $canonical =~ s/^\n$//go;
	}

	push @Alvis::NLPPlatform::tab_end_sections_byaddr, (length($canonical) - 1);
	$pos_prec_section = $pos_section + 10;
    }


    return($canonical);
}

1;


__END__

=head1 NAME

Alvis::NLPPlatform::Canonical - Perl extension for cleaning XML
annotation of the canonical part of documents given the Alvis format.

=head1 SYNOPSIS

use Alvis::NLPPlatform::Canonical;

Alvis::NLPPlatform::Canonical::CleanUp($canonical);

=head1 DESCRIPTION

This module provides a method for removing XML annotation in the
canonical section of Alvis documents.

=head1 METHODS

=head2 CleanUp($canonical_doc, $preserveWhiteSpace)

This method removes all the XML tags in the canonical document
(C<$canonical_doc>), passed as paramater. Note that the method assumes
that only the canonical section is sent. The boolean
C<$preserveWhiteSpace> indicate if the linguistic annotation will be
done by preserving white space or not, i.e. XML blank nodes and white
space at the beginning and the end of any line.

=cut

=head1 SEE ALSO

C<Alvis::NLPPlatform>

Alvis web site: http://www.alvis.info

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr> and Julien Deriviere <julien.deriviere@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon and Julien Deriviere

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut 

