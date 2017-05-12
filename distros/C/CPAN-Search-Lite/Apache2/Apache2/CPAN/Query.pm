package Apache2::CPAN::Query;
use strict;
use warnings;
use utf8;
use mod_perl2 1.999022;     # sanity check for a recent version
use Apache2::Const -compile => qw(OK REDIRECT SERVER_ERROR 
                                  TAKE1 RSRC_CONF ACCESS_CONF);
use CPAN::Search::Lite::Query;
use CPAN::Search::Lite::Util qw($mode_info $query_info %modes
                                %chaps_rev %chaps $tt2_pages);
our $chaps_desc = {};
our $pages = {};

use CPAN::Search::Lite::Lang qw(%langs load);
use Template;
use File::Spec::Functions qw(catfile catdir);
use Apache2::Request;
use Apache2::Cookie;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Module ();
use Apache2::Log ();
use APR::Date;
use APR::URI;
use Apache2::URI;
use APR::Const -compile => qw(URI_UNP_OMITQUERY);

our $VERSION = 0.77;

my @directives = (
                  {name      => 'CSL_db',
                   errmsg    => 'database name',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_user',
                   errmsg    => 'user to log in as',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_passwd',
                   errmsg    => 'password for user',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_tt2',
                   errmsg    => 'location of tt2 pages',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_dl',
                   errmsg    => 'default download location',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_max_results',
                   errmsg    => 'maximum number of results',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_html_root',
                   errmsg    => 'root directory of html files',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                  {name      => 'CSL_html_uri',
                   errmsg    => 'root uri of html files',
                   args_how  => Apache2::Const::TAKE1,
                   req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
                  },
                 );
Apache2::Module::add(__PACKAGE__, \@directives);

my $cookie_mirror = 'cslmirror';
my $cookie_ws = 'cslwebstart';
my $cookie_lang = 'csllang';

my ($template, $query, $cfg, $dl, $max_results);

sub new {
    my ($class, $r) = @_;
    my $lang = lang_wanted($r);
    my $req = Apache2::Request->new($r);
    $cfg = Apache2::Module::get_config(__PACKAGE__, 
                                      $r->server,
                                      $r->per_dir_config) || { };

    $dl ||= $cfg->{dl} || 'http://www.cpan.org';
    $max_results ||= $cfg->{max_results} || 200;
    my $passwd = $cfg->{passwd} || '';

    $template ||= Template->new({
                                 INCLUDE_PATH => [$cfg->{tt2},
                                                  Template::Config->instdir('templates')],
                                 PRE_PROCESS => ['config', 'header'],
                                 POST_PROCESS => 'footer',
                                 POST_CHOMP => 1,
                                })  || do {
                                  $r->log_error(Template->error());
                                  return Apache2::Const::SERVER_ERROR;
                                };
    $query ||= CPAN::Search::Lite::Query->new(db => $cfg->{db},
                                              user => $cfg->{user},
                                              passwd => $passwd,
                                              max_results => $max_results);

    my $mode = $req->param('mode') || 'dist';
    unless ($r->location eq '/mirror') {
        if ($r->protocol =~ /(\d\.\d)/ && $1 >= 1.1) {
            $r->headers_out->{'Cache-Control'} = 'max-age=36000';
        }
        else {
            $r->headers_out->{Expires} = APR::Date::parse_http(time+36000);
        }
    }
    my $mirror;
    my $submit = $req->param('submit') || '';
    my $webstart;
    my $lang_cookie;

    if ($submit) {
      $webstart = $req->param('webstart');
      my $value = $webstart || 1;
      my $expires = $webstart ? '+1y' : 'now';
      my $c_ws = Apache2::Cookie->new($r, 
                                           name => $cookie_ws, 
                                           path => '/',
                                           value => $value,
                                           expires => $expires);
      $c_ws->bake($r);
      
      $lang_cookie = $req->param('lang');
      $value = $lang_cookie || 1;
      $expires = $lang_cookie ? '+1y' : 'now';
      my $c_lang = Apache2::Cookie->new($r, 
                                        name => $cookie_lang, 
                                        path => '/',
                                        value => $value,
                                        expires => $expires);
      $c_lang->bake($r);
      $lang = $lang_cookie if $lang_cookie;

      my $host = $req->param('host') || $req->param('url') || '';
      if ($host) {
        my $cookie = Apache2::Cookie->new($r, 
                                          name => $cookie_mirror, 
                                          path => '/',
                                          value => $host,
                                          expires => '+1y');
        $cookie->bake($r);
        $mirror = $host;
      }
    }
    else {
      my %cookies = Apache2::Cookie->fetch($r);
      unless ($mirror) {
        if (my $c = $cookies{$cookie_mirror}) {
          $mirror = $c->value;
        }
      }
      unless ($webstart) {
        if (my $c = $cookies{$cookie_ws}) {
          $webstart = $c->value;
        }
      }
      unless ($lang_cookie) {
        if (my $c = $cookies{$cookie_lang}) {
          $lang = $lang_cookie = $c->value;
        }
      }
    }

    $CPAN::Search::Lite::Query::lang = $lang;
    unless ($pages->{$lang}) {
      my $rc = load(lang => $lang, pages => $pages, chaps_desc => $chaps_desc);
      unless ($rc == 1) {
        $r->log_error($rc);
        return;
      }
    }

    $mirror ||= $dl;
    $r->content_type('text/html; charset=UTF-8');

    my $self = {mode => $mode, mirror => $mirror, req => $req,
                html_root => $cfg->{html_root}, lang => $lang,
                html_uri => $cfg->{html_uri}, webstart => $webstart,
                title => $pages->{$lang}->{title}};
    bless $self, $class;
}

sub search : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    
    my $req = $self->{req};
    my $query_term = trim($req->param('query'));
    return $self->chapter($r) unless $query_term;
    my $mode = $self->{mode};
    $mode = 'module' if $query_term =~ /::/;
    $mode = 'dist' if $query_term =~ /-/;
    $query_term =~ s{\.pm$}{} if ($mode eq 'module');
    my ($results, $page, %extra_info, $search_page);
    if ($query_term and $mode eq 'chapter') {
      if ($query_term =~ / /) {
        $mode = 'dist';
        $search_page = 'search';
      }
      else {
#        $query_term =~ s/[^\w]//g;
        $search_page = 'query';
      }
    }
    else {
      $search_page = 'search';
    } 
    $query->query(mode => $mode, query => $query_term);
    if ($results = $query->{results}) {
      $page = ref($results) eq 'ARRAY' ?
        $tt2_pages->{$mode}->{$search_page} :
          $tt2_pages->{$mode}->{info};
    }
    else {
      $page = 'missing';
    }
    
    unless (ref($results) eq 'ARRAY') {
        my $name;
        if ($mode and $mode_info->{$mode}->{name} 
            and $name = $results->{$mode_info->{$mode}->{name}}) {
            if ($name =~ /^(\w)(\w)/) {
                my ($a, $b) = (uc($1), uc($2));
                $extra_info{letter} = $a;
                $extra_info{cpan_letter} = "$a/$a$b";
            }
            if ($mode eq 'dist' and $name =~ /^([^-]+)-/) {
                $extra_info{subletter} = $1;
            }
            if ($mode eq 'module' and $name =~ /^([^:]+)::/) {
              $extra_info{subletter} = $1;
            }
        }
    }
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $vars = {results => $results,
                query => $query_term,
                mode => $mode,
                mirror => $self->{mirror},
                %extra_info,
                pages => $pages->{$self->{lang}},
                title => $self->{title},
               };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub cpanid : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $uri = $r->uri;
    my ($mode, $results, $page);
    my ($cpanid, $dist_name) = $uri =~ m!^/~([^/]+)/?(.*)!;
    if ($dist_name) {
        $mode = 'dist';
        $query->query(mode => $mode, name => $dist_name);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{info} : 'letters';
    }
    elsif ($cpanid) {
        $mode = 'author';
        $query->query(mode => $mode, name => $cpanid);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{info} : 'letters';
    }
    else {
        $mode = 'author';
        $page = 'letters';
    }
    my %extra_info;
    unless (ref($results) eq 'ARRAY') {
        if (my $name = $results->{$mode_info->{$mode}->{name}}) {
            if ($name =~ /^(\w)(\w)/) {
                my ($a, $b) = (uc($1), uc($2));
                $extra_info{letter} = $a;
                $extra_info{cpan_letter} = "$a/$a$b";
                $extra_info{title} = sprintf("%s : %s",
                                             $self->{title},
                                             $name);
            }
            if ($mode eq 'dist' and $name =~ /^([^-]+)-/) {
                $extra_info{subletter} = $1;
                $extra_info{title} = sprintf("%s : %s",
                                             $self->{title},
                                             $name);
            }
            if ($mode eq 'module' and $name =~ /^([^:]+)::/) {
                $extra_info{subletter} = $1;
                $extra_info{title} = sprintf("%s : %s",
                                             $self->{title},
                                             $name);
            }
        }
    }
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                title => $self->{title},
                %extra_info,
                pages => $pages->{$self->{lang}},
                webstart => $self->{webstart},
                };
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub author : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $path_info = $r->path_info;
    my $mode = 'author';
    my ($page, $cpanid, $letter, $results);
    if ($path_info =~ m!^/([^/]+)!) {
        my $match = $1;
        if ($path_info =~ m!/$!) {
            $letter = $match;
        }
        else {
            $cpanid = $match;
        }
    }
    if ($letter) {
        $query->query(mode => $mode, letter => $letter);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{letter} : 'letters';
    }
    elsif ($cpanid) {
        $query->query(mode => $mode, name => $cpanid);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{info} : 'letters';
    }
    else {
        $page = 'letters';
    }
    my %extra_info;
    unless (ref($results) eq 'ARRAY') {
        if (my $name = $results->{$mode_info->{$mode}->{name}}) {
            if ($name =~ /^(\w)(\w)/) {
                my ($a, $b) = (uc($1), uc($2));
                $extra_info{letter} = $a;
                $extra_info{cpan_letter} = "$a/$a$b";
                $extra_info{title} = sprintf("%s : %s",
                                             $self->{title},
                                             $name);
            }
            if ($mode eq 'dist' and $name =~ /^([^-]+)-/) {
                $extra_info{subletter} = $1;
                $extra_info{title} = sprintf("%s : %s",
                                             $self->{title},
                                             $name);
            }
        }
    }
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                letter => $letter,
                title => $self->{title},
                %extra_info,
                pages => $pages->{$self->{lang}},
                webstart => $self->{webstart},
                };
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub dist : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $path_info = $r->path_info;
    my $mode = 'dist';
    my ($page, $dist_name, $letter, $results);
    if ($path_info =~ m!^/([^/]+)!) {
        my $match = $1;
        if ($path_info =~ m!/$!) {
            $letter = $match;
        }
        else {
            $dist_name = $match;
        }
    }
    if ($letter) {
        $query->query(mode => $mode, letter => $letter);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{letter} : 'letters';
    }
    elsif ($dist_name) {
        $query->query(mode => $mode, name => $dist_name);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{info} : 'letters';
    }
    else {
        $page = 'letters';
    }
    if ($letter and ref($results) eq 'ARRAY' and @$results == 1) {
      $r->headers_out->set(Location => "/dist/$results->[0]->{dist_name}");
      return Apache2::Const::REDIRECT;
    }
    my %extra_info;
    unless (ref($results) eq 'ARRAY') {
        if (my $name = $results->{$mode_info->{$mode}->{name}}) {
            if ($name =~ /^(\w)/) {
                $extra_info{letter} = $letter = uc($1);
            }
            if ($name =~ /^([^-]+)-/) {
                $extra_info{subletter} = $1;
            }
            $extra_info{title} = sprintf("%s : %s",
                                         $self->{title},
                                         $name);
        }
    }
    unless ($letter and $letter =~ /^\w$/) {
        $extra_info{subletter} = $letter;
        ($extra_info{letter} = $letter) =~ s/^(\w).*/$1/ if $letter;
    }
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                letter => $letter,
                title => $self->{title},
                %extra_info,
                pages => $pages->{$self->{lang}},
                webstart => $self->{webstart},
                };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub module : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $path_info = $r->path_info;
    my $mode = 'module';
    my ($page, $mod_name, $letter, $results);
    if ($path_info =~ m!^/([^/]+)!) {
        my $match = $1;
        if ($path_info =~ m!/$!) {
            $letter = $match;
        }
        else {
            $mod_name = $match;
        }
    }
    if ($letter) {
        $query->query(mode => $mode, letter => $letter);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{letter} : 'letters';
    }
    elsif ($mod_name) {
        $query->query(mode => $mode, name => $mod_name);
        $results = $query->{results};
        $page = $results ? $tt2_pages->{$mode}->{info} : 'letters';
    }
    else {
        $page = 'letters';
    }
    if ($letter and ref($results) eq 'ARRAY' and @$results == 1) {
      $r->headers_out->set(Location => "/module/$results->[0]->{mod_name}");
      return Apache2::Const::REDIRECT;
    }
    my %extra_info;
    unless (ref($results) eq 'ARRAY') {
        if (my $name = $results->{$mode_info->{$mode}->{name}}) {
            if ($name =~ /^(\w)/) {
                $extra_info{letter} = $letter = uc($1);
            }
            if ($name =~ /^([^:]+)::/) {
                $extra_info{subletter} = $1;
            }
            $extra_info{title} = sprintf("%s : %s",
                                         $self->{title},
                                         $name);
        }
    }
     unless ($letter and $letter =~ /^\w$/) {
        $extra_info{subletter} = $letter;
        ($extra_info{letter} = $letter) =~ s/^(\w).*/$1/ if $letter;
    }
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                letter => $letter,
                title => $self->{title},
                %extra_info,
                pages => $pages->{$self->{lang}},
                webstart => $self->{webstart},
                };
    $template->process($page, $vars, $r, binmode => ':utf8')or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
  }

sub chapter : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $path_info = $r->path_info;
    my $mode = 'chapter';
    my ($results, $page, %extra_info);
    if (not $path_info) {
        $results = $self->chap_results();
        $page = $results ? 'chapterid' : 'missing';
    }
    my ($chapter, $subchapter);
    if ($path_info) {
        if ($path_info =~ m!^/([^/]+)/?(.*)!) {
            ($chapter, $subchapter) = ($1, $2);
        }
        $chapter = undef if (not defined $chaps_rev{$chapter});
    }
    if (not defined $chapter) {
        $results = $self->chap_results();
        $page = $results ? 'chapterid' : 'missing';
    }
    else {
        my %args;
        $args{mode} = $mode;
        $args{id} = $chaps_rev{$chapter};
        $extra_info{chapter} = $chapter;
        my $chapter_desc = $chaps_desc->{$self->{lang}}->{$args{id}};
        $extra_info{chapter_desc} = $chapter_desc;
        $extra_info{title} = sprintf("%s : %s",
                                     $self->{title},
                                     $chapter_desc);
        if ($subchapter) {
            $args{subchapter} = $subchapter;
            $extra_info{subchapter} = $subchapter;
            $page = $tt2_pages->{$mode}->{search};
        }
        else {
            $page = $tt2_pages->{$mode}->{info};
        }
        $query->query(%args);
        $results = $query->{results};
        $page = 'missing' unless $results;
        if ($subchapter and ref($results) eq 'ARRAY' and @$results == 1) {
          $r->headers_out->set(Location => "/dist/$results->[0]->{dist_name}");
          return Apache2::Const::REDIRECT;
        }
    }
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                title => $self->{title},
                %extra_info,
                pages => $pages->{$self->{lang}},
                };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub mirror : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $mode = 'mirror';
    my (%save, %extra_info, $path);
    if (my $referer = $r->headers_in->{Referer}) {
        my $parsed = APR::URI->parse($r->pool, $referer);
        my $qs = $parsed->query;
        $path = $parsed->path;
        %save = parse_qs($qs);
        delete $save{host};
        delete $save{url};
    }
    $extra_info{save} = \%save;
    my $page = 'mirror';
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $title = sprintf("%s : %s", $self->{title}, 'mirror');
    my $vars = {mode => $mode,
                mirror => $self->{mirror},
                webstart => $self->{webstart},
                lang => $self->{lang},
                path => $path,
                title => $title,
                %extra_info,
                pages => $pages->{$self->{lang}},
                };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub recent : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    my $req = $self->{req};
    my $age = $req->param('age') || 7;
    my $mode = 'dist';
    $query->query(mode => $mode,
                  recent => $age);
    my $results = $query->{results};
    my $page = $results ? 'recent' : 'missing';
    if (my $error = $query->{error}) {
        $r->log->error($error);
        $query->{error} = undef;
        $page = 'error';
    }
    my $title = sprintf("%s : %s", $self->{title}, 'recent uploads');
    my $vars = {results => $results,
                mode => $mode,
                mirror => $self->{mirror},
                age => $age,
                title => $title,
                pages => $pages->{$self->{lang}},
                webstart => $self->{webstart},
                };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
}

sub perldoc : method {
  my ($self, $r) = @_;
  $self = __PACKAGE__->new($r) 
    unless ref($self) eq __PACKAGE__;
  my $path_info = $r->path_info;
  my $mode = 'module';
  my ($page, $request, $results);
  if (my $args = $r->args()) {
    $request = $args;
  }
  else {
    if (not $path_info) {
      $results = $self->chap_results();
      $page = $results ? 'chapterid' : 'missing';
    }
    else {
      if ($path_info =~ m!^/([^/]+)!) {
        $request = $1;
      }
      else {
        $results = $self->chap_results();
        $page = $results ? 'chapterid' : 'missing';
      }
    }
  }
  my $vars;
  if ($page) {
    $vars = {results => $results,
             mirror => $self->{mirror},
             pages => $pages->{$self->{lang}},
             title => $self->{title},
             };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
  }

  my $parsed = $r->parsed_uri();
  my $html_root = $self->{html_root};
  
  my ($scheme, $host, $path) 
    = $self->{html_uri} =~ m!(\w+)://([^/]+/)(.*)!; 
  $parsed->hostname($host);
  $parsed->port(80);
  $parsed->scheme($scheme);
  
  my $perl_file = catfile $html_root, 'perl', $request;
  $perl_file .= '.html';
  if (-f $perl_file) {
    $path = File::Spec::Unix->catfile($path, 'perl', $request);
    $parsed->path($path . '.html');
    $r->headers_out->set(Location => $parsed->unparse(APR::Const::URI_UNP_OMITQUERY));
    return Apache2::Const::REDIRECT;
  }
  
  $query->query(mode => 'module', name => $request);
  $results = $query->{results};  
  my $dist_name = $results->{dist_name};
  my $mod_file = catfile $html_root, $dist_name, split(/::/, $request);
  $mod_file .= '.html';
  unless ($results->{doc} and -f $mod_file) {
    $page = 'not_found';        
    $vars = {request => $request,
             mirror => $self->{mirror},
             pages => $pages->{$self->{lang}},
             mode => 'perldoc',
             };
    $template->process($page, $vars, $r, binmode => ':utf8') or do {
      $r->log_error($template->error());
      return Apache2::Const::SERVER_ERROR;
    };
    return Apache2::Const::OK;
  }

  $path = File::Spec::Unix->catfile($path, $dist_name, split(/::/, $request));
  $parsed->path($path . '.html');
  $r->headers_out->set(Location => $parsed->unparse(APR::Const::URI_UNP_OMITQUERY));
  return Apache2::Const::REDIRECT;
}

sub chap_results {
    my $self = shift;
    my $chapters;
    foreach my $key( sort {$a <=> $b} keys %chaps) {
        push @$chapters, {chapterid => $key, 
                          chap_link => $chaps{$key},
                          chap_desc => $chaps_desc->{$self->{lang}}->{$key},
                         };
    }
    return $chapters;
}

sub parse_qs {
    my $qs = shift;
    return unless $qs;
    my %args = map {
        tr/+/ /;
        s/%([0-9a-fA-F]{2})/pack("C",hex($1))/ge;
        $_;
    } split /[=&;]/, $qs, -1;
    return %args;
}

sub trim {
    my $string = shift;
    return unless $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\s+/ /g;
    $string =~ s/\"|\'|\\//g;
    return ($string =~ /\w/) ? $string : undef;
}

sub lang_wanted {
  my $r = shift;
  my $accept = $r->headers_in->{'Accept-Language'};
  return 'en' unless $accept;
  my %wanted;
  foreach my $lang(split /,/, $accept) {
    if ($lang !~ /;/) {
      $lang =~ s{(\w+)-\w+}{$1};
      $wanted{1} = lc $lang;
    }
    else {
      my @q = split /;/, $lang, 2;
      $q[1] =~ s{q=}{};
      $q[1] = trim($q[1]);
      $q[0] =~ s{(\w+)-\w+}{$1};
      $wanted{$q[1]} = lc trim($q[0]);
    }
  }
  for (reverse sort {$a <=> $b} keys %wanted) {
    return $wanted{$_} if $langs{$wanted{$_}};
  }
  return 'en';
}

sub CSL_db {
  my ($cfg, $parms, $db) = @_;
  $cfg->{ db } = $db;
}

sub CSL_user {
  my ($cfg, $parms, $user) = @_;
  $cfg->{ user } = $user;
}

sub CSL_passwd {
  my ($cfg, $parms, $passwd) = @_;
  $cfg->{ passwd } = $passwd;
}

sub CSL_tt2 {
  my ($cfg, $parms, $tt2) = @_;
  $cfg->{ tt2 } = $tt2;
}

sub CSL_dl {
  my ($cfg, $parms, $dl) = @_;
  $cfg->{ dl } = $dl;
}

sub CSL_max_results {
  my ($cfg, $parms, $max_results) = @_;
  $cfg->{ max_results } = $max_results;
}

sub CSL_html_root {
  my ($cfg, $parms, $html_root) = @_;
  $cfg->{ html_root } = $html_root;
}

sub CSL_html_uri {
  my ($cfg, $parms, $html_uri) = @_;
  $cfg->{ html_uri } = $html_uri;
}

#sub DESTROY {
#    $dbh->disconnect;
#}

1;

__END__

=head1 NAME

Apache2::CPAN::Query - mod_perl interface to CPAN::Search::Lite::Query

=head1 DESCRIPTION

This module provides a mod_perl (2) interface to CPAN::Search::Lite::Query.
The modules C<Apache2::Request>
and C<Apache2::Cookie> of the C<libapreq2> distribution
are required. A directive

    PerlLoadModule Apache2::CPAN::Query

should appear before any of the C<Location> directives
using the module. As well, the following directives should
be defined in the Apache configuration file.

=over 3

=item C<CSL_db database>

the name of the database [required]

=item C<CSL_user user>

the user to connect to the database as [required]

=item C<CSL_passwd password>

the password to use for this user [optional if no password
is required for the user specified in C<CSL_user>.]

=item C<CSL_tt2 /path/to/tt2>

the path to the tt2 pages [required].

=item C<CSL_dl http://www.cpan.org>

the default download location [optional - http://www.cpan.org will
be used if not specified]

=item C<CSL_max_results 200>

the maximum number of results to obtain [optional - 200 will be
used if not specified]

=item C<CSL_html_root /usr/local/httpd/CPAN>

the path to the local html docs [required for the perldoc handler]

=item C<CSL_html_uri http://you.org/CPAN/docs>

the uri to use for the html docs [required for the perldoc handler]

=back

Available response handlers are as follows.

=over 3

=item * search

 <Location "/search">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->search
 </Location>

This handles search queries such as for
I<http://localhost/search?mode=dist;query=libnet>.
C<mode> can be one of C<dist>, C<module>, or C<author>.
A search using the specified C<query>
will be done on, respectively, distribution names and abstracts,
module names and abstracts, and CPAN ids and full names.

=item * cpanid

 <LocationMatch "/~[A-Za-z0-9-]+">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->cpanid
 </LocationMatch>

There are two levels:

=over 3

=item * http://localhost/~cpanid

This will bring up a page of information on the author
whose cpanid is C<CPANID>.

=item * http://localhost/~cpanid/Dist-Name

This will bring up a page of information on the distribution
C<Dist-Name> of cpanid C<CPANID>.

=back

=item * author 

 <Location "/author">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->author
 </Location>

There are 3 levels:

=over 3

=item * http://localhost/author

This brings up a menu of letters of the alphabet to link
to authors whose ids begin with that letter.

=item * http://localhost/author/CPANID

This brings up an information page for the author with
cpanid C<CPANID>.

=item * http://localhost/author/A/

This brings up a list of all authors whose cpanids begin
with C<A>.

=back

=item * dist

 <Location "/dist">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->dist
 </Location>

There are 4 levels:

=over 3

=item * http://localhost/dist

This brings up a menu of letters of the alphabet to link
to distributions whose names begin with that letter.

=item * http://localhost/dist/Dist-Name

This brings up an information page for the distribution with
name C<Dist-Name>.

=item * http://localhost/dist/A/

This brings up a list of all distributions whose names begin
with C<A>.

=item * http://localhost/dist/ABC/

This brings up a list of all distributions whose names match
C<ABC-*>.

=back

=item * module

 <Location "/module">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->module
 </Location>

There are 4 levels:

=over 3

=item * http://localhost/module

This brings up a menu of letters of the alphabet to link
to mocules whose names begin with that letter.

=item * http://localhost/module/Mod::Name

This brings up an information page for the module with
name C<Mod::Name>.

=item * http://localhost/module/A/

This brings up a list of all modules whose names begin
with C<A>.

=item * http://localhost/module/ABC/

This brings up a list of all modules whose names match
C<ABC::*>.

=back

=item * chapter

 <Location "/chapter">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->chapter
 </Location>

There are 3 levels:

=over 3

=item * http://localhost/chapter

This brings up a menu of all available chapter
headings (as appears in
C<%chaps> of C<CPAN::Search::Lite::Util>).

=item * http://localhost/chapter/Data_Type_Utilities

This brings up a list
all subchapters of the C<Data Type Utilities> chapter.

=item * http://localhost/chapter/Data_Type_Utilities/Tie

This brings up a list of all distributions in the
C<Tie> subchapter of the C<Data Type Utilities> chapter.

=back

=item * recent

 <Location "/recent">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->recent
 </Location>

With this, a request for I<http://localhost/recent> will
list all distributions uploaded in the last 7 days.

=item * mirror

 <Location "/mirror">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->mirror
 </Location>

With this, a request for I<http://localhost/mirror> will
bring up a page whereby the user can change the location
of where downloads will be redirected to. This requires
cookies to be enabled.

=item * perldoc

 <Location "/perldoc">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Query->perldoc
 </Location>

With this, a request for, eg, I<http://localhost/perldoc/perlfaq> will
be redirected to the I<perfaq> documentation, and a request
for, eg, I<http://localhost/perldoc/Net::FTP>, will be redirected
to the documentation for I<Net::FTP>.

=back

=head1 SEE ALSO

L<Apache2::CPAN::Search>, L<CPAN::Search::Lite::Query>, and L<mod_perl>.

=cut
