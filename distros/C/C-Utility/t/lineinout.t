use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use C::Utility qw/linein lineout/;
use File::Slurper 'read_lines';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

chdir $Bin or die $!;
my $textin = linein ('status-c-tmpl');
# This is like what is described in ../examples/statuses.pl, but I
# don't want to introduce a dependency on Template here.
my @statuses = (qw/good great super fantastic/);
my $statuses_out = '';
for (@statuses) {
    $statuses_out .= "$_,\n";
}
$textin =~ s/STATUSES/$statuses_out/;
lineout ($textin, 'status.c');
my @l = read_lines ("$Bin/status.c");
is ($l[0], '#line 2 "status-c-tmpl"');
is ($l[3], '#line 5 "status.c"');
is ($l[9], '#line 7 "status-c-tmpl"');
unlink ('status.c') or die $!;
done_testing ();
