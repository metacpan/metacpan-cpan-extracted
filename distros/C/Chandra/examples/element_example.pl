#!/usr/bin/env perl
#
# Example: Element API — build a UI tree in Perl, render to HTML
#
# Demonstrates Chandra::Element with event handlers that call back to Perl.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;
use Chandra::Element;

my @items;
my $next_id = 1;

my $app = Chandra::App->new(
    title  => 'Element Example',
    width  => 500,
    height => 450,
    debug  => 1,
);

sub build_ui {
    Chandra::Element->new({
        tag => 'div',
        id  => 'app',
        style => { 'font-family' => '-apple-system, BlinkMacSystemFont, sans-serif', padding => '20px' },
        children => [
            { tag => 'h1', data => 'Shopping List', style => 'color: #333' },
            {
                tag => 'div',
                style => { display => 'flex', gap => '8px', 'margin-bottom' => '16px' },
                children => [
                    {
                        tag         => 'input',
                        type        => 'text',
                        id          => 'new-item',
                        placeholder => 'Add item...',
                        style       => 'flex:1; padding:8px; border:1px solid #ccc; border-radius:4px; font-size:14px',
                    },
                    {
                        tag     => 'button',
                        data    => 'Add',
                        style   => 'padding:8px 20px; background:#4CAF50; color:#fff; border:none; border-radius:4px; cursor:pointer; font-size:14px',
                        onclick => sub {
                            $app->dispatch_eval(
                                "var v=document.getElementById('new-item').value;" .
                                "if(v){window.chandra.invoke('add_item',[v]).then(function(){" .
                                "document.getElementById('new-item').value='';});}"
                            );
                        },
                    },
                ],
            },
            build_list(),
        ],
    });
}

sub build_list {
    return {
        tag => 'ul',
        id  => 'item-list',
        style => 'list-style:none; padding:0',
        children => [
            map {
                my $item = $_;
                {
                    tag   => 'li',
                    id    => "item-$item->{id}",
                    style => 'display:flex; justify-content:space-between; align-items:center; padding:10px; margin:4px 0; background:#f9f9f9; border-radius:4px',
                    children => [
                        { tag => 'span', data => $item->{name}, style => 'font-size:14px' },
                        {
                            tag   => 'button',
                            data  => 'x',
                            style => 'background:#e74c3c; color:#fff; border:none; border-radius:50%; width:24px; height:24px; cursor:pointer; font-size:12px',
                            onclick => sub {
                                $app->dispatch_eval(
                                    "window.chandra.invoke('remove_item',[$item->{id}])"
                                );
                            },
                        },
                    ],
                }
            } @items
        ],
    };
}

$app->bind('add_item', sub {
    my ($name) = @_;
    push @items, { id => $next_id++, name => $name };
    print "[Perl] Added: $name\n";
    re_render();
    return 1;
});

$app->bind('remove_item', sub {
    my ($id) = @_;
    @items = grep { $_->{id} != $id } @items;
    print "[Perl] Removed item $id\n";
    re_render();
    return 1;
});

sub re_render {
    my $list = Chandra::Element->new(build_list());
    $app->update('#item-list', $list);
}

$app->set_content(build_ui());

print "Starting element example...\n";
$app->run;
print "Done.\n";

=head1 NAME

Element Example - Build a dynamic UI tree in Perl using Chandra::Element

=head1 DESCRIPTION

This example demonstrates how to use the C<Chandra::Element> module to construct a dynamic user interface in Perl. It creates a simple shopping list application where users can add and remove items. The UI is built as a tree of elements, and event handlers are defined in Perl that can be called from JavaScript when buttons are clicked. The example also shows how to update the UI by re-rendering parts of it when the underlying data changes.

=cut
