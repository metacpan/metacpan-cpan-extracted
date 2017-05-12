package CGI::Kwiki::Changes;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';

sub process {
    my ($self) = @_;
    $self->driver->load_class('metadata');
    my $search = $self->cgi->page_id;
    return
      $self->template->process('display_header') .
      $self->changes .
      $self->template->process('basic_footer');
}

sub changes {
    my ($self) = @_;
    my $search = $self->cgi->search;
    my $database = $self->database;
    my $pages = [ 
        map {[$_, -M $_]} 
        grep {
            (my $page_id = $_) =~ s/.*[\/\\]//;
            $database->exists($self->unescape($page_id));
        } glob "database/*" 
    ];
    my $html = qq{<table border="0" class="changes">\n};
    for my $range
        ([$self->loc("hour"), 1/24],
         [$self->loc("3 hours"), 0.125],
         [$self->loc("6 hours"), 0.25],
         [$self->loc("12 hours"), 0.5],
         [$self->loc("24 hours"), 1],
         [$self->loc("2 days"), 2],
         [$self->loc("3 days"), 3],
         [$self->loc("week"), 7],
         [$self->loc("2 weeks"), 7],
         [$self->loc("month"), 30],
         [$self->loc("3 months"), 90],
        ) {
        my ($recent, $older) = ([], []);
        push @{$_->[1] <= $range->[1] ? $recent : $older}, $_
          for @$pages;
        $pages = $older;
        if (@$recent) {
            $html .= qq{<tr><th colspan="3"><h2>} .
                     $self->loc("Changes in the last %1:", $range->[0]) .
                     qq{</h2></th></tr>\n};
            for my $page_id (sort {-M $a <=> -M $b} 
                             map {$_->[0]} @$recent) {
                $html .= "<tr>\n";
                $page_id =~ s/.*[\/\\](.*)/$1/;
                $page_id = $self->unescape($page_id);
                my $metadata = $self->metadata->get($page_id);
                my $edit_by = $metadata->{edit_by} || '&nbsp;';
                my $edit_time = $metadata->{edit_time} || '&nbsp;';
		my $script = $self->script;
                $html .= qq{<td class="page-id" nowrap="1"><a href="$script?$page_id">$page_id</a></td>\n};
                $html .= qq{<td class="edit-by" nowrap="1">$edit_by</td>\n};
                $html .= qq{<td class="edit-time" nowrap="1">$edit_time GMT</td>\n};
                $html .= qq{</tr>\n};
            }
        }
    }
    $html .= qq{</table>\n};
    return $html;
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Changes - Changes Base Class for CGI::Kwiki

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
