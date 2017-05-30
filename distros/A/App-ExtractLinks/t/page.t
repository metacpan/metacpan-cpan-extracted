use strict;
use warnings;

use Test::Cmd;
use Test::More tests => 2;

use lib 'lib';
use App::ExtractLinks;

my $test = Test::Cmd->new(
    prog    => './bin/extract-links',
    workdir => ''
);

my $input = <<'EOF';
<!DOCTYPE HTML>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <title>Search the CPAN - metacpan.org</title>
        <link rel="alternate" type="application/rss+xml" title="RSS" href="/feed/recent" />
        <link href="/_assets/510a05c940bec575d4a5edfd45e2668f.css" rel="stylesheet" type="text/css">
        <link rel="search" href="/static/opensearch.xml" type="application/opensearchdescription+xml" title="MetaCPAN">
        <link rel="shortcut icon" href="/static/icons/favicon.ico">
        <link rel="apple-touch-icon" sizes="152x152" href="/static/icons/apple-touch-icon.png">
        <script src="/_assets/8ee3b0e7a6641aed845899d0645808f6.js" type="text/javascript"></script>
        <script>
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', 'UA-27829474-1', {
              siteSpeedSampleRate : 100
          });
          ga('send', 'pageview');

          ga(function() {
            var cookies=['__utma', '__utmb', '__utmc', '__utmv', '__utmz', '_gat'];
            for (var i = cookies.length; i--; ) {
              var cookie = cookies[i]+"=; expires="+(new Date(0)).toGMTString()+"; path=/";
              document.cookie = cookie;
              document.cookie = cookie + '; domain=.'+document.domain;
            }
          });
        </script>
        
        
    </head>
    <body>
        <nav class="navbar navbar-default" role="navigation">
            <div class="container-fluid">
                <ul class="nav navbar-nav">
                    <li class="active">
                        <a href="/"><img src="/static/icons/metacpan-icon.png" />                            Home                        </a>
                    </li>
                    <li class="">
                        <a href="/recent"><i class="fa fa-history"></i>                            Recent                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="/about"><i class="fa fa-info"></i>                            About                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="/about/faq"><i class="fa fa-question"></i>                            FAQ                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="https://github.com/metacpan/metacpan-web/issues"><i class="fa fa-github-alt"></i>                            GitHub Issues                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="/news"><i class="fa fa-newspaper-o"></i>                            News                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="/lab"><i class="fa fa-rocket"></i>                            Lab                        </a>
                    </li>
                    <li class="hidden-xs">
                        <a href="https://fastapi.metacpan.org"><i class="fa fa-database"></i>                            API                        </a>
                    </li>
                </ul>
                <ul class="nav navbar-nav navbar-right">
                    <form action="https://metacpan.org/account/logout" method="POST" id="metacpan-logout"></form>
                    <li class="dropdown logged_in" style="display: none;">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                        Account
                        <b class="caret"></b>
                        </a>
                        <ul class="dropdown-menu">
                            <li><a href="/account/identities">Identities</a></li>
                            <li><a href="/account/profile">Profile</a></li>
                            <li><a href="/account/favorite/list">Favorites</a></li>
                            <li>
                                <a href="#" onclick="$('#metacpan-logout').submit(); return false">Logout</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown logged_out" style="display: none;">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                        Sign in
                        <b class="caret"></b>
                        </a>
                        <ul class="dropdown-menu">
                            <li>
                                <a href="https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&amp;choice=facebook" onclick="return logInPAUSE(this)">
                                <i class="fa fa-facebook fa-fw"></i>
                                Facebook
                                </a>
                            </li>
                            <li>
                                <a href="https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&amp;choice=github" onclick="return logInPAUSE(this)">
                                <i class="fa fa-github fa-fw"></i>
                                GitHub
                                </a>
                            </li>
                            <li>
                                <a href="https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&amp;choice=twitter" onclick="return logInPAUSE(this)">
                                <i class="fa fa-twitter fa-fw"></i>
                                Twitter
                                </a>
                            </li>
                            <li>
                                <a href="https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&amp;choice=google" onclick="return logInPAUSE(this)">
                                <i class="fa fa-google fa-fw"></i>
                                Google
                                </a>
                            </li>
                            <li>
                                <a href="/login/openid">
                                <i class="fa fa-openid fa-fw"></i>
                                OpenID
                                </a>
                            </li>
                        </ul>
                    </li>
                </ul>
            </div>
        </nav>

        <div class="container-fluid">

        

            

            <div class="row">
                <div class="main-content col-md-12">
                    

<div align="center" class="home">
  <a href="/" class="big-logo" alt="meta::cpan"></a>
  <form action="/search">
    <input type="hidden" name="size" id="search-size" value="20">
    <div class="form-group">
        <input type="text" name="q" size="41" autofocus="autofocus" id="search-input" class="form-control home-search-input">
    </div>
    <div class="form-group">
        <button type="submit" class="btn search-btn">Search the CPAN</button>
        <button type="submit" class="btn search-btn" name="lucky" value="1">I'm Feeling Lucky</button>
    </div>
  </form>
  <div class="hidden-phone home-hint">
    Hint: Press shift and enter if you are feeling lucky
  </div>
  <div class="alert alert-info">
    <strong>New to CPAN?</strong> Maybe take a look at <a href="/pod/Task::Kensho">Task::Kensho!</a>
  </div>

  <div class="news-highlight row">
    <div class="col-xs-12 col-sm-8 col-sm-push-2 col-md-6 col-md-push-3">
      <p>
        MetaCPAN would like to acknowledge the following sponsors:
      </p>
      <div class="row sponsor-grid">
        <div class="col-sm-6">
          <!-- perl careers ad remains until Jan 1, 2018 -->
          <a href="http://perl.careers/" target="_blank"><img src="/static/images/sponsors/perl-careers.png" alt="Find Perl Jobs and Perl Developers with Perl Careers"></a>
        </div>
        <div class="col-sm-6">
          <!-- promocodewatch ad remains until July 6, 2017 -->
          <a href="https://www.promocodewatch.com" target="_blank">PromoCodeWatch</a>
        </div>
      </div>
    </div>
  </div>
</div>

                </div>
            </div>

            <div class="row footer">
                <div class="hidden-xs hidden-sm col-md-2">&nbsp;</div>
                <div class="col-xs-2 col-sm-1 col-md-1" style="text-align: center">
                    <a href="https://fastapi.metacpan.org">API</a>
                </div>
                <div class="col-xs-5 col-sm-3 col-md-2" style="text-align: center">
                    <a href="/about">About MetaCPAN</a>
                </div>
                <div class="hidden-xs col-sm-2 col-md-2" style="text-align: center">
                    <a href="/mirrors">CPAN Mirrors</a>
                </div>
                <div class="hidden-xs col-sm-3 col-md-2" style="text-align: center">
                    <a href="https://github.com/metacpan/metacpan-web">Fork metacpan.org</a>
                </div>
                <div class="hidden-xs col-sm-1 col-md-1" style="text-align: center">
                    <a href="https://www.perl.org/">Perl.org</a>
                </div>
            </div>

            <div class="row" style="padding:15px">
              <div class="hidden-xs col-md-4 text-right" style="padding:25px">
                <span class="hidden-phone" style="color: #999">Hosting generously provided by:</span>
              </div>
              <div class="col-xs-9 col-md-4" style="padding:25px">
                <a href="http://www.bytemark.co.uk/r/metacpan.org/" target="_blank">
                  <img width="210" src="/static/images/sponsors/bytemark_logo.png">
                </a>
              </div>
              <div class="col-xs-9 col-md-4" style="padding:15px">
                <a target="_blank" href="https://www.liquidweb.com/">
                  <img width="170" src="/static/images/sponsors/liquidweb_color.png">
                </a>
              </div>
            </div>
        </div>
        <div class="modal fade" tabindex="-1" role="dialog" id="keyboard-shortcuts">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h4 class="modal-title">Keyboard Shortcuts</h4>
              </div>
              <div class="modal-body row">
                <div class="col-md-6">
  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>Global</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>s</kbd>
        </td>
        <td>Focus search bar</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>?</kbd>
        </td>
        <td>Bring up this help dialog</td>
      </tr>
    </tbody>
  </table>

  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>GitHub</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>p</kbd>
        </td>
        <td>Go to pull requests</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>i</kbd>
        </td>
        <td>go to github issues (only if github is preferred repository)</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="col-md-6">
  <table class="table keyboard-shortcuts">
    <thead>
      <tr>
        <th></th>
        <th>POD</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>a</kbd>
        </td>
        <td>Go to author</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>c</kbd>
        </td>
        <td>Go to changes</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>i</kbd>
        </td>
        <td>Go to issues</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>d</kbd>
        </td>
        <td>Go to dist</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>r</kbd>
        </td>
        <td>Go to repository/SCM</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>s</kbd>
        </td>
        <td>Go to source</td>
      </tr>
      <tr>
        <td class="keys">
          <kbd>g</kbd> <kbd>b</kbd>
        </td>
        <td>Go to file browse</td>
      </tr>

    </tbody>
  </table>
</div>

              </div>
              <div class="modal-footer"></div>
            </div>
          </div>
        </div>
    </body>
</html>
EOF

$test->run(stdin => $input);

my $output = <<'EOF';
/feed/recent
/_assets/510a05c940bec575d4a5edfd45e2668f.css
/static/opensearch.xml
/static/icons/favicon.ico
/static/icons/apple-touch-icon.png
/
/recent
/about
/about/faq
https://github.com/metacpan/metacpan-web/issues
/news
/lab
https://fastapi.metacpan.org
#
/account/identities
/account/profile
/account/favorite/list
#
#
https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&choice=facebook
https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&choice=github
https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&choice=twitter
https://fastapi.metacpan.org/oauth2/authorize?client_id=metacpan.org&choice=google
/login/openid
/
/pod/Task::Kensho
http://perl.careers/
https://www.promocodewatch.com
https://fastapi.metacpan.org
/about
/mirrors
https://github.com/metacpan/metacpan-web
https://www.perl.org/
http://www.bytemark.co.uk/r/metacpan.org/
https://www.liquidweb.com/
EOF
 
ok($test);
is($test->stdout, $output, 'output');
