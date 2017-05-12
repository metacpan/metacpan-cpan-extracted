use strict;
use warnings;

use Test::More tests => 14;

use Brat::Handler;
use Brat::Handler::File;

my $bratfile = Brat::Handler::File->new();
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new() works' );

$bratfile = Brat::Handler::File->new("examples/taln-2012-long-001-resume.ann");
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new(taln-2012-long-001-resume.ann) works' );

ok (scalar(keys %{$bratfile->_terms}) == 21, 'number of read terms ok');

ok (scalar(keys %{$bratfile->_relations}) == 0, 'number of read relations ok');

ok (scalar(keys %{$bratfile->_attributes}) == 0, 'number of read attributes ok');

# warn "==> " . $bratfile->_textSize . "\n";
ok($bratfile->_textSize == 836, 'text size ok');

$bratfile = Brat::Handler::File->new("examples/taln-2012-long-002-resume.ann");
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new(taln-2012-long-002-resume.ann) works' );

ok (scalar(keys %{$bratfile->_terms}) == 36, 'number of read terms ok');
ok ($bratfile->_maxTermId == 36, 'max term id ok');

ok (scalar(keys %{$bratfile->_relations}) == 11, 'number of read relations ok');
ok ($bratfile->_maxRelationId == 11, 'max relation id ok');

ok (scalar(keys %{$bratfile->_attributes}) == 1, 'number of read attributes ok');
ok ($bratfile->_maxAttributeId == 1, 'max attribute id ok');

# warn "==> " . $bratfile->_textSize . "\n";
ok($bratfile->_textSize == 1175, 'text size ok');
