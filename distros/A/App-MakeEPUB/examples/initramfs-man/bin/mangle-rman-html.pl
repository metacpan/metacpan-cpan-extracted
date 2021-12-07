#!/usr/bin/perl
# vim: set ts=4 sw=4 tw=78 et si:
#
# mangle-rman-html
#
use 5.010;
use strict;
use warnings;

use Getopt::Long;
use HTML::TreeBuilder;
use Pod::Usage;

binmode(STDIN,':utf8');

my $doctype = 'DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'
            . ' "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"';
my $xmlns = "http://www.w3.org/1999/xhtml";

my %opt;

GetOptions( \%opt,
    'title=s',
    'help|?', 'manual')
    or pod2usage(2);

pod2usage(-exitval => 0, -verbose => 1, -input => \*DATA) if ($opt{help});
pod2usage(-exitval => 0, -verbose => 2, -input => \*DATA) if ($opt{manual});

my $ht = HTML::TreeBuilder->new();

my $file = shift;

if (! $file or '-' eq $file) {
    local $/;
    undef $/;
    my $input = <>;
    $ht->parse($input);
}
else {
    $ht->parse_file($file);
}

$ht->declaration($doctype);

$ht->attr('xmlns', $xmlns);

if ($opt{title}) {
    my $head = $ht->find('head');
    my $title = $head->find('title');
    $title->delete_content();
    $title->push_content($opt{title});
}

my $body = $ht->find('body');

if ($body->attr('bgcolor')) {
    $body->attr('bgcolor', undef);
}

# Wrap some tags that are directly descending from body in <div>..</div>
foreach my $item_r ($body->content_refs_list) {
    if ('REF' eq ref($item_r) and 'a' eq $$item_r->tag()) {
        my $div = HTML::Element->new('div', class => 'anchor');
        $$item_r->replace_with($div);
        $div->push_content($$item_r);
    }
}

# repair anchors
my @anchors = $ht->look_down('_tag' => 'a');

foreach my $anchor (@anchors) {
    if ($anchor->attr('name')) {
        $anchor->attr('name', undef);
    }
}

print $ht->as_HTML(undef, ' ', {});

$ht->delete;

__END__

=head1 NAME

%TITLE% - do nothing

=head1 SYNOPSIS

 %TITLE% [options]

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

