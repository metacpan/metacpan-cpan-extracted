use strict;
use warnings;
use Test::More;
use App::Prove::RunScripts;
use File::Temp qw(tempfile);
use t::Utils qw(app_with_args file);

my ( $fh, $out ) = tempfile();

my $before = file( <<EOM, '.pl' );
use strict;
open my \$fh, '>>', '${out}' or die \$!;
print \$fh "before\t";
close \$fh or die \$!;
EOM

my $t = file( <<EOM, '.t' );
use strict;
use Test::More tests => 1;
open my \$fh, '>>', '${out}' or die \$!;
print \$fh "t\t";
close \$fh or die \$!;
ok 1;
EOM

my $after = file( <<EOM, '.pl' );
use strict;
open my \$fh, '>>', '${out}' or die \$!;
print \$fh "after";
close \$fh or die \$!;
EOM

my $app = app_with_args(
    [ '--before', $before, '--after', $after, '--quiet', $t ] );
$app->run;

my $line = <$fh>;
is $line, "before\tt\tafter", "before and after scripts are called";

done_testing;
