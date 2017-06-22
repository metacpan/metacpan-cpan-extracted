use strict;
use warnings;
use Test::More;
use Catmandu;

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:datafield ind1=" " ind2=" " tag="245">
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
            <marc:subfield code="b">a</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Beta</marc:subfield>
            <marc:subfield code="b">b</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Gamma</marc:subfield>
            <marc:subfield code="b">c</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">X</marc:subfield>
            <marc:subfield code="a">Y</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">Z</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC

note "
---
".'marc_spec(245,title)     title: "Title / Name"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, 'Title / Name', 'marc_spec(245,title)';
}

note "
---
".'marc_spec(245$a,title)    title: "Title / "';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245$a,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, 'Title / ', 'marc_spec(245$a,title)';
}

note "
---
".'marc_spec(245,title.$append)     title: [ "Title / Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title.$append); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, ['Title / Name'], 'marc_spec(245,title.$append)';
}

note "
---
".'marc_spec(245$a$c,title.$append)     title: [ "Title / Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245$a$c,title.$append); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, ['Title / Name'], 'marc_spec(245$a$c,title.$append)';
}


note "
---
".'add_field(title.$first, "first"); marc_spec(245,title.$append)     title: ["first", "Title / Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'add_field(title.$first, "first"); marc_spec(245,title.$append); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, ['first', 'Title / Name'], 'marc_spec(245,title.$append)';
}

note "
---
".'marc_spec(245$a,title.$append)    title: [ "Title / " ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245$a,title.$append); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, ['Title / '], 'marc_spec(245$a.$append,title)';
}

note "
---
".'marc_spec(245,title, split:1)    title: [ "Title / ", "Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title, split:1); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, [ 'Title / ', 'Name' ],
        'marc_spec(245,title, split:1)';
}

note "
---
".'marc_spec(245,title.$append, split:1)    title: [ [ "Title / ", "Name" ] ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title.$append, split:1); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, [[ 'Title / ', 'Name' ]], 'marc_spec(245a,title.$append,split:1)';
}

note "
---
".'marc_spec(245,title, split:1, nested_arrays:1)    title: [ [ "Title / ", "Name" ] ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title, split:1, nested_arrays:1); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, [[ 'Title / ', 'Name' ]], 'marc_spec(245, title, split:1, nested_arrays:1)';
}

note "
---
".'marc_spec(245,title.$append, split:1, nested_arrays:1)    title: [[ [ "Title / ", "Name" ] ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(245,title.$append, split:1, nested_arrays:1); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title}, [[[ 'Title / ', 'Name' ]]], 'marc_spec(245a,title.$append,split:1, nested_arrays:1)';
}

note "
---
".'marc_spec(500,note)  note: "ABCD"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500,note); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, 'ABCD', 'marc_spec(500,note)';
}

note "
---
".'marc_spec(500$a,note)     note: "ABC"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, 'ABC', 'marc_spec(500$a,note)';
}

note "
---
".'marc_spec(500$a,note, invert:1)     note: "D"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note,invert:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, 'D', 'marc_spec(500$a,note,invert:1)';
}

note "
---
".'marc_spec(500,note.$append)  note: [ "ABCD" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => ' marc_spec(500,note.$append); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, ['ABCD'], ' marc_spec(500,note.$append)';
}

note "
---
".'marc_spec(500,note.$append, join:"#")  note: [ "A#B#C#D" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500,note.$append, join:"#"); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, ['A#B#C#D'], ' marc_spec(500,note.$append, join:"#")';                                           
}

note "
---
".'marc_spec(500$a,note.$append)     note: [ "ABC" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => ' marc_spec(500$a,note.$append); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, ['ABC'], ' marc_spec(500$a,note.$append)';
}

note "
---
".'marc_spec(500$a,note.$append, invert:1)     note: [ "D" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note.$append,invert:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, ['D'], 'marc_spec(500$a,note.$append,invert:1)';
}

note "
---
".'marc_spec(500,note, split:1)     note: [ "A" , "B" , "C" , "D" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500,note, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [ 'A', 'B', 'C', 'D' ], 'marc_spec(500,note, split:1)';
}

note "
---
".'marc_spec(500$x,note, split:1, invert:1)     note: [ "A" , "B" , "C"]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$x,note, split:1, invert:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [ 'A', 'B', 'C' ], 'marc_spec(500$x,note, split:1, invert:1)';
}

note "
---
".'marc_spec(500$a,note, split:1)    note: [ "A" , "B" , "C" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [ 'A', 'B', 'C' ], 'marc_spec(500a,note, split:1)';
}

note
    'marc_spec(500$a,note, split:1, nested_arrays:1)   note: [[ "A" , "B" , "C" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note, split:1, nested_arrays:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [[ "A" , "B" , "C" ]], 'marc_spec(500a,note, split:1)';
}

note "
---
".'marc_spec(500$a,note.$append, split:1)    note : [[ "A" , "B" , "C" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note.$append, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [ [ 'A', 'B', 'C' ] ], 'marc_spec(500$a,note.$append, split:1)';
}

note "
---
".'marc_spec(500$x,note.$append, split:1, invert:1)    note : [[ "A" , "B" , "C" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$x,note.$append, split:1, invert:1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [ [ 'A', 'B', 'C' ] ],
        'marc_spec(500$x,note.$append, split:1, invert:1)';
}

note
    'marc_spec(500$a,note.$append, split:1, nested_arrays: 1)  note : [[[ "A" , "B" , "C" ]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(500$a,note.$append, split:1, nested_arrays: 1); retain_field(note)'
    );
    my $record = $importer->first;
    is_deeply $record->{note}, [[[ "A" , "B" , "C" ]]], 'marc_spec(500$a,note.$append, split:1, nested_arrays: 1)';
}

note "
---
".'marc_spec(650,subject)   subject: "AlphaaBetabGammac"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650,subject); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, 'AlphaaBetabGammac', 'marc_spec(650,subject)';
}

note "
---
".'marc_spec(650$a,subject)  subject: "AlphaBetaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650$a,subject) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, 'AlphaBetaGamma', 'marc_spec(650$a,subject)';
}

note "
---
".'marc_spec(650[0]$a,subject)  subject: "Alpha"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650[0]$a,subject) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, 'Alpha', 'marc_spec(650[0]$a,subject)';
}

note "
---
".'marc_spec(650$a/0,subject)  subject: "ABG"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650$a/0,subject) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, 'ABG', 'marc_spec(650$a/0,subject)';
}

note "
---
".'marc_spec(650$a/#,subject,invert:1)  subject: "AlphBetGamm"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650$a/#,subject,invert:1) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, 'AlphBetGamm', 'marc_spec(650$a/#,subject,invert:1)';
}

note "
---
".'marc_spec(650$a,subject.$append)  subject: [ "Alpha", "Beta" , "Gamma" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650$a,subject.$append); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ 'Alpha', 'Beta', 'Gamma' ], 'marc_spec(650$a,subject.$append)';
}

note "
---
".'marc_spec(650$a,subject, split:1)     subject: [ "Alpha", "Beta" , "Gamma" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(650$a,subject, split:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ 'Alpha', 'Beta', 'Gamma' ], 'marc_spec(650$a,subject, split:1)';
}

note "
---
".'marc_spec(650$a,subject.$append, split:1)     subject: [[ "Alpha" , "Beta" , "Gamma" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_spec(650$a,subject.$append, split:1) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ [ 'Alpha', 'Beta', 'Gamma' ] ], 'marc_spec(650$a,subject.$append, split:1) ';
}

note "
---
".'marc_spec(650,subject, nested_arrays:1)    subject: [["Alpha", "a"], ["Beta", "b"] , ["Gamma", "c"]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_spec(650,subject, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ ['Alpha', 'a'], ['Beta', 'b'], ['Gamma', 'c'] ], 'marc_spec(650,subject, nested_arrays:1)';
}

note "
---
".'marc_spec(650$a$b,subject, nested_arrays:1)    subject: [["Alpha", "a"], ["Beta", "b"] , ["Gamma", "c"]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_spec(650$a$b,subject, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ ['Alpha', 'a'], ['Beta', 'b'], ['Gamma', 'c'] ], 'marc_spec(650,subject, nested_arrays:1)';
}

note "
---
".'marc_spec(650$a$b,subject.$append, nested_arrays:1)    subject: [[["Alpha", "a"], ["Beta", "b"] , ["Gamma", "c"]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_spec(650$a$b, subject.$append, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ [ ['Alpha', 'a'], ['Beta', 'b'], ['Gamma', 'c'] ] ], 'marc_spec(650$a$b,subject.$append, nested_arrays:1)';
}

note "
---
".'marc_spec(650$a,subject, split:1, nested_arrays:1)    subject: [["Alpha"], ["Beta"] , ["Gamma"]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_spec(650$a,subject, split:1, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is_deeply $record->{subject}, [ ['Alpha'], ['Beta'], ['Gamma'] ], 'marc_spec(650$a,subject, split:1, nested_arrays:1)';
}

note "
---
".'marc_spec(999,local)     local: "XYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999,local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, 'XYZ', 'marc_spec(999,local)';
}

note "
---
".'marc_spec(999$a,local)    local: "XYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a,local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, 'XYZ', 'marc_spec(999$a,local)';
}

note "
---
".'marc_spec(999$a[0],local)    local: "XZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[0],local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, 'XZ', 'marc_spec(999$a[0],local)';
}

note "
---
".'marc_spec(999$a[#],local)    local: "YZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[#],local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, 'YZ', 'marc_spec(999$a[#],local)';
}

note "
---
".'marc_spec(999$a[#],local,invert:1)    local: "X"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[#],local,invert:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, 'X', 'marc_spec(999$a[#],local,invert:1)';
}

note "
---
".'marc_spec(999$a,local.$append)    local: [ "XY", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a,local.$append); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ 'XY', 'Z' ], 'marc_spec(999$a,local.$append)';
}

note "
---
".'marc_spec(999$a[0],local.$append)    local: [ "X", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[0],local.$append); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ 'X', 'Z' ], 'marc_spec(999$a[0],local.$append)';
}

note "
---
".'marc_spec(999$a,local, split:1)   local: [ "X" , "Y", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a,local, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ 'X', 'Y', 'Z' ], 'marc_spec(999$a,local, split:1)';
}


note "
---
".'marc_spec(999$a[0],local, split:1)   local: [ "X" , "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[0],local, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ 'X', 'Z' ], 'marc_spec(999$a[0],local, split:1)';
}

note "
---
".'marc_spec(999$a[0],local, split:1, invert:1)   local: [ "Y" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[0],local, split:1, invert:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ 'Y' ], 'marc_spec(999$a[0],local, split:1, invert:1)';
}

note "
---
".'marc_spec(999$a,local.$append, split:1)   local: [[ "X" , "Y", "Z" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a,local.$append, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ [ 'X', 'Y', 'Z' ] ], 'marc_spec(999$a,local.$append, split:1)';
}

note "
---
".'marc_spec(999$a[0],local.$append, split:1)   local: [[ "X" , "Z" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a[0],local.$append, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ [ 'X', 'Z' ] ], 'marc_spec(999$a[0],local.$append, split:1)';
}


note "
---
".'marc_spec(999$a,local, nested_arrays:1)  local: [ ["X" , "Y"] , ["Z"] ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix => 'marc_spec(999$a,local, nested_arrays:1); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, [ [ 'X', 'Y' ], ['Z'] ], 'marc_spec(999$a,local, nested_arrays:1) ';
}

note "
---
".'marc_spec(999$a,local.$append, join:" ")     local: [ "X Y", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(999$a,local.$append, join:" "); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local}, ['X Y', 'Z'], 'marc_spec(999$a,local.$append, join:" ")';
}

note "
---
".'marc_spec(...$a, all.$append)    all: [ "Title / ", "ABC", "Alpha", "Beta", "Gamma", "XY", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(...$a, all.$append); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [ "Title / ", "ABC", "Alpha", "Beta", "Gamma", "XY", "Z" ], 'marc_spec(...$a, all.$append)';
}

note "
---
".'marc_spec(..., all.$append)    all: [ "Title / Name", "ABCD", "Alphaa", "Betab", "Gammac", "XY", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(..., all.$append); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [ "                        ", "Title / Name", "ABCD", "Alphaa", "Betab", "Gammac", "XY", "Z" ], 'marc_spec(..., all.$append)';
}

note "
---
".'marc_spec(...$a, all, split:1)    all: [ "Title / " , "A" , "B" , "C", "Alpha" , "Beta" , "Gamma" , "X" , "Y", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(...$a, all, split:1); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [ "Title / " , "A" , "B" , "C", "Alpha" , "Beta" , "Gamma" , "X" , "Y", "Z" ], 'marc_spec(...$a, all, split:1)';
}

note "
---
".'marc_spec(...$a, all.$append, split:1)    all: [[ "Title / " , "A" , "B" , "C", "Alpha" , "Beta" , "Gamma" , "X" , "Y", "Z" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(...$a, all.$append, split:1); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [[ "Title / " , "A" , "B" , "C", "Alpha" , "Beta" , "Gamma" , "X" , "Y", "Z" ]], 'marc_spec(...$a, all.$append, split:1)';
}

    
note "
---
".'marc_spec(...$a, all, split:1, nested_arrays:1)    all: [["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(...$a, all, split:1, nested_arrays:1); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [ ["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]], 'marc_spec(...$a, all, split:1, nested_arrays:1)';
}

note "
---
".'marc_spec(...$a, all.$append, split:1, nested_arrays:1)    all: [[ ["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_spec(...$a, all.$append, split:1, nested_arrays:1); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, [[ ["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]]], 'marc_spec(...$a, all.$append, split:1, nested_arrays:1)';
                                                           
}

note "
---
".'add_field(all.$first,"first"); marc_spec(...$a, all.$append, split:1, nested_arrays:1)    all: ["first",[ ["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'add_field(all.$first,"first");  marc_spec(...$a, all.$append, split:1, nested_arrays:1); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all}, ["first",[ ["Title / "], ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"]]], 'marc_spec(...$a, all.$append, split:1, nested_arrays:1)';
}

done_testing;
