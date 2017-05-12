use Test::More tests => 1;

use strict;
use Data::HTMLDumper;

#----------------------------------------------------------------

Data::HTMLDumper->actions(MyOutput->new());

my $list = [ 'phil', 'crow' ];

my @dump = split /\n/, Data::HTMLDumper->Dump([$list], ['list']);

my @correct = split /\n/, q{<table border='1'><tr><th>$</th><th>list</th></tr>
<tr><td>phil</td>
<td>crow</td>
</tr></table>
};

is_deeply(\@dump, \@correct, "Dump uses names");

package MyOutput;

use base 'Data::HTMLDumper::Output';

sub expression {
    my $self = shift;
    my %item = @_;

    return "<table border='1'><tr><th>$item{SIGIL}</th>"
         . "<th>$item{ID_NAME}</th></tr>\n"
         . "$item{item}</table>\n";
}
