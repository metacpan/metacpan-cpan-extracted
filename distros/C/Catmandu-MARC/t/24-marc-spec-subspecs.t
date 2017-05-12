use strict;
use warnings;
use Test::More;
use Catmandu;

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:datafield ind1="0" ind2="1" tag="245">
            <marc:subfield code="a">Title / </marc:subfield>
            <marc:subfield code="c">Name</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="500">
            <marc:subfield code="a">A</marc:subfield>
            <marc:subfield code="a">B</marc:subfield>
            <marc:subfield code="a">C</marc:subfield>
            <marc:subfield code="x">D</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Alpha</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Beta</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Gamma</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">X</marc:subfield>
            <marc:subfield code="a">Y</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1="1" ind2=" " tag="999">
            <marc:subfield code="a">Z</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC

note 'marc_spec(650{$a=\Beta}, equals)     equals: "Beta"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a=\Beta}", equals); retain_field(equals)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals}, 'Beta', 'marc_spec(650{$a=\Beta}, equals)';
}

note 'marc_spec(650{$a!=\Beta}, equals_not)     equals_not: "AlphaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a!=\Beta}", equals_not); retain_field(equals_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals_not}, 'AlphaGamma', 'marc_spec(650{$a!=\Beta}, equals_not)';
}

note 'marc_spec(650{$a/0=\B}, equals)     equals: "Beta"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a/0=\B}", equals); retain_field(equals)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals}, 'Beta', 'marc_spec(650{$a/0=\B}, equals)';
}

note 'marc_spec(650{$a/0!=\B}, equals_not)     equals_not: "AlphaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a/0!=\B}", equals_not); retain_field(equals_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals_not}, 'AlphaGamma', 'marc_spec(650{$a/0!=\B}, equals_not)';
}

note 'marc_spec(650{$a~\ph}, includes)     includes: "Alpha"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a~\ph}", includes); retain_field(includes)'
    );
    my $record = $importer->first;
    is_deeply $record->{includes}, 'Alpha', 'marc_spec(650{$a~\ph}, includes)';
}

note 'marc_spec(650{$a!~\ph}, includes_not)     includes_not: "BetaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650{$a!~\ph}", includes_not); retain_field(includes_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{includes_not}, 'BetaGamma', 'marc_spec(650{$a!~\ph}, includes_not)';
}

note 'marc_spec(650[#]{$a!~\ph}, includes_not)     includes_not: "Gamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[#]{$a!~\ph}", includes_not); retain_field(includes_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{includes_not}, 'Gamma', 'marc_spec(650[#]{$a!~\ph}, includes_not)';
}

note 'marc_spec(245{500$a}, exists)     exists: "Title / Name"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("245{500$a}", exists); retain_field(exists)'
    );
    my $record = $importer->first;
    is_deeply $record->{exists}, 'Title / Name', 'marc_spec(245{500$a}, exists)';
}

note 'marc_spec(245{!500$a}, exists_not)     exists_not: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("245{!500$a}", exists_not); retain_field(exists_not)'
    );
    my $record = $importer->first;
    ok !$record->{exists_not}, 'marc_spec(245{!500$a}, exists_not)';
}

note 'marc_spec(245$a{500$a=\C}, equals)     equals: "Title / "';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("245$a{500$a=\C}", equals); retain_field(equals)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals}, 'Title / ', 'marc_spec(245$a{500$a=\C}, equals)';
}

note 'marc_spec(245$a{500$a!=\C}, equals_not)     equals_not: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("245$a{500$a!=\C}", equals_not); retain_field(equals_not)'
    );
    my $record = $importer->first;
    ok !$record->{equals_not}, 'marc_spec(245$a{500$a!=\C}, equals_not)';
}

note 'marc_spec(245{500$a!=\F}, equals_not)     equals: "Title / Name"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("245{500$a!=\F}", equals_not); retain_field(equals_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{equals_not}, 'Title / Name', 'marc_spec(245{500$a!=\F}, equals_not)';
}

note 'marc_spec(500$a[1]{$x}, exists)     exists: "B"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("500$a[1]{$x}", exists); retain_field(exists)'
    );
    my $record = $importer->first;
    is_deeply $record->{exists}, 'B', 'marc_spec(500$a[1]{$x}, exists)';
}

note 'marc_spec(500$a[1]{!$x}, exists_not)     exists_not: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("500$a[1]{!$x}", exists_not); retain_field(exists_not)'
    );
    my $record = $importer->first;
    ok !$record->{exists_not}, 'marc_spec(500$a[1]{!$x}, exists_not)';
}

note 'marc_spec(500$a[1]{!$c}, exists_not)     exists_not: "B"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("500$a[1]{!$c}", exists_not); retain_field(exists_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{exists_not}, 'B', 'marc_spec(500$a[1]{!$c}, exists_not)';
}

note 'marc_spec(650[1]{300}, exists)     exists: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{300}", exists); retain_field(exists)'
    );
    my $record = $importer->first;
    ok !$record->{exists}, 'marc_spec(650[1]{300}, exists)';
}

note 'marc_spec(650[1-#]{!300}, exists_not)     exists_not: "BetaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1-#]{!300}", exists_not); retain_field(exists_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{exists_not}, 'BetaGamma', 'marc_spec(650[1-#]{!300}, exists_not)';
}

note 'marc_spec(650[0]{!300}, exists_not)     exists_not: "Alpha"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[0]{!300}", exists_not); retain_field(exists_not)'
    );
    my $record = $importer->first;
    is_deeply $record->{exists_not}, 'Alpha', 'marc_spec(650[0]{!300}, exists_not)';
}

note 'marc_spec(650[1]{245_0}, indicator1)     indicator1: "Beta"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245_0}", indicator1); retain_field(indicator1)'
    );
    my $record = $importer->first;
    is_deeply $record->{indicator1}, 'Beta', 'marc_spec(650[1]{245_0}, indicator1)';
}

note 'marc_spec(999$a{_1}, indicator1)     indicator1: "Z"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999$a{999_1}", indicator1); retain_field(indicator1)'
    );
    my $record = $importer->first;
    is_deeply $record->{indicator1}, 'Z', 'marc_spec(999$a{_1}, indicator1)';
}

note 'marc_spec(650[1]{245_1}, indicator1)     indicator1: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245_1}", indicator1); retain_field(indicator1)'
    );
    my $record = $importer->first;
    ok !$record->{indicator1}, 'marc_spec(650[1]{245_1}, indicator1)';
}

note 'marc_spec(650[1]{245__1}, indicator2)     indicator1: "Beta"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245__1}", indicator2); retain_field(indicator2)'
    );
    my $record = $importer->first;
    is_deeply $record->{indicator2}, 'Beta', 'marc_spec(650[1]{245__1}, indicator2)';
}

note 'marc_spec(650[1]{245__0}, indicator2)     indicator2: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245__0}", indicator2); retain_field(indicator2)'
    );
    my $record = $importer->first;
    ok !$record->{indicator2}, 'marc_spec(650[1]{245__0}, indicator2)';
}

note 'marc_spec(650[1]{245_01}, indicators)     indicator1: "Beta"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245_01}", indicators); retain_field(indicators)'
    );
    my $record = $importer->first;
    is_deeply $record->{indicators}, 'Beta', 'marc_spec(650[1]{245_01}, indicators)';
}

note 'marc_spec(650[1]{245_00}, indicators)     indicator2: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("650[1]{245_00}", indicators); retain_field(indicators)'
    );
    my $record = $importer->first;
    ok !$record->{indicators}, 'marc_spec(650[1]{245_00}, indicators)';
}


note 'marc_spec(999{245_00|$a=\Y}, or)     or: "XY"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999{245_00|$a=\Y}", or); retain_field(or)'
    );
    my $record = $importer->first;
    is_deeply $record->{or}, 'XY', 'marc_spec(999{245_00|$a=\Y}, or)';
}

note 'marc_spec(999$a[#]{245_00|$a=\Y}, or)     or: "Y"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999$a[#]{245_00|$a=\Y}", or); retain_field(or)'
    );
    my $record = $importer->first;
    is_deeply $record->{or}, 'Y', 'marc_spec(999$a[#]{245_00|$a=\Y}, or)';
}

note 'marc_spec(999$a[#]{245_00}{$a=\Y}, and)     and: undef';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999$a[#]{245_00}{$a=\Y}", and); retain_field(and)'
    );
    my $record = $importer->first;
    ok !$record->{and}, 'marc_spec(999$a[#]{245_00}{$a=\Y}, and)';
}

note 'marc_spec(999$a[#]{245_01}{$a=\Y}, and)     and: "Y"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999$a[#]{245_01}{$a=\Y}", and); retain_field(and)'
    );
    my $record = $importer->first;
    is_deeply $record->{and}, 'Y', 'marc_spec(999$a[#]{245_01}{$a=\Y}, and)';
}

note 'marc_spec(999$a[#]{245_01}{$a=\Foo|$a=\Y}, and)     and: "Y"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec("999$a[#]{245_01}{$a=\Foo|$a=\Y}", and); retain_field(and)'
    );
    my $record = $importer->first;
    is_deeply $record->{and}, 'Y', 'marc_spec(999$a[#]{245_01}{$a=\Foo|$a=\Y}, and)';
}


done_testing;
