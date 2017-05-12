#!/usr/bin/perl -w
use strict;
use Convert::AcrossLite;

my $ac = Convert::AcrossLite->new();
$ac->in_file('/home/doug/puzzles/Easy.puz');
$ac->out_file('/home/doug/puzzles/Easy.xml');
$ac->parse_file;

my $rows = $ac->get_rows;
my $columns = $ac->get_columns;
my $title = convert_entities($ac->get_title);
my $author = convert_entities($ac->get_author);
my $copyright = convert_entities($ac->get_copyright);

my $xml;

$xml = qq!<?xml version="1.0" ?>\n!;
$xml .= qq!<crowssword rows="$rows" columns="$columns">\n!;
$xml .= qq!<title>$title</title>\n!;
$xml .= qq!<author>$author</author>\n!;
$xml .= qq!<copyright>$copyright</copyright>\n!;


my $across = $ac->get_across;
my %across = %$across;

$xml .= qq!<across>\n!;
foreach my $key (sort { $a <=> $b } keys %across) {
    my $solution = convert_entities($across{$key}{solution});
    my $clue = convert_entities($across{$key}{clue});
    $xml .= qq!  <entry number="$across{$key}{clue_number}" !;
    $xml .= qq!answer="$solution" !;
    $xml .= qq!clue="$clue" !;
    $xml .= qq!row="$across{$key}{row}" !;
    $xml .= qq!col="$across{$key}{column}" !;
    $xml .= qq!length="$across{$key}{length}"/>\n!;
}
$xml .= qq!</across>\n!;

my $down = $ac->get_down;
my %down = %$down;

$xml .= qq!<down>\n!;
foreach my $key (sort { $a <=> $b } keys %down) {
    my $solution = convert_entities($down{$key}{solution});
    my $clue = convert_entities($down{$key}{clue});
    $xml .= qq!  <entry number="$down{$key}{clue_number}" !;
    $xml .= qq!answer="$solution" !;
    $xml .= qq!clue="$clue" !;
    $xml .= qq!row="$down{$key}{row}" !;
    $xml .= qq!col="$down{$key}{column}" !;
    $xml .= qq!length="$down{$key}{length}"/>\n!;
}
$xml .= qq!</down>\n!;
$xml .= qq!</crossword>!;

if(defined $ac->out_file) {
    my $PUZ_OUT = $ac->out_file;

    open FH, ">$PUZ_OUT" or die "Can't open $PUZ_OUT: $!";
    print FH $xml;
    close FH;
} else {
    print $xml;
}

sub convert_entities {
    my $line = shift;

    # Take care of entities
    $line =~ s/&/&amp;/g;
    $line =~ s/</&lt;/g;
    $line =~ s/>/&gt;/g;
    $line =~ s/"/&quot;/g;

    return $line;
}
