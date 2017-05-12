package Convert::CharMap::UCM;
use 5.006;
use strict;
use warnings;
use charnames ();

our $VERSION = '0.10';

sub in {
    # XXX: To be written
    die "UCM->in not yet implemented.";
}

sub out {
    my $class = shift;
    my %c = %{shift->{characterMapping}};
    my $o = '';
    my $sub = '';
    $sub .= "\\x$_" for ($a->{assignments}{sub} =~ m/([A-F\d]{2})/g);
    $o .= << ".";
<code_set_name> "$c{id}"
<mb_cur_min> 1
<mb_cur_max> 2
<subchar> $sub
#
CHARMAP
.

    my @lines;
    foreach my $set ([a => 0], [fbu => 1], [fub => 3]) {
	my $array = $c{assignments}{$set->[0]} or next;
	my $trail = " |$set->[1]";
	foreach my $a (@{$array}) {
	    my $l = "<U$a->{u}> ";
	    $l .= "\\x$_" for ($a->{b} =~ m/([A-F\d]{2})/g);
	    $l .= $trail;
	    if (my $c = charnames::viacode(hex($a->{u}))) {
		$l .= " # $c";
	    }
	    push @lines, [$l => hex($a->{u})];
	}
    }

    $o .= join("\n", map $_->[0], sort { $a->[1] <=> $b->[1] } @lines);
    $o .= "\nEND CHARMAP\n";
    return $o;
}

1;
