package Apache::Perldoc;
use vars qw( $VERSION );
$VERSION = qw($Revision: 1.11 $)[1];

sub handler {
    my $r = shift;
    $r->content_type('text/html');
    $r->send_http_header;

    my $pod;

    warn $r->filename;

    if ($r->filename =~ m/\.pod$/i) {
        $pod = $r->filename;
    } else {
        $pod = $r->path_info;
        $pod =~ s|/||;
        $pod =~ s|/|::|g;
        $pod =~ s|\.html$||;  # Intermodule links end with .html
    }

    $pod = 'perl' unless $pod;

    $pod =~
      s/^f::/-f /;    # If we specify /f/ as our "base", it's a function search

    my $tmp      = $r->dir_config('TMP') || "/tmp";
    my $perldoc  = $r->dir_config('PERLDOC');
    my $pod2html = $r->dir_config('POD2HTML');

    if ( $perldoc && $pod2html ) {

        # We want to run tainted
        $ENV{PATH} = "/bin";
      } else {
        $perldoc ||= "perldoc";
        $pod2html ||= "pod2html";
    }

    # Get the path name and throw away errors on stderr
    my $filename = qx( $perldoc -l $pod 2> /dev/null );

    if ($?) {
        print
"No such perldoc. Either you don't have that module installed, or the author neglected to provide documentation.";
      } else {
        chdir $tmp;
        print qx( $perldoc -u $pod | $pod2html --htmlroot=/perldoc --header );
    }
}

1;

# Documentation {{{

=head1 NAME

Apache::Perldoc - mod_perl handler to spooge out HTML perldocs

=head1 DESCRIPTION

A simple mod_perl handler to give you Perl documentation on installed
modules.

The following configuration should go in your httpd.conf

    <Location /perldoc>
      SetHandler perl-script
      PerlHandler Apache::Perldoc
    </Location>

You can then get documentation for a module C<Foo::Bar> at the URL
C<http://your.server.com/perldoc/Foo::Bar>

Note that you can also get the standard Perl documentation with URLs
like C<http://your.server.com/perldoc/perlfunc> or just
C<http://your.server.com/perldoc> for the main Perl docs.

Finally, you can search for a particular Perl keyword with
C<http://your.server.com/perldoc/f::keyword> The 'f' is used by analogy
with the C<-f> flag to C<perldoc>.

In addition to Perl modules, you can have C<Apache::Perldoc> convert
C<.pod> files to HTML with the following configiration:

    <FilesMatch \.pod$>
      SetHandler perl-script
      PerlHandler Apache::Perldoc
    </FilesMatch>

This has not been extensively tested, but appears to mostly work.

=head1 Running under C<PerlTaintCheck>

If you have C<PerlTaintCheck> turned on, then we can't rely on 
C<$ENV{PATH}> to find F<perldoc> and F<pod2html>.  You'll have to 
specify the full paths to F<perldoc> and F<pod2html> like so:

    <Location /perldoc>
      SetHandler	perl-script
      PerlHandler Apache::Perldoc
      PerlSetVar	PERLDOC  /usr/local/bin/perldoc
      PerlSetVar	POD2HTML /usr/local/bin/pod2html
    </Location>

=head1 Specifying your own C<TMP> directory

C<Apache::Perldoc> assumes that it can use F</tmp> as the temp directory
to run from, since F<pod2html> requires a place to put its work files.
You can override this with a

    PerlSetVar TMP /my/temp/directory

=head1 Author

Rich Bowen <rbowen@ApacheAdmin.com>

http://www.ApacheAdmin.com/

Patches from Andy Lester to make it a little bit more secure.

=head1 Caveat

Note that this is EXCEEDINGLY insecure. Run this at your own risk, and
only on internal web sites, if you know what's good for you.

If someone would like to make this a little more secure, I would be
delighted to apply any patches you would like to provide. This module
was written for my own benefit, and put back on CPAN because some folks
asked me to.

You have been warned.

=head1 Other neat trick - Bookmarklet

If you create a browser bookmark to the following URL, you can highlight
the name of a module on web page, then select the bookmark, and go
directly to the documentation for that module. Selecting the bookmark
without having anything highlighted will result in a pop-up dialog in
which you can type a module name.

 javascript:Qr=document.getSelection();if(!Qr){void(Qr=prompt('Module
 name',''))};if(Qr)location.href='http://localhost/perldoc/'+escape(Qr)

Note that that's all one line, split here for display purposes. I know
this works in Netscape and Mozilla. Can't vouch for IE.

=head1 LICENSE

This code is released under the HJTI license ("Here, Just Take It"), or,
if you really want a real license, take your pick of the GPL and the
Artistic License. Which is to say, this is release under the same terms
as Perl itself.

The author makes no particular claims to ownership, as this is a really
obvious idea, and a lot of other people have been doing this for ages. I
just appear to be the first to put it on CPAN.

=cut

# }}}


