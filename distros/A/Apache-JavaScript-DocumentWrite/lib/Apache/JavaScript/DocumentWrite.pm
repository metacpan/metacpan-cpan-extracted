package Apache::JavaScript::DocumentWrite;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

use Apache::Constants qw(:common);
use Apache::File ();

sub handler {
    my $r = shift;
    my $uri = $r->uri();
    return DECLINED unless $uri =~ s/\.js$//;

    # set it real filename and handle it in content phase
    $r->uri($uri);
    $r->handler("perl-script");
    $r->push_handlers(PerlHandler => \&document_write_handler);
    return DECLINED;
}

sub document_write_handler {
    my $r = shift;
    my $file = $r->filename;
    my $fh = Apache::File->new($file) or return DECLINED;
    $r->content_type('text/plain');
    $r->send_http_header();
    return OK if $r->header_only;
    while (<$fh>) {
	chomp;
	s/\x27/&#x27;/g; # '
	print "document.writeln('$_');\n";
    }

    return OK;
}

1;
__END__

=head1 NAME

Apache::JavaScript::DocumentWrite - replaces document as javascript document.write

=head1 SYNOPSIS

 PerlTransHandler Apache::JavaScript::DocumentWrite

=head1 DESCRIPTION

Apache::JavaScript::DocumentWrite is a mod_perl handler to output HTML
(or plain text) file as a JavaScript document.write file. This module
helps you to do client-side SSI using JavaScript.

For example, you have a HTML file generated from RSS with crontab in

  http://example.com/rss.html

access to

  http://example.com/rss.html.js

gives you document.write version of rss.html. Thus it can be embedded
into another HTML file using SCRIPT html tag like:

  <script src="http://example.com/rss.html.js"></script>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<mod_perl>

=cut
