#!/usr/bin/perl
# vim: set ts=4 sw=4 tw=78 et si:
#
# finish-htmlrfc
#
use 5.010;
use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use HTML::TreeBuilder;

my %opt;

GetOptions( \%opt,
    'help|?', 'manual')
    or pod2usage(2);

pod2usage(-exitval => 0, -verbose => 1, -input => \*DATA) if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2, -input => \*DATA) if ($opt{manual});

while (my $fname = shift) {
    my $tree = HTML::TreeBuilder->new();

    $tree->store_declarations(0);
    $tree->store_pis(0);

    $tree->parse_file($fname);

    add_id_to_name_in_anchor($tree);
    change_href($tree,qr|./rfc\d+|,'');
    change_href($tree,qr|./draft-.+|,'');
    change_href($tree,qr|/rfcdiff|,'');
    change_href($tree,qr|../html|,'');
    cleanup_body($tree);
    cleanup_div($tree);
    delete_a_name($tree);
    delete_br($tree);
    delete_span_noprint($tree);
    shorten_local_href($tree,qr/#section-\d+/);
    shorten_local_href($tree,qr/#appendix-[A-Z]+/);

    my $content = $tree->as_HTML();

    print STDOUT qq(<?xml version="1.0" encoding="UTF-8"?>\n),
                 qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"),
                 qq( "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">\n),
                 $content;

    $tree->delete();
}

sub add_id_to_name_in_anchor {
    my ($tree) = @_;

    my @anchors = $tree->look_down('_tag' => 'a',
        'name' => qr//,
        'id' => undef,
    );

    foreach my $a (@anchors) {
        my $name = $a->attr('name');
        $a->attr('id', $name);
    }
} # add_id_to_name_in_anchor

sub change_href {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'a',
        'href' => $from,
    );

    foreach my $a (@anchors) {
        $a->attr('href', $to);
    }
} # change_href()

sub cleanup_body {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'body',
    );

    foreach my $a (@anchors) {
        $a->attr('onload', undef);
    }
} # cleanup_body()

sub cleanup_div {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'div',
        sub { $_[0]->{onmouseout} or $_[0]->{onmouseover} or $_[0]->{onclick} },
    );

    foreach my $a (@anchors) {
        $a->attr('onclick', undef);
        $a->attr('onmouseout', undef);
        $a->attr('onmouseover', undef);
    }
} # cleanup_div()

sub delete_a_name {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'a',
        'name' => qr//,
    );

    foreach my $a (@anchors) {
        $a->attr('name', undef);
    }
} # delete_a_name()

sub delete_br {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'br', );

    foreach my $a (@anchors) {
        $a->delete();
    }
} # delete_br()

sub delete_span_noprint {
    my ($tree, $from, $to) = @_;

    my @anchors = $tree->look_down('_tag' => 'span',
        'class' => qr//,
        sub { $_[0]->{class} =~ /noprint/; }
    );

    foreach my $a (@anchors) {
#        $a->delete();
        $a->tag('div');
    }
} # delete_span_noprint()

sub shorten_local_href {
    my ($tree, $href) = @_;

    my @anchors = $tree->look_down('_tag' => 'a',
        'href' => qr//,
#        'href' => /^section-\d+\./,
        sub { $_[0]->{href} =~ $href; },
    );

    foreach my $a (@anchors) {
        my $h = $a->attr('href');
        $h =~ s/^($href).*$/$1/;
        $a->attr('href', $h);
    }
} # shorten_local_href()

__END__

=head1 NAME

finish-htmlrfc - do nothing

=head1 SYNOPSIS

 finish-htmlrfc [options]

=head1 OPTIONS

=over 8

=item B<< -help >>

Print a brief help message and exit.

=item B<< -manual >>

Print the manual page and exit.

=back

=head1 DESCRIPTION

This program will do nothing.

=head1 AUTHOR

Mathias Weidner

