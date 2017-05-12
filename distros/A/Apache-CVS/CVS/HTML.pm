# $Id: HTML.pm,v 1.11 2003/12/07 00:00:05 barbee Exp $

=head1 NAME

Apache::CVS::HTML - subclass of Apache::CVS that prints HTML

=head1 SYNOPSIS

    <Location /cvs>
        SetHandler perl-script
        PerlHandler Apache::CVS::HTML
        PerlSetVar CVSRoots cvs1=>/usr/local/CVS
        PerlSetVar CSSFile /apache_cvs.css
    </Location>

=head1 DESCRIPTION

This is a subclass of C<Apache::CVS>. Please see its pod page for
definitive documentation. C<Apache::CVS::HTML> override all of the print_*
methods to display directories, files and revisions in HTML tables. Diffs
are displayed as plain text. There is also a little directory indicator at the
top of every page.

=head1 APACHE CONFIGURATION

=item CSSFile

    Path to a Cascading Stylesheet File. A default CSS file is
    provided with this distribution.

    PerlSetVar CSSFile /apache_cvs.css

=head1 CSS CONFIGURATION

The format of the CSS class below are:
    I<name> (B<HTML tag>, B<where this class shows up>)

=item root_link (anchor, everywhere)

=item path_link (anchor, everywhere)

=item directory_link (anchor, directory listings)

=item file_link (anchor, directory listings)

=item graph_link (anchor, file listings)

=item revision_link (anchor, file listings, graph display)

=item directory_sort_link (anchor, directory listinsg)

=item file_sort_link  (anchor, file listings)

=item diff_link (anchor, file listinsg)

=item directory_table (table, directory listing)

=item directory_header_row (tr, directory listing)

=item directory_header (th, directory listing)

=item directory_odd_row (tr, directory listing)

=item directory_even_row (tr, directory listing)

=item directory_data (td, directory listing)

=item file_table (table, file listing)

=item file_header_row (tr, file listing)

=item file_header (th, file listing)

=item file_odd_row (tr, file listing)

=item file_even_row (tr, file listing)

=item file_data (td, file listing)

=cut

package Apache::CVS::HTML;

use strict;

use Apache::CVS();
if ($Apache::CVS::Graph) {
    use Graph::Directed();
}

@Apache::CVS::HTML::ISA = ('Apache::CVS');

$Apache::CVS::HTML::VERSION = $Apache::CVS::VERSION;;

my @time_units = ('days', 'hours', 'minutes', 'seconds');
my @directory_headers = ('filename', 'author', 'number of revisions',
                         'latest revision', 'most recent revision date',
                         'revision age');
my %directory_sorting = (
    'filename' => 'f',
    'author' => 'a',
    'number of revisions' => 'n',
    'most recent revision date' => 'm'
);
my @file_headers = ('revision number', 'author', 'state', 'symbol', 'date',
                    'age', 'comment', 'action');
my %file_sorting = (
    'revision number' => 'r',
    'author' => 'a',
    'state' => 's',
    'date' => 'd',
);
my %css_class = (
    # anchors
    'root_link' =>      'root_link',
    'path_link' =>      'path_link',
    'directory_link' => 'directory_link',
    'file_link' =>      'file_link',
    'graph_link' =>     'graph_link',
    'revision_link' =>  'revision_link',
    'diff_link' =>      'diff_link',
    'file_sort_link' =>  'file_sort_link',
    'directory_sort_link' =>  'directory_sort_link',

    # directory table
    'directory_table' =>      'directory_table',
    'directory_header_row' => 'directory_header_row',
    'directory_header' =>     'directory_header',
    'directory_odd_row' =>    'directory_odd_row',
    'directory_even_row' =>   'directory_even_row',
    'directory_data' =>       'directory_data',

    # file table
    'file_table' =>      'file_table',
    'file_header_row' => 'file_header_row',
    'file_header' =>     'file_header',
    'file_odd_row' =>    'file_odd_row',
    'file_even_row' =>   'file_even_row',
    'file_data' =>       'file_data',
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(shift);

    $self->file_sorting_available(1);
    $self->revision_sorting_available(1);
    $self->{css_file} = $self->request()->dir_config('CSSFile');

    bless ($self, $class);
    return $self;
}

sub sort_files {
    my $self = shift;
    my ($files, $sort_criterion, $ascending) = @_;

    # skip if there are no files
    return unless scalar @{ $files };

    my @sorted_files;
    SWITCH: for ($sort_criterion) {
        /$directory_sorting{'filename'}/ && do {
            @sorted_files = sort { $a->name() cmp $b->name() } @{ $files };
            last;
        };
        /$directory_sorting{'author'}/ && do {
            @sorted_files = sort { $a->revision('last')->author() cmp
                                   $b->revision('last')->author() } @{ $files };
            last;
        };
        /$directory_sorting{'number of revisions'}/ && do {
            @sorted_files =
                sort { $a->revision_count() <=> $b->revision_count() }
                    @{ $files };
            last;
        };
        /$directory_sorting{'most recent revision date'}/ && do {
            @sorted_files = sort { $a->revision('last')->date() <=>
                                   $b->revision('last')->date() } @{ $files };
            last;
        };
        @sorted_files = @{ $files };
    }
    @sorted_files = reverse @sorted_files if $ascending;
    return \@sorted_files;
}

sub _split_revision {
    my $revision = shift;
    my @revision_parts;
    while ($revision =~ s#^(\d+)##) {
        push @revision_parts, $1;
        $revision =~ s#^\.##;
    }
    return \@revision_parts;
}

sub _by_revision {
    my $a_number = _split_revision($a->number());
    my $b_number = _split_revision($b->number());

    my $a_max_index = scalar @{ $a_number };
    my $max_index = $a_max_index;
    my $b_max_index = scalar @{ $b_number };
    $max_index = $b_max_index if ($b_max_index < $max_index);
    for (my $counter = 0; $counter < $max_index; $counter++) {
        if ($a_number->[$counter] > $b_number->[$counter]) {
            return 1;
        } elsif ($a_number->[$counter] < $b_number->[$counter]) {
            return -1;
        } else {
            next;
        }
    }
    return $a_max_index <=> $b_max_index;
}

sub sort_revisions {
    my $self = shift;
    my ($revisions, $sort_criterion, $ascending) = @_;

    # skip if there are no files
    return unless scalar @{ $revisions};

    my @sorted_revisions;
    SWITCH: for ($sort_criterion) {
        /$file_sorting{'revision number'}/ && do {
            @sorted_revisions = sort _by_revision @{ $revisions };
            last;
        };
        /$file_sorting{'author'}/ && do {
            @sorted_revisions = sort { $a->author() cmp $b->author() }
                                     @{ $revisions };
            last;
        };
        /$file_sorting{'state'}/ && do {
            @sorted_revisions = sort { $a->state() cmp $b->state() }
                                @{ $revisions };
            last;
        };
        /$file_sorting{'date'}/ && do {
            @sorted_revisions = sort { $a->date() <=> $b->date() }
                                @{ $revisions };
            last;
        };
        @sorted_revisions = @{ $revisions };
    }
    @sorted_revisions = reverse @sorted_revisions if $ascending;
    return \@sorted_revisions;
}

sub print_error {
    my $self = shift;
    my $error = shift;
    $self->print_http_header();
    $self->print_page_header();
    $error =~ s/\n/<br>/g;
    $self->request()->print($error);
    $self->print_page_footer();
}

sub print_page_header {
    my $self = shift;
    return if $self->page_headers_sent();
    $self->request()->print('<html>
                             <head>
                                <link rel="stylesheet" type="text/css" href="');
    $self->request()->print($self->{css_file});
    $self->request()->print('">
                                <title>Apache::CVS</title>
                             </head>
                             <body bgcolor=white>');
    $self->print_path_links();
    $self->page_headers_sent(1);
}

sub print_page_footer {
    shift->{request}->print('</body></html>');
}

sub print_path_links {
    my $self = shift;
    my ($is_revision) = @_;

    my $rpath = $self->request()->parsed_uri->rpath();
    my $cvsroot = $self->current_root();
    my $filename = $self->path();
    my $cvsroot_path = $self->current_root_path();
    # strip out unnecessary stuff
    $filename =~ s/$cvsroot_path//;
#    $filename =~ s#[^/]*/?$## unless $is_revision;

    # top / root / file
    my $path = qq($rpath/$cvsroot$filename);

    my $link = qq(<a class=$css_class{path_link} href=$rpath>top</a>);
    $link .= qq(:: <a class=$css_class{path_link} href=$rpath/$cvsroot>$cvsroot</a>);

    my $parents;
    foreach ( split m#/#, $filename ) {

        next unless $_;
        $link .= qq(:: <a class=$css_class{path_link} href="$rpath/$cvsroot$parents/$_">$_</a>);
        $parents .= qq(/$_) if $_;
    }

    $link .= q(<p>);

    $self->request()->print($link);
}

sub print_root {
    my $self = shift;
    my $root = shift;
    $self->request()->print('<a class=$css_class{root_link} href="' .
                            $self->request()->parsed_uri->rpath() .
                            qq(/$root">$_</a><br>));
}

sub print_root_list_header {
    my $self = shift;
    $self->request()->print('available cvs roots<p>');
}

sub print_root_list_footer {
    return;
}

sub _print_sortable_headers {
    my $self = shift;
    my ($uri_base, $criterion, $sort_direction, $headers, $sorting,
        $th_css_class, $a_css_class) = @_;
    foreach my $header (@{ $headers}) {

        $self->request()->print(qq|<th class=$th_css_class>|);

        # check to see if this is a sortable field
        if (exists($sorting->{$header})) {

            $self->request()->print(qq|<a class=$a_css_class href="$uri_base?o=|);
            $self->request()->print($sorting->{$header});

            if ($sorting->{$header} eq $criterion) {
                # if we already sorting by this criterion, offer to sort the
                # other way
                my $ascending = ($sort_direction + 1) % 2;
                $self->request()->print(qq|&asc=$ascending|);
            }
            $self->request()->print(qq|">$header</a>|);
        } else {
            $self->request()->print($header);
        }
        $self->request()->print('</th>');
    }
}

sub print_directory_list_header {
    my $self = shift;
    my ($uri_base, $criterion, $sort_direction) = @_;

    $self->request()->print('<table class=$css_class{directory_table}>
                                <tr class=$css_class{directory_header_row}>');

    if ($self->file_sorting_available()) {
        $self->_print_sortable_headers($uri_base, $criterion, $sort_direction,
                                       \@directory_headers,
                                       \%directory_sorting,
                                       $css_class{directory_header},
                                       $css_class{directory_sort_link});
    } else {
        map { $self->request()->print("<th class=$css_class{directory_header}>$_</th>") } @directory_headers;
    }

    $self->request()->print('   </tr>');
}

sub print_directory {
    my $self = shift;
    my ($uri_base, $directory, $row_number) = @_;
    my $uri = $uri_base. $directory->name();
    if ($row_number % 2) {
        $self->request()->print("<tr class=$css_class{directory_odd_row}>");
    } else {
        $self->request()->print("<tr class=$css_class{directory_even_row}>");
    }
    $self->request()->print("<td class=$css_class{directory_data}>
                            <a class=directory_link href=$uri>" .
                                  $directory->name() .
                                  '</a></td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             </tr>');
}

sub print_file {
    my $self = shift;
    my ($uri_base, $file, $row_number) = @_;
    my $uri = $uri_base . $file->name();
    my $revision = $file->revision('last');
    if ($row_number % 2) {
        $self->request()->print("<tr class=$css_class{directory_odd_row}>");
    } else {
        $self->request()->print("<tr class=$css_class{directory_even_row}>");
    }

    $self->request()->print("<td class=$css_class{directory_data}>
                                <a class=file_link href=$uri>"
                                . $file->name() .
                                '</a>
                            </td>');
    $self->request()->print('<td class=$css_class{directory_data}>'
                            . $revision->author()
                            . '</td>');
    $self->request()->print('<td class=$css_class{directory_data}>'
                            . $file->revision_count());

    if ($Apache::CVS::Graph) {
        $self->request()->print(" (<a class=$css_class{graph_link} href=$uri?g>graph</a>)");
    }
    $self->request()->print('</td>');
    $self->request()->print('<td class=$css_class{directory_data}>'
                            . $revision->number()
                            . '</td>');
    $self->request()->print('<td class=$css_class{directory_data}>'
                            . localtime($revision->date())
                            . '</td>');

    my $age = join(', ',
                   map { $revision->age()->{$_} . ' ' . $_ } @time_units);
    $self->request()->print("<td class=$css_class{directory_data}>$age</td>");
    $self->request()->print('</tr>');
}

sub print_plain_file() {
    my ($self, $file, $row_number) = @_;
    if ($row_number % 2) {
        $self->request()->print("<tr class=$css_class{directory_odd_row}>");
    } else {
        $self->request()->print("<tr class=$css_class{directory_even_row}>");
    }
    $self->request()->print('<td class=$css_class{directory_data}>'
                            . $file->name()
                            . '</td>');
    $self->request()->print('<td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td>
                             <td class=$css_class{directory_data}>&nbsp;</td> </tr>');
}

sub print_directory_list_footer {
    my $self = shift;
    $self->request()->print('</table>');
}

sub print_file_list_header {
    my $self = shift;
    my ($uri_base, $criterion, $sort_direction) = @_;

    $self->request()->print('<table class=$css_class{file_table}>
                             <tr class=$css_class{file_header_row}>');

    if ($self->revision_sorting_available()) {
        $self->_print_sortable_headers($uri_base, $criterion, $sort_direction,
                                       \@file_headers, \%file_sorting,
                                       $css_class{file_header},
                                       $css_class{file_sort_link});
    } else {
        map { $self->request()->print("<th class=$css_class{file_header}>$_</th>") } @file_headers;
    }
    $self->request()->print('   </tr>');
}

sub print_file_list_footer {
    my $self = shift;
    $self->request()->print('</table>');
}

sub print_revision {
    my $self = shift;
    my ($uri_base, $revision, $row_number, $diff_revision) = @_;
    my $revision_uri = "$uri_base?r=" . $revision->number();
    my $date = localtime($revision->date());
    my $age = join(', ',
                   map { $revision->age()->{$_} . ' ' . $_ } @time_units);
    my $symbols = $revision->symbol();
    my $symbol = '';
    $symbol = join(', ', @{ $symbols}) if scalar @{ $symbols};
    if ($row_number % 2) {
        $self->request()->print("<tr class=$css_class{file_odd_row}>");
    } else {
        $self->request()->print("<tr class=$css_class{file_even_row}>");
    }
    $self->request()->print("<td class=$css_class{file_data}>
                                <a class=revision_link href=$revision_uri>" .
                                $revision->number()
                            . '</td>' .
                            '<td class=$css_class{file_data}>'
                                . $revision->author()
                            . '</td>' .
                            '<td class=$css_class{file_data}>'
                                . $revision->state()
                            . '</td>' .
                             "<td class=$css_class{file_data}>$symbol</td>
                            <td class=file_data>$date</td>
                            <td class=file_data>$age</td>" .
                             '<td class=$css_class{file_data}>'
                                . $revision->comment()
                            . '</td>');
    if ($diff_revision eq $revision->number()) {
        $self->request()->print('<td class=$css_class{file_data}>selected for diff</td>');
    } else {
        if ($diff_revision) {
            $self->request()->print(qq|<td class=$css_class{file_data}> 
                                    <a class=diff_link href="$uri_base?ds=| .
                                    $revision->number()  .
                                    qq|&dt=$diff_revision">select for diff | .
                                    "with $diff_revision</a>");
        } else {
            $self->request()->print(qq|<td class=$css_class{file_data}>
                                    <a class=diff_link href="$uri_base?ds=| .
                                    $revision->number()  .
                                    '">select for diff</a>');
        }
    }
    $self->request()->print('</tr>');
}

sub print_text_revision {
    my $self = shift;
    my $content = shift;
    $self->request()->print('<pre>');
    $content =~ s/</&lt;/g;
    $content =~ s/>/&gt;/g;
    $self->request()->print($content);
    $self->request()->print('</pre>');
}

sub print_diff {
    my ($self, $diff, $uri_base) = @_;
    my @content;

    eval {
        @content = @{ $diff->content() };
    };
    if ($@) {
        $self->request()->log_error($@);
        $self->print_http_header();
        $self->print_page_header();
        $self->request()->print("<p>Unable to get diff.<br>$@");
        $self->print_page_footer();
        return;
    }

    unless (scalar @content) {
        $self->request()->print('There is no difference between the versions.');
        return;
    }
    if (scalar keys %{ $self->diff_styles()} > 1) {
        # print a bunch of links for the different diff styles
        my ($source_revision, $target_revision);
        eval {
            $source_revision = $diff->source()->number();
            $target_revision = $diff->target()->number();
        };
        if ($@) {
            $self->request()->log_error($@);
            $self->print_http_header();
            $self->print_page_header();
            $self->request()->print("<p>Unable to get diff.<br>$@");
            $self->print_page_footer();
            return;
        }
        $self->request()->print(qq|<a class=diff_link href="$uri_base?ds=$source_revision&dt=$target_revision&dy=$_">$_</a>&nbsp;|) foreach keys %{ $self->diff_styles()};
        $self->request()->print(qq|<br>|);
    }
    $self->request()->print('<pre>');
    while (my $line = shift @content) {
        $line =~ s/</&lt;/g;
        $line =~ s/>/&gt;/g;
        $self->request()->print($line);
    }
    $self->request()->print('</pre>');
}

sub _print_tree_node {
    my ($self, $labels, $node, $uri) = @_;
    $self->request()->print(qq(<a class=$css_class{revision_link} href="$uri?r=$node">$node</a>));
    if (ref $labels eq 'HASH' && exists $labels->{$node} ) {
        my @tags = @{ $labels->{$node} };
        if (scalar @tags) {
            my $tags = join(', ', @tags);
            $self->request()->print(" ($tags)");
        }
    }
    $self->request()->print("\n");
}

sub _print_tree {
    my ($self, $cvs_graph, $uri, $node, $prefix, $depth) = @_;
    my $labels = $cvs_graph->labels();

    # init
    $depth ||= 0;
    $prefix ||= [];
    $node ||= $cvs_graph->root_node();

    if ($depth) {
        my $sub_depth = $depth - 1;
        local $prefix->[$sub_depth] = '+-' if $prefix->[$sub_depth] eq '| ';
        local $prefix->[$sub_depth] = '`-' if $prefix->[$sub_depth] eq '  ';
        $self->request()->print(join('', @{ $prefix}[0..$sub_depth]));
    }

    $self->_print_tree_node($labels, $node, $uri);

    $prefix->[$depth] = '| ';

    my @children = $cvs_graph->graph()->successors($node);
    my $size = scalar(@children) - 1;

    for (0 .. $size) {
        $prefix->[$depth] = '  ' if ($_ == $size);
        $self->_print_tree($cvs_graph, $uri, $children[$_], $prefix, $depth+1);
    }
}

sub print_graph {
    my $self = shift;
    my ($uri_base, $filename, $cvs_graph) = @_;

    $self->request()->print("<p><pre>");
    $self->_print_tree($cvs_graph, "$uri_base/$filename");
    $self->request()->print('</pre>');
}

=head1 SEE ALSO

L<Apache::CVS>

=head1 AUTHOR

John Barbee, F<barbee@veribox.net>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
