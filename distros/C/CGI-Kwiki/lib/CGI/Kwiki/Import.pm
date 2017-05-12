package CGI::Kwiki::Import;
$VERSION = '0.01';
use strict;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
use CGI::Kwiki ':char_classes';

use constant DB_DIR => 'database';

sub process {
    my ($self) = @_;
    my $import = $self->cgi->page_id;
    return
      $self->template->process('display_header') .
      $self->import.
      $self->template->process('basic_footer');
}

sub import {
    my ($self) = @_;
    eval { require LWP::Simple; 1 } or return;

    my $url = $self->cgi->get_raw('import') or return;
    my $page_id = $self->unescape($self->encode($url));
    $page_id =~ s{[?/]+$}{};
    $page_id =~ s{.*[?/]}{};
    if ($page_id =~ /[^$WORD]/) {
	$page_id = join('', map ucfirst, split(/[^$WORD]+/, $page_id)) or return;
    }
    my $local = DB_DIR."/".$self->escape($page_id);
    my $page_file_path = $self->database->file_path($page_id);
    my $old_timestamp = (-M $local);
    LWP::Simple::mirror($url, $local);
    if (-M $local != $old_timestamp) {
	# say, we may want to muddle it a bit.
	$self->_extract_text($local);
	my $now = time;
	$self->driver->load_class('metadata');
	$self->metadata->set($page_id);

	$self->driver->load_class('backup');
	$self->backup->commit($page_id);
	utime $now, $now, $local;
    }
    my $script = $self->script;
    my $result .= qq{<a href="$script?$page_id">$page_id</a><br>\n};
    return $result;
}

sub _extract_text {
    my ($self, $file) = @_;

    local $/;
    open FH, $file or return;
    my $content = <FH>;
    close FH;

    $content =~ m{<html[^>]*>(.*)}si or return; # don't bother with non-html stuff

    $content = $1;
    $content = $1 if $content =~ m{<wiki>(.*)</wiki>}si;
    $content = $1 if $content =~ m{<div class="wiki">(.*)</div>}si;
    $content =~ s{<img[^>]+src="([^"]+)"[^>]*>}{$1}gi;
    $content =~ s{<script[^>]*>(.*?)</script>}{}gi;
    $content =~ s{<pre[^>]*>(.*?)</pre>}
                 {join("", map "    $_\n", split(/\n/, $1))}egi;
    $content =~ s{<p[^>]*>}{\n\n}gi;
    $content =~ s{<[^>]+>}{}g;

    open FH, "> $file" or return;
    print FH CGI::unescapeHTML($content);
    close FH;

    return 1;
}

1;

=head1 NAME 

CGI::Kwiki::Import - Import the external Kwiki page

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Autrijus Tang <autrijus@autrijus.org>
Hsin-Chan Chien <hcchien@hcchien.org>

=head1 COPYRIGHT

Copyright 2002, 2003 by Autrijus Tang, Hsin-Chan Chien.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
