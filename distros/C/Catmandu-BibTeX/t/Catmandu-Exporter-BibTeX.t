use strict;
use warnings;
use Clone qw(clone);
use Test::More;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Exporter::BibTeX';
  use_ok($pkg);
}
require_ok($pkg);

# don't touch this! Exporter adds newline at the end.
my $bibtex = <<TEX;
\@inproceedings{2602779,
  author       = {Boukricha, Hana and Wachsmuth, Ipke and Carminati, Maria Nella and Knoeferle, Pia and Müller-Leßmann, Stephan},
  language     = {English},
  publisher    = {IEEE},
  title        = {A Computational Model of Empathy: Empirical Evaluation},
  year         = {2013},
}

TEX

my $data = {
	_citekey => 2602779,
	_type => 'inproceedings',
	author => ["Boukricha, Hana", "Wachsmuth, Ipke", "Carminati, Maria Nella", "Knoeferle, Pia", "Müller-Leßmann, Stephan"],
	language => 'English',
	publisher => 'IEEE',
	year => 2013,
	title => 'A Computational Model of Empathy: Empirical Evaluation',
};

my $data2 = clone($data);

my $bibtex_out;
my $exporter = $pkg->new(file => \$bibtex_out);

isa_ok($exporter, $pkg);

can_ok($exporter, 'add');

can_ok($exporter, 'add_many');

$exporter->add($data);

is($bibtex, $bibtex_out, "compare output");

is_deeply($data, $data2, "exporter is idempotent");

done_testing;
