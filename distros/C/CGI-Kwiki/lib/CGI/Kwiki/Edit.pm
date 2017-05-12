package CGI::Kwiki::Edit;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
use CGI::Kwiki ':char_classes';

use constant NEW_DEFAULT => 'New Page Name';

sub process {
    my ($self) = @_;
    return $self->protected 
      unless $self->is_editable;
    my $error_msg = $self->check_new_name;
    my $page_id = $self->cgi->page_id;
    $self->driver->load_class('backup');
    return $self->save 
      if $self->cgi->button =~ /^save$/i and not $error_msg;
    return $self->preview 
      if $self->cgi->button =~ /^preview$/i;
    my $wiki_text = ($self->cgi->revision && 
                     $self->cgi->revision ne $self->cgi->head_revision
                    )
        ? $self->backup->fetch($page_id, $self->cgi->revision)
        : ($self->database->load($page_id) ||
           ($self->loc("Describe the new page here.") . "\n")
          );
    $self->template->process(
        [qw(display_header edit_body basic_footer)],
        wiki_text => $wiki_text,
        error_msg => $error_msg,
        history => $self->history,
        version_mark => $self->backup->version_mark,
        $self->privacy_checked,
    );
}

sub history {
    my ($self) = @_;
    return '' unless $self->backup->has_history;
    my $changes = $self->backup->history;
    return '' unless @$changes;
    my $selected_revision = $self->cgi->revision || $changes->[0]->{revision};
    my $head_revision = $changes->[0]->{revision};
    my $history = <<END;
<br>
<input type="hidden" name="head_revision" value="$head_revision">
<select name="revision" onchange="this.form.submit()">
END
    for my $change (@$changes) {
        my $selected = $change->{revision} eq $selected_revision
          ? ' selected' : '';
        my ($revision, $date, $edit_by) =
          @{$change}{qw(revision date edit_by)};
        $history .= qq{<option value="$revision"$selected>} .
                    qq{$revision ($date) $edit_by</option>\n};
    }
    $history .= qq{</select>\n};
}

sub privacy_checked {
    my ($self) = @_;
    return (
        public_checked => $self->is_public ? ' checked' : '',
        protected_checked => $self->is_protected ? ' checked' : '',
        private_checked => $self->is_private ? ' checked' : '',
    );
}

sub protected {
    my ($self) = @_;
    $self->template->process(
        [qw(display_header protected_edit_body basic_footer)],
    );
}

sub preview {
    my ($self) = @_;
    $self->driver->load_class('formatter');
    my $wiki_text = $self->cgi->wiki_text;
    my $preview = $self->formatter->process($wiki_text);
    $self->template->process(
        [qw(display_header preview_body edit_body basic_footer)],
        preview => $preview,
        $self->privacy_checked,
    );
}

sub save {
    my ($self) = @_;
    my $page_id = $self->cgi->page_id;
    $self->database->lock($page_id);
    my $conflict = $self->backup->conflict;
    my $return;
    my $wiki_text = $self->cgi->wiki_text;
    if ($conflict) {
        $return = $self->template->process(
            [qw(display_header edit_body basic_footer)],
            wiki_text => $wiki_text,
            version_mark => $self->cgi->version_mark,
            $self->privacy_checked,
            %$conflict, 
        );
    }
    else {
        $self->database->store($wiki_text, $self->cgi->page_id);
        if ($self->is_admin) {
            my $privacy = $self->cgi->privacy || 'public';
            $self->set_privacy($privacy);
            $self->blog if $self->cgi->blog;
            $self->delete if $self->cgi->delete;
        }
        $return = { redirect => $self->script . "?" . $self->escape($self->cgi->page_id) };
    }
    $self->database->unlock($page_id);
    return $return;
}

sub check_new_name {
    my ($self) = @_;
    my $page_id = $self->cgi->page_id;
    $self->cgi->page_id_new($self->cgi->page_id_new || $self->loc(NEW_DEFAULT));
    my $page_id_new = $self->cgi->page_id_new;
    my $error_msg = '';
    if (length $page_id_new and
        $page_id_new ne $self->loc(NEW_DEFAULT)
       ) {
        if ($page_id_new !~ /^[$ALPHANUM\:\-]+$/) {
            $error_msg = $self->loc("Invalid page name '%1'", $page_id_new);
        }
        elsif ($self->database->exists($page_id_new)) {
            $error_msg = $self->loc("Page name '%1' already exists", $page_id_new);
        }
        else {
            $self->cgi->page_id($page_id_new);
        }
    }
    return $error_msg;
}

sub blog {
    my ($self) = @_;
    $self->driver->load_class('blog');
    $self->driver->blog->create_entry;
}

sub delete {
    my ($self) = @_;
    my $page_id = $self->cgi->page_id;
    $self->database->lock($page_id);
    $self->database->delete($self->cgi->page_id);
    $self->cgi->page_id('');
    $self->database->unlock($page_id);
}

1;

=head1 NAME 

CGI::Kwiki::Edit - Edit Base Class for CGI::Kwiki

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
