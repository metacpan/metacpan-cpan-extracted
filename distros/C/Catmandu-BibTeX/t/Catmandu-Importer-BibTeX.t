use Test2::V0;
use Catmandu::Importer::BibTeX;

my $data = [
    {
        _citekey => '2602779',
        type     => 'inproceedings',
        author   => [
            'Boukricha, Hana',
            'Wachsmuth, Ipke',
            'Carminati, Maria Nella',
            'Knoeferle, Pia'
        ],
        editor    => ['Turing, Alan',],
        language  => 'English',
        publisher => 'IEEE',
        title     => 'A Computational Model of Empathy: Empirical Evaluation',
        year      => '2013',
    },
    {
        _citekey => '1890757',
        type     => 'article',
        author   => ['γλώσσα',],
        journal  => 'Journal of Physical Agents',
        pages    => '21--32',
        title =>
            'Domestic Applications for social robots - a user study on appearance and function',
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

my $importer = Catmandu::Importer::BibTeX->new(file => \$bibtex);

can_ok($importer, 'each');

isa_ok $importer, "Catmandu::Importer::BibTeX";

is $importer->to_array, $data;

done_testing;
