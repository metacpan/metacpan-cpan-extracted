package AYAHDemoHandler;

use Captcha::AreYouAHuman;
use HTML::Template;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);
use CGI;

sub handler {
        my $r = shift;

        $r->content_type('text/html');
        my $template_file = $r->dir_config("HTMLTemplate");

        # I use CGI.pm here, and I override into the library.
        # I'm certain you're going to do something else in the code.
        # Perhaps you have two handlers.
        my $cgi = new CGI;
        my $ayah = new Captcha::AreYouAHuman("publisher_key" => "xxxxchangemexxxx",
			"scoring_key" => "xxxxchangemexxxx");

        my $ScoreResult = "";
        my $PublisherHTML = "";
        my $ConversionCode = "";

        if ($cgi->param("Submit") ne "") {
                my $sc;
                if ($sc = $ayah->scoreResult("session_secret" => $cgi->param("session_secret"), "client_ip" => $cgi->remote_host())) {
                        $ScoreResult = "Successful; we think you are a human!";
                        $ConversionCode = $ayah->recordConversion("session_secret" => $cgi->param("session_secret"));
                } else {
                        $ScoreResult = "Not successful...Are you a human?";
                }

        }

        $PublisherHTML = $ayah->getPublisherHTML();
        my $tmpl = new HTML::Template(filename => $template_file);
        $tmpl->param("ScoreResult" => $ScoreResult);
        $tmpl->param("PublisherHTML" => $PublisherHTML);
        $tmpl->param("ConversionCode" => $ConversionCode);
        print $tmpl->output();

        return Apache2::Const::OK;
}

1;

