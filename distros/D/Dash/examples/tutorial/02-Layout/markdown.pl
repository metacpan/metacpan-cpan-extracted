## Please see file perltidy.ERR
#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 2 Layout',
    external_stylesheets => $external_stylesheets
);

my $markdown_text = <<ENDOFMARKDOWN;
### Dash and Markdown

Dash apps can be written in Markdown.
Dash uses the [CommonMark](http://commonmark.org/)
specification of Markdown.
Check out their [60 Second Markdown Tutorial](http://commonmark.org/help/)
if this is your first introduction to Markdown!
ENDOFMARKDOWN

$app->layout(
    html->Div( children => [ dcc->Markdown( children => $markdown_text ) ] ) );

$app->run_server();

