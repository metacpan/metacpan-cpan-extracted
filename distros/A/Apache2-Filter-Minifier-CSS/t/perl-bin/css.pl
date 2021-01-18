use File::Slurp qw(slurp);
use File::Spec::Functions qw(catfile);
my $r = shift;
$r->content_type('text/css');
print slurp( catfile($r->document_root, 'test.css') );
