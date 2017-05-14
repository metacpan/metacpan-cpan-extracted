
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use warnings;
use strict;

my @p = split( /\n/, <<ENDE );
3.2.1 string
3.2.2 boolean
3.2.3 decimal 
3.2.4 float
3.2.5 double
3.2.6 duration
3.2.7 dateTime
3.2.8 time
3.2.9 date
3.2.10 gYearMonth
3.2.11 gYear
3.2.12 gMonthDay
3.2.13 gDay
3.2.14 gMonth
3.2.15 hexBinary
3.2.16 base64Binary
3.2.17 anyURI
3.2.18 QName
3.2.19 NOTATION
ENDE

use Data::Dumper;

use HTML::Template;

my @x = map { split /\s/; { lc_name => lc $_[1], uc_name => uc $_[1], name => $_[1], id => $_[0] } } @p;

print Dumper \@x;

my $tmpl = <<'ENDE';
=begin comment

Primitive datatypes
3.2.1 string 
3.2.2 boolean 
3.2.3 decimal 
3.2.4 float 
3.2.5 double 
3.2.6 duration 
3.2.7 dateTime 
3.2.8 time 
3.2.9 date 
3.2.10 gYearMonth 
3.2.11 gYear 
3.2.12 gMonthDay 
3.2.13 gDay 
3.2.14 gMonth 
3.2.15 hexBinary 
3.2.16 base64Binary 
3.2.17 anyURI 
3.2.18 QName 
3.2.19 NOTATION 

=end

<TMPL_LOOP NAME=primitiv_types>

package Data::Type::Object::<TMPL_VAR name=lc_name>;

    our @ISA = qw(Data::Type::IType::Primitiv);

    sub export { qw(<TMPL_VAR name=uc_name>) }

    sub desc { '<TMPL_VAR name> (<TMPL_VAR id>)' }
</TMPL_LOOP>
ENDE

    my $template = HTML::Template->new( type => 'scalarref', source => \$tmpl, die_on_bad_params => 0, loop_context_vars => 1 );

    $template->param( primitiv_types => \@x );

    print $template->output;
