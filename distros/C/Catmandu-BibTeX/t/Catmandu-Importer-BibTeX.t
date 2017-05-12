use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Importer::BibTeX';
  use_ok($pkg);
}
require_ok($pkg);

my $data = [
  {
    _citekey => '2602779',
    type => 'inproceedings',
    author => ['Boukricha, Hana', 'Wachsmuth, Ipke', 'Carminati, Maria Nella', 'Knoeferle, Pia'],
    editor => 'Turing, Alan',
    language => 'English',
    publisher => 'IEEE',
    title => 'A Computational Model of Empathy: Empirical Evaluation',
    year => '2013',
  },
  {
    _citekey => '1890757',
    type => 'article',
    author => 'γλώσσα',
    journal => 'Journal of Physical Agents',
    pages => '21--32',
    title => 'Domestic Applications for social robots - a user study on appearance and function',
    year => '2008',
    },
];

my $bibtex = <<TEX;
\@inproceedings{2602779,
  author       = {Boukricha, Hana and Wachsmuth, Ipke and Carminati, Maria Nella and Knoeferle, Pia},
  editor       = {Turing, Alan},
  language     = {English},
  publisher    = {IEEE},
  title        = {A Computational Model of Empathy: Empirical Evaluation},
  year         = {2013},
}
\@article{1890757,
  author       = {γλώσσα},
  journal      = {Journal of Physical Agents},
  pages        = {21--32},
  title        = {Domestic Applications for social robots - a user study on appearance and function},
  year         = {2008},
}
TEX

my $importer = $pkg->new(file => \$bibtex);

can_ok ($importer, 'each');

isa_ok $importer, $pkg;

is_deeply $importer->to_array, $data;

done_testing;
