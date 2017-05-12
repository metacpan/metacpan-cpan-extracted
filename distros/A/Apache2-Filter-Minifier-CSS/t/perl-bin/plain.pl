use MY::slurp;
use File::Spec::Functions qw(catfile);
my $r = shift;
$r->content_type('text/plain');
print slurp( catfile($r->document_root, 'test.txt') );
