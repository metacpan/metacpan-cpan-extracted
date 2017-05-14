
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use warnings;
use strict;

# 3.3 Derived datatypes

my @p = split( /\n/, <<ENDE );
3.3.1 normalizedString
3.3.2 token
3.3.3 language
3.3.4 NMTOKEN
3.3.5 NMTOKENS
3.3.6 Name
3.3.7 NCName
3.3.8 ID
3.3.9 IDREF
3.3.10 IDREFS
3.3.11 ENTITY 
3.3.12 ENTITIES
3.3.13 integer
3.3.14 nonPositiveInteger
3.3.15 negativeInteger
3.3.16 long
3.3.17 int
3.3.18 short
3.3.19 byte
3.3.20 nonNegativeInteger
3.3.21 unsignedLong
3.3.22 unsignedInt
3.3.23 unsignedShort
3.3.24 unsignedByte
3.3.25 positiveInteger
ENDE

use Data::Dumper;

use HTML::Template;

my @x = map { split /\s/; { lc_name => lc $_[1], uc_name => uc $_[1], name => $_[1], id => $_[0] } } @p;

print Dumper \@x;

my $tmpl = <<'ENDE';
=begin comment

3.3 Derived datatypes
3.3.1 normalizedString 
3.3.2 token 
3.3.3 language 
3.3.4 NMTOKEN 
3.3.5 NMTOKENS 
3.3.6 Name 
3.3.7 NCName 
3.3.8 ID 
3.3.9 IDREF 
3.3.10 IDREFS 
3.3.11 ENTITY 
3.3.12 ENTITIES 
3.3.13 integer 
3.3.14 nonPositiveInteger 
3.3.15 negativeInteger 
3.3.16 long 
3.3.17 int 
3.3.18 short 
3.3.19 byte 
3.3.20 nonNegativeInteger 
3.3.21 unsignedLong 
3.3.22 unsignedInt 
3.3.23 unsignedShort 
3.3.24 unsignedByte 
3.3.25 positiveInteger 	

=end
<TMPL_LOOP NAME=primitiv_types>

package Data::Type::Object::<TMPL_VAR name=lc_name>;

    our @ISA = qw(Data::Type::IType::Derived);

    sub export { qw(<TMPL_VAR name=uc_name>) }

    sub desc { '<TMPL_VAR name> (<TMPL_VAR id>)' }
</TMPL_LOOP>
ENDE

    my $template = HTML::Template->new( type => 'scalarref', source => \$tmpl, die_on_bad_params => 0, loop_context_vars => 1 );

    $template->param( primitiv_types => \@x );

    print $template->output;
