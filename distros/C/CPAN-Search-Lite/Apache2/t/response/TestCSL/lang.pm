package # hide from PAUSE
  TestCSL::lang;
use strict;
use warnings;
use mod_perl2 1.999022;     # sanity check for a recent version
use Apache2::Const -compile => qw(OK);
use CPAN::Search::Lite::Query;
our $chaps_desc = {};
our $pages = {};
use CPAN::Search::Lite::Lang qw(%langs load);
use TestCSL qw(lang_wanted);
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Log ();
use Apache2::Request;

sub handler {
    my $r = shift;
    $r->content_type('text/html; charset=UTF-8');
    my $req = Apache2::Request->new($r);
    my $data = $req->param('data');
    my $hash_element = $req->param('hash_element');
    my $wanted = $req->param('wanted');
    my $lang = lang_wanted($r);
    $CPAN::Search::Lite::Query::lang = $lang;
    unless ($pages->{$lang}) {
      my $rc = load(lang => $lang, pages => $pages,
                    chaps_desc => $chaps_desc);
      unless ($rc == 1) {
        $r->log_error($rc);
        return;
      }
    }
    my $response;
    if ($data eq 'chaps_desc') {
        $response = $chaps_desc->{$lang}->{$wanted};
    }
    else {
        if ($hash_element) {
            $response = $pages->{$lang}->{$hash_element}->{$wanted};
        }
        else {
            $response = $pages->{$lang}->{$wanted};
        }
    }
    utf8::decode($response);
    $r->print($response);
    return Apache2::Const::OK;
}

1;
