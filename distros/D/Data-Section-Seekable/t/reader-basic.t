#!perl

use 5.010;
use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::Exception;
use Test::More 0.98;

use Data::Section::Seekable::Reader;

my $reader = Data::Section::Seekable::Reader->new;

is($reader->read_part('part1'), "This is part1\n", "part1 content");
is($reader->read_part('part2'), "This is part\ntwo\n", "part2 content");
dies_ok { $reader->read_part('part3') } "attempt to read unknown part -> dies";

is_deeply($reader->read_extra('part1'), undef, "part1 extra");
is($reader->read_extra('part2'), "extra,info", "part2 extra");
dies_ok { $reader->read_extra('part3') } "attempt to read extra for unknown part -> dies";

is_deeply([$reader->parts()], ["part1","part2"], "parts()");

# test empty/no parts
{
    my ($fh, $filename) = tempfile();
    print $fh "Data::Section::Seekable v1\n\n";
    close $fh; open $fh, "<", $filename;
    my $reader = Data::Section::Seekable::Reader->new(handle=>$fh);
    is_deeply([$reader->parts], []);
}

{
    my ($fh, $filename) = tempfile();
    print $fh "Data::Section::Seekable v1\nfoo,0,1\n\nx";
    close $fh; open $fh, "<", $filename;
    my $reader = Data::Section::Seekable::Reader->new(handle=>$fh);
    is($reader->read_part('foo'), 'x');
}

subtest "ignore garbage before" => sub {
    my ($fh, $filename) = tempfile();
    print $fh "garbage\nanother garbage\n\nData::Section::Seekable v1\nfoo,0,1\n\nx";
    close $fh; open $fh, "<", $filename;
    my $reader = Data::Section::Seekable::Reader->new(handle=>$fh);
    is($reader->read_part('foo'), 'x');
};

{
    my ($fh, $filename) = tempfile();
    close $fh; open $fh, "<", $filename;
    dies_ok { Data::Section::Seekable::Reader->new(handle=>$fh) } "empty section -> dies";
}

{
    my ($fh, $filename) = tempfile();
    print $fh "Header\n";
    close $fh; open $fh, "<", $filename;
    dies_ok { Data::Section::Seekable::Reader->new(handle=>$fh) } "no header found -> dies";
}

{
    my ($fh, $filename) = tempfile();
    print $fh "Data::Section::Seekable v1\n";
    close $fh; open $fh, "<", $filename;
    dies_ok { Data::Section::Seekable::Reader->new(handle=>$fh) } "empty toc -> dies";
}

{
    my ($fh, $filename) = tempfile();
    print $fh "Data::Section::Seekable v1\nfoo\n";
    close $fh; open $fh, "<", $filename;
    dies_ok { Data::Section::Seekable::Reader->new(handle=>$fh) } "invalid toc -> dies";
}

{
    my ($fh, $filename) = tempfile();
    print $fh "Data::Section::Seekable v1\nfoo,0,10\n";
    close $fh; open $fh, "<", $filename;
    dies_ok { Data::Section::Seekable::Reader->new(handle=>$fh) } "no blank line after toc -> dies";
}

done_testing;

__DATA__
Data::Section::Seekable v1
part1,0,14
part2,14,17,extra,info

This is part1
This is part
two
