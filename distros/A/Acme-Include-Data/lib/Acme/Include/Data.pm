package Acme::Include::Data;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/yes_it_works/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.05';

my $data = __FILE__;
$data =~ s/Data\.pm$/this-is-a-data-file.txt/;

open my $in, "<", $data or die $!;
my $text = '';
while (<$in>) {
    $text .= $_;
}

sub yes_it_works
{
    return $text;
}

1;
