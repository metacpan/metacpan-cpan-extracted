use warnings;
use strict;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
use Test::More tests => 6;
use Data::Dumper;

$| = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deepcopy = 1;
BEGIN { use_ok('Data::StreamSerializer') };

sub compare_object($$);

my $subt = {
    suba => 'subb',
    subc => [ qw{ subd sube subf } ],
};
my @h = (
    0,
    \\\[ a => 'b', 'f', \\\'g', \$subt ],
    \\[ c => 'd' ],
    [ e => [ qw( 1 2 3) ] ],
    \\\\{ "привет" => "utf8: строка",
      some => $subt,
      undef => undef,
    }
);
$| = 1;

my $ds = eval Dumper(\@h);

my $sr = new Data::StreamSerializer(\@h);
my $str = '';
ok $sr, 'Constructor';
$sr->block_size( 5 );
while(defined(my $part = $sr->next)) {
    $str .= $part;
}

# note $str;

ok !exists $sr->{data}, "Serialization has been done";
my ($dsh) = eval $str;
ok !$@, "Eval serialized object";
ok compare_object($dsh, \@h), "Source and result objects are the same";
ok compare_object($ds, \@h), "Original object wasn't modified";

sub compare_object($$)
{
    my ($o1, $o2) = @_;
    return 1 if (!defined($o1) and !defined($o2));
    return 0 unless ref($o1) eq ref $o2;
    return $o1 eq $o2 unless ref $o1;                        # SCALAR
    return $o1 eq $o2 if 'Regexp' eq ref $o1;                # Regexp
    return compare_object $$o1, $$o2 if 'SCALAR' eq ref $o1; # SCALARREF
    return compare_object $$o1, $$o2 if 'REF' eq ref $o1;    # REF

    if ('ARRAY' eq ref $o1) {
        return 0 unless @$o1 == @$o2;
        for (0 .. $#$o1) {
            return 0 unless compare_object $o1->[$_], $o2->[$_];
        }
        return 1;
    }

    if ('HASH' eq ref $o1) {
        return 0 unless keys(%$o1) == keys %$o2;

        for (keys %$o1) {
            return 0 unless exists $o2->{$_};
            return 0 unless compare_object $o1->{$_}, $o2->{$_};
        }
        return 1;
    }


    die ref $o1;
}
