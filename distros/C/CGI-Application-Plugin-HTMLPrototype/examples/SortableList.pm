package SortableList;

use strict;
use warnings;

use base qw(CGI::Application);
use CGI::Application::Plugin::TT;
use CGI::Application::Plugin::HTMLPrototype;
use CGI::Application::Plugin::ViewSource;

sub setup {
    my $self = shift;
    $self->run_modes([qw(
        start
    )]);
}

sub start {
    my $self = shift;

    return $self->tt_process(\*DATA);
}

1;
__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>CGI::Application::Plugin::HTMLPrototype - SortableList Example</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  [% c.prototype.define_javascript_functions %]
  <style>
    .listitem {
        cursor: move;
    }
  </style>
</head>
<body>

<h3>CGI::Application::Plugin::HTMLPrototype - SortableList Example</h3>

<p>Code:  <a href="sortablelist.cgi?rm=view_source">SortableList source</a>

<h4>Sortable lists</h4>

<ul class="sortablelist" id="sortablelist_1">
    <li class="listitem" id="list1_1">Item 1.1</li>
    <li class="listitem" id="list1_2">Item 1.2</li>
    <li class="listitem" id="list1_3">Item 1.3</li>
    <li class="listitem" id="list1_4">Item 1.4</li>
</ul>
<hr>
<ul class="sortablelist" id="sortablelist_2">
    <li class="listitem" id="list1_1">Item 2.1</li>
    <li class="listitem" id="list1_2">Item 2.2</li>
    <li class="listitem" id="list1_3">Item 2.3</li>
    <li class="listitem" id="list1_4">Item 2.4</li>
</ul>

[% c.prototype.sortable_element( 'sortablelist_1' { containment='["sortablelist_1","sortablelist_2"]' } ) %]
[% c.prototype.sortable_element( 'sortablelist_2' { containment='["sortablelist_1","sortablelist_2"]' } ) %]

</body>
</html>
