use strict;
use warnings;
use Test::More 0.89;

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

my $fasta_output = <<EOT;
>a100
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
>t200
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
TTTTTTTTTTTTTTTTTTTT
>c24
CCCCCCCCCCCCCCCCCCCCCCCC
EOT

my $fasta = request('/fasta');
is $fasta->content,   $fasta_output, 'Fasta rendering';
is $fasta->content_type, 'application/x-fasta', 'content-type is right';

my $default = request('/');
is $default->content, $fasta_output, 'Default format';
is $default->content_type, 'application/x-fasta', 'content-type is right';

done_testing;
