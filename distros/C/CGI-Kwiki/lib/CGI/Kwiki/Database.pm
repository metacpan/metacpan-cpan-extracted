package CGI::Kwiki::Database;
$VERSION = '0.18';
use strict;
use CGI::Kwiki;
use base 'CGI::Kwiki';
use base 'CGI::Kwiki::Privacy';
use Fcntl ':flock';

attribute 'lock_handle';

use constant DB_DIR => 'database';
use constant LOCK_DIR => 'metabase/lock';

sub file_path {
    my ($self, $page_id) = @_;
    DB_DIR . '/' . $self->escape($page_id);
}

sub lock_path {
    my ($self, $page_id) = @_;
    LOCK_DIR . '/' . $self->escape($page_id);
}

sub lock {
    my ($self, $page_id) = @_;
    local *LOCK;
    my $lock_handle = *LOCK;
    my $lock_file = $self->lock_path($page_id);
    open $lock_handle, "> $lock_file"
      or die "Can't open lock file $lock_file\n:$!";
    $self->lock_handle(*LOCK);
    flock($lock_handle, LOCK_EX) 
      or die "Can't lock $page_id\n:$!";
}

sub unlock {
    my ($self, $page_id) = @_;
    my $lock_handle = $self->lock_handle;
    flock($lock_handle, LOCK_UN) 
      or die "Can't unlock $page_id\n:$!";
    close $lock_handle;
}

sub exists {
    my ($self, $page_id) = @_;
    return $self->is_readable && 
           -f $self->file_path($page_id) &&
           not -z $self->file_path($page_id) ||
           $page_id eq $self->config->changes_page;
}

sub load {
    my ($self, $page_id) = @_;
    die "Can't load page '$page_id'. Unauthorized\n"
      unless $self->is_readable;
    my $file_path = $self->file_path($page_id);
    return '' unless $self->exists($page_id);
    local($/, *WIKIPAGE);
    open WIKIPAGE, $file_path 
      or die "Can't open $file_path for input:\n$!";
    binmode(WIKIPAGE, ':utf8') if $self->use_utf8;
    return <WIKIPAGE>;
}

sub store {
    my ($self, $wiki_text, $page_id) = @_;
    return if $wiki_text eq $self->load($page_id);
    die "Can't store page '$page_id'. Unauthorized\n"
      unless $self->is_writable;
    my $file_path = $self->file_path($page_id);
    umask 0000;
    open WIKIPAGE, "> $file_path"
      or die "Can't open $file_path for output:\n$!";
    binmode(WIKIPAGE, ':utf8') if $self->use_utf8;
    print WIKIPAGE $wiki_text;
    close WIKIPAGE;

    $self->driver->load_class('metadata');
    $self->metadata->set($page_id);

    $self->driver->load_class('backup');
    $self->backup->commit($page_id);
}

sub delete {
    my ($self, $page_id) = @_;
    $page_id = $self->escape($page_id);
    for (qw(database metabase/metadata 
            metabase/public metabase/protected metabase/private
           )
        ) {
        unlink "$_/$page_id";
    }
}

sub update_time {
    my ($self) = @_;
    my @stat = stat $self->file_path($self->cgi->path_id);
    $stat[9];
}

sub pages {
    my ($self) = @_;
    grep {
        $self->exists($_);
    } map {
        s/.*[\\\/]//; $self->unescape($_);
    } glob "database/*";
}

1;

__END__

=head1 NAME 

CGI::Kwiki::Database - Database Base Class for CGI::Kwiki

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
