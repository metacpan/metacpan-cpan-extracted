
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use warnings;
use strict;

# 4.2 Fundamental Facets

my @p = split( /\n/, <<ENDE );
4.2.1 equal
4.2.2 ordered
4.2.3 bounded
4.2.4 cardinality
4.2.5 numeric
ENDE

use Data::Dumper;

use HTML::Template;

my @x = map { split /\s/; { lc_name => lc $_[1], uc_name => uc $_[1], name => $_[1], id => $_[0] } } @p;

print Dumper \@x;

my $tmpl = <<'ENDE';
=begin comment	

http://www.w3.org/TR/xmlschema-2/#rf-fund-facets

4.2 Fundamental Facets

4.2.1 equal
4.2.2 ordered
4.2.3 bounded
4.2.4 cardinality
4.2.5 numeric

=end 

<TMPL_LOOP NAME=primitiv_types>

package Data::Type::Facet::<TMPL_VAR name=lc_name>;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::IFacet::Fundamental);

    sub desc { '<TMPL_VAR name> (<TMPL_VAR id>)' }
</TMPL_LOOP>
ENDE

    my $template = HTML::Template->new( type => 'scalarref', source => \$tmpl, die_on_bad_params => 0, loop_context_vars => 1 );

    $template->param( primitiv_types => \@x );

    print $template->output;
