    package Apache::WAP::AutoIndex;
    use strict;
    use CGI::WML;
    use Apache::Constants qw(:common);

    our $VERSION = '0.01';
    sub handler {
        my $r = shift;
        my $cgi = new CGI::WML;

        my $filename     = $r->filename;
        my $url_filename = $r->uri;
        $filename     =~ s/filelist\.wml$//;
        $url_filename =~ s/filelist\.wml$//;
        unless (opendir DH, $filename) { return FORBIDDEN; }

        my $content = "<p>Directory $url_filename:<br/>";
        my $filelink;
        foreach my $file ( readdir DH ){
            if (-d "$filename/$file")
                 { $file .= "/"; $filelink = $file . "filelist.wml"; }
            else { $filelink = $file; }
            $content .= CGI::a({href => "$filelink"}, "$file");
        }
        $content .= "</p>";
        close DH;

        $r->print( $cgi->header(),
              $cgi->start_wml(),
              $cgi->template(-content=>$cgi->prev()),
              $cgi->card(-id=>"dirlist",
                     -title=>"Directory $filename",
                     -content=> $content),
              $cgi->end_wml() );
    }
    1;

