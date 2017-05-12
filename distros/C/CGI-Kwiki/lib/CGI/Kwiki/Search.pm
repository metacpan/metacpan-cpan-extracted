package CGI::Kwiki::Search;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
use CGI::Kwiki ':char_classes';

sub process {
    my ($self) = @_;
    my $search = $self->cgi->page_id;
    return
      $self->template->process('display_header') .
      $self->search .
      $self->template->process('basic_footer');
}

sub search {
    my ($self) = @_;
    my $database = $self->database;
    my $search = $self->cgi->search;
    # Detaint query string
    $search =~ s/[^$WORD\ \-\.\^\$\*\|\:]//g;
    my @pages = $database->pages;
    my @results;
    for my $page_id (@pages) {
        next unless $self->is_readable($page_id);
        if ($page_id =~ m{$search}i) {
            push @results, $page_id;
            next;
        }
        my $wiki_text = $database->load($page_id);
        if ($wiki_text =~ m{$search}is) {
            push @results, $page_id;
        }
    }
    my $result = "<h3>";
    if (length $search) {
        $result .= $self->loc("%1 pages found containing '%2'", scalar @results, $search);
    }
    else {
        $result .= $self->loc("%1 pages found", scalar @results);
    }
    $result .= ":</h3>\n";
    my $script = $self->script;
    for my $page_id (sort @results) {
        $page_id =~ s/.*?([$WORD\-:]+)\n/$1/;
        $result .= qq{<a href="$script?$page_id">$page_id</a><br>\n};
    }
    return $result;
}

1;

=head1 NAME 

CGI::Kwiki::Search - Search Base Class for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
