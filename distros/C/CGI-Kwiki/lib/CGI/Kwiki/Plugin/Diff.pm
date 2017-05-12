package CGI::Kwiki::Plugin::Diff;
$VERSION = '0.18';
use strict;
use CGI qw(start_form end_form popup_menu hidden);
use base 'CGI::Kwiki::Plugin';

sub process {
    my ($self) = @_;
    my $page_id = $self->cgi->page_id;

    my $diff = $self->diff($page_id);
    my $entry_form = $self->entry_form($page_id);
    $self->template->process(
        [qw(display_header display_body basic_footer)],
        display => "$entry_form$diff",
	is_diff => 1,
    );
}

sub methods {
    qw(entry_form display_diff);
}

sub entry_form {
    my ($self, $page_id) = @_;
    $page_id ||= $self->cgi->page_id;

    return '' 
      unless $self->prefs->{select_diff} &&
             $self->backup->has_history;
    my $history = $self->backup->history;
    return '' unless @$history > 1;
    my $head_revision = $history->[0]{revision};
    my $current_revision = $self->cgi->current_revision || 
                           $head_revision;
    my (@values, %labels, $selected);
    for (@$history) {
        my $key = $_->{revision};
        push @values, $key;
        $selected = $key if $key eq $current_revision;
        $labels{$key} = "$_->{file_rev} ($_->{date}) $_->{edit_by}";
    }

    my $prompt = $self->loc("Revision Diffs for <a href='%1'>%2</a>:", ($self->script . '?' . $self->escape($page_id)), $page_id);
    <<FORM;
<form>
$prompt
${\
    popup_menu(
        -name => 'diff_revision', 
        -values => \@values, 
        -default => $selected, 
        -labels => \%labels,
        -onChange => "submit()",
    ) 
}
<input type="hidden" name="action" value="plugin" />
<input type="hidden" name="plugin_name" value="Diff" />
<input type="hidden" name="page_id" value="$page_id" />
<input type="hidden" name="head_revision" value="$head_revision" />
<input type="hidden" name="current_revision" value="$current_revision" />
</form>
FORM
}

sub display_diff {
    my ($self) = shift;
    return '' 
      unless $self->prefs->{show_diff} &&
             $self->backup->has_history;
    my $page_id = $self->cgi->page_id;
    my $history = $self->backup->history;
    return '' unless @$history > 1;
    $self->diff($page_id,
                $history->[1]{revision},
                $history->[0]{revision},
                2,
               );
}

sub diff {
    my ($self, $page_id, $r1, $r2, $context) = @_;
    $r1 ||= $self->cgi->diff_revision;
    $r2 ||= $self->cgi->current_revision;
    (my $num1 = $r1) =~ s/.*\.//;
    (my $num2 = $r2) =~ s/.*\.//;
    if ($num1 > $num2) {
        ($r1, $r2) = ($r2, $r1);
    }
    return $self->loc('No history') unless $self->backup->has_history;
    my $diff = $self->backup->diff($page_id, $r1, $r2, $context);
    $diff = CGI->escapeHTML($diff);
    $diff =~ s/\r//g;
    $diff =~ s/^\-(.*)$/<del>$1<\/del>/mg;
    $diff =~ s/^\+(.*)$/<ins>$1<\/ins>/mg;
    $diff =~ s/\n/<br>\n/g;
    $self->decode($diff);
    $self->cgi->current_revision($r1);

    my $prompt = $self->loc("Differences from revision %1 to %2:", $self->backup->file_rev($page_id, $r1), $self->backup->file_rev($page_id, $r2));
    return <<END;
<h3>$prompt</h3>
<div class="diff">
$diff
</div>
END
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Plugin::Diff - A Diff Plugin for CGI::Kwiki

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
