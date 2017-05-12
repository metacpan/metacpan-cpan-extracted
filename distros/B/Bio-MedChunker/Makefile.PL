use inc::Module::Install;

name            ('Bio-MedChunker');
abstract        ('NP chunker for MEDLINE texts');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Bio/MedChunker.pm');
license         ('perl');

requires        ('Bio::Medpost');
build_requires  ('Test::More');
auto_install();

&WriteAll;

