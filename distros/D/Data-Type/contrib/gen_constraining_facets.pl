
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use warnings;
use strict;

# 4.3 Constraining Facets

my @p = split( /\n/, <<ENDE );
4.3.1 length
4.3.2 minLength
4.3.3 maxLength
4.3.4 pattern
4.3.5 enumeration
4.3.6 whiteSpace
4.3.7 maxInclusive
4.3.8 maxExclusive
4.3.9 minExclusive
4.3.10 minInclusive
4.3.11 totalDigits
4.3.12 fractionDigits
ENDE

use Data::Dumper;

use HTML::Template;

my @x = map { split /\s/; { lc_name => lc $_[1], uc_name => uc $_[1], name => $_[1], id => $_[0] } } @p;

print Dumper \@x;

my $tmpl = <<'ENDE';
=begin comment

4.3 Constraining Facets

4.3.1 length 
4.3.2 minLength 
4.3.3 maxLength 
4.3.4 pattern 
4.3.5 enumeration 
4.3.6 whiteSpace 
4.3.7 maxInclusive 
4.3.8 maxExclusive 
4.3.9 minExclusive 
4.3.10 minInclusive 
4.3.11 totalDigits 
4.3.12 fractionDigits 

=end 

<TMPL_LOOP NAME=primitiv_types>

package Data::Type::Facet::<TMPL_VAR name=lc_name>;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::IFacet::Constraining);

    sub desc { '<TMPL_VAR name> (<TMPL_VAR id>)' }
</TMPL_LOOP>
ENDE

    my $template = HTML::Template->new( type => 'scalarref', source => \$tmpl, die_on_bad_params => 0, loop_context_vars => 1 );

    $template->param( primitiv_types => \@x );

    print $template->output;
