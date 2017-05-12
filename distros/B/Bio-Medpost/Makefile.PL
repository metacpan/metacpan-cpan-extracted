use inc::Module::Install;

use File::Spec::Functions;
my $varpath = catfile(qw(lib Bio Medpost Var.pm));
print "Please enter the absolute path of medpost [blank to ignore]\n >> ";
chomp($p = <STDIN>);
#print $p,$/;
#print $varpath.$/;
`perl -i -pe "s('.*';)('$p';);" $varpath` if $p;


name            ('Bio-Medpost');
abstract        ('Part of speech tagger for MEDLINE text');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Bio/Medpost.pm');
license         ('perl');

build_requires  ('Test::More');
auto_install();

&WriteAll;

