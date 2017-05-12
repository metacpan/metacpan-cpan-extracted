#!/usr/local/bin/perl
use strict;

my $base = qx/perl -MGTop -e 'print GTop->new->proc_mem(\$\$)->size'/;

foreach my $module qw(DateTime DateTimeX::Lite DateTimeX::Lite=Strftime,Arithmetic,Overload,ZeroBase) {
    my $used = qx/perl -Ilib -MGTop -M$module -e 'print GTop->new->proc_mem(\$\$)->size'/;
    my $real = $used - $base;
    print "$module: $real\n";
}