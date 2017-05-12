package Apache2::CPAN::Search;
use strict;
use warnings;
use utf8;
use mod_perl2 1.999022;     # sanity check for a recent version
use Apache2::Const -compile => qw(OK SERVER_ERROR TAKE1 RSRC_CONF ACCESS_CONF);
use CPAN::Search::Lite::Query;
use CPAN::Search::Lite::Util qw($mode_info $query_info %chaps 
                                %modes $tt2_pages);
our $chaps_desc = {};
our $pages = {};
use CPAN::Search::Lite::Lang qw(%langs load);
use Template;
use File::Spec::Functions qw(catfile catdir);
use Apache2::Request;
use Apache2::Cookie;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use APR::Date;
use APR::URI;
use Apache2::URI;
use Apache2::Module ();
use Apache2::Log ();
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

my $cookie_name = 'cslmirror';
my ($template, $query, $cfg, $dl, $max_results);

sub new {
    my ($class, $r) = @_;
    my $lang = lang_wanted($r);
    my $req = Apache2::Request->new($r);
    $cfg = Apache2::Module::get_config(__PACKAGE__,
                                      $r->server,
                                      $r->per_dir_config) || { };
    $dl = $cfg->{dl} || 'http://www.cpan.org';
    $max_results ||= $cfg->{max_results} || 200;
    my $passwd = $cfg->{passwd} || '';

    $template ||= Template->new({
                                 INCLUDE_PATH => [$cfg->{tt2},
                                                  Template::Config->instdir('templates')],
                                 PRE_PROCESS => ['config', 'header'],
                                 POST_PROCESS => 'footer',
                                 POST_CHOMP => 1,
                                }) || do {
                                  $r->log_error(Template->error());
                                  return Apache2::Const::SERVER_ERROR;
                                };

    $query ||= CPAN::Search::Lite::Query->new(db => $cfg->{db},
                                              user => $cfg->{user},
                                              passwd => $passwd,
                                              max_results => $max_results);
    $CPAN::Search::Lite::Query::lang = $lang;
    unless ($pages->{$lang}) {
      my $rc = load(lang => $lang, pages => $pages, chaps_desc => $chaps_desc);
      unless ($rc == 1) {
        $r->log_error($rc);
        return;
      }
    }
    my $mode = $req->param('mode');
    unless ($mode && $mode eq 'mirror') {
        if ($r->protocol =~ /(\d\.\d)/ && $1 >= 1.1) {
            $r->headers_out->{'Cache-Control'} = 'max-age=36000';
        }
        else {
            $r->headers_out->{Expires} = APR::Date::parse_http(time+36000);
        }
    }

    my $mirror;
    if (my $host = ($req->param('host') || $req->param('url') )) {
        my $cookie = Apache2::Cookie->new($r, name => $cookie_name,
                                         value => $host, expires => '+1y');
        $cookie->bake;
        $mirror = $host;
   }
    else {
        my %cookies = Apache2::Cookie->fetch($r);
        if (my $c = $cookies{$cookie_name}) {
            $mirror = $c->value; 
        }
    }
    $mirror ||= $dl;
    $r->content_type('text/html; charset=UTF-8');

    my $self = {mode => $mode,
                mirror => $mirror, req => $req, lang => $lang};
    bless $self, $class;
}

sub search : method {
    my ($self, $r) = @_;
    $self = __PACKAGE__->new($r) 
        unless ref($self) eq __PACKAGE__;
    
    my $req = $self->{req};

    my $mode = $self->{mode};
    my $query_term = trim($req->param('query'));
    my $letter = $req->param('letter');
    my $chapterid = $req->param('chapterid');
    my $recent = $req->param('recent');
    my $subchapter = $req->param('subchapter');
    my ($page, $results, %extra_info, $age);
    
  MODE: {
        (defined $mode and $mode eq 'mirror') and do {
            my %save;
            if (my $referer = $r->headers_in->{Referer}) {
                my $parsed = APR::URI->parse($r->pool, $referer);
                my $qs = $parsed->query;
                %save = parse_qs($qs);
                delete $save{host};
                delete $save{url};
            }
            $extra_info{save} = \%save;
            $page = 'mirror';
            last MODE;
        };
        (defined $mode and $mode eq 'chapter') and do {
            $results = $self->chap_results();
            $page = $results ? 'chapterid' : 'missing';
            last MODE;
        };
        (defined $chapterid) and do {
            my %args;
            $args{mode} = $mode = 'chapter';
            $args{id} = $chapterid;
            $extra_info{chapterid} = $chapterid;
            $extra_info{chapter_link} = $chaps{$chapterid};
            $extra_info{chapter_desc} = $chaps_desc->{$self->{lang}}->{$chapterid};
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
            last MODE;
        };
        (defined $mode and not $modes{$mode}) and do {
            $page = 'missing';
            last MODE;
        };
        
        (defined $mode and defined $query_term) and do {
            $mode = 'module' if $query_term =~ /::/;
            $query_term =~ s{\.pm$}{} if ($mode eq 'module');
            $query->query(mode => $mode, query => $query_term);
            if ($results = $query->{results}) {
                $page = ref($results) eq 'ARRAY' ?
                    $tt2_pages->{$mode}->{search} :
                      $tt2_pages->{$mode}->{info};
            }
            else {
                $page = 'missing';
            }
            last MODE;
        };
        (defined $mode and defined $letter) and do {
            $query->query(mode => $mode, letter => $letter);
            $results = $query->{results};
            $page = $results ? $tt2_pages->{$mode}->{letter} : 'missing';
            unless ($letter =~ /^\w$/) {
                $extra_info{subletter} = $letter;
                ($extra_info{letter} = $letter) =~ s/^(\w).*/$1/;
            }
            last MODE;
        };
        (defined $recent) and do {
            $mode = 'dist';
            $age = $recent || 7;
            $query->query(mode => $mode,
                          recent => $age);
            $results = $query->{results};
            $page = $results ? 'recent' : 'missing';
            last MODE;
        };
        (defined $mode) and do {
            $page = 'letters';
            last MODE;
        };
        foreach my $what (keys %$query_info) {
          next unless my $value = $req->param($what);
          $mode = $query_info->{$what}->{mode};
          my $type = $query_info->{$what}->{type};
          $query->query(mode => $mode,
                        $type => $value);
          if ($results = $query->{results}) {
              $page = ref($results) eq 'ARRAY' ?
                  $tt2_pages->{$mode}->{search} :
                      $tt2_pages->{$mode}->{info};
          }
          else {
              $page = 'missing';
          }
          last MODE;
      }
        $mode = 'chapter';
        $results = $self->chap_results();
        $page = $results ? 'chapterid' : 'missing';
    }
    
    unless (ref($results) eq 'ARRAY') {
        if (my $name = $results->{$mode_info->{$mode}->{name}}) {
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
    my $vars = {results => $results,
                query => $query_term,
                mode => $mode,
                letter => $letter,
                age => $age,
                mirror => $self->{mirror},
                pages => $pages->{$self->{lang}},
                %extra_info,
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

sub chap_results {
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
  $passwd = '' unless $passwd =~ /\w/;
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

1;


__END__

=head1 NAME

Apache2::CPAN::Search - mod_perl interface to CPAN::Search::Lite::Query

=head1 DESCRIPTION

This module provides a mod_perl (2) interface to CPAN::Search::Lite::Query.
The modules C<Apache2::Request>
and C<Apache2::Cookie> of the C<libapreq2> distribution
are required. A directive

    PerlLoadModule Apache2::CPAN::Search

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

=back

The response handler can then be specified as

 <Location "/search">
   SetHandler perl-script
   PerlResponseHandler Apache2::CPAN::Search->search
 </Location>

A request for C<http://localhost/search> without any
query string will bring up a page of chapterid listings.
All other requests are handled through the query string
arguments.

=over 3

=item C<mode=$value>

What results depends on the C<$value> of C<mode>

=over 3

=item C<mode=dist>, C<mode=author>, C<mode=module>

This brings up an alphabetical listing with links to
pages of either distributions, authors, or modules
whose names begin with the indicated letter.

=item C<mode=chapter>

This brings up a page of links to the main chapter ids.

=item C<mode=mirror>

This brings up a page whereby the location of the mirror
used to get downloads from can be specified.

=back

=item C<mode=$mode;query=$query>

For this type of request, C<$mode> must be one of C<dist>,
C<module>, or C<author>. A search using the specified C<$query>
will be done on, respectively, distribution names and abstracts,
module names and abstracts, and CPAN ids and full names.

=item C<mode=$mode;letter=$letter>

For this type of request, C<$mode> must be one of C<dist>,
C<module>, or C<author>. If C<$letter> is a single letter, 
this returns, resepctively, all
distribution names, module names, or CPAN ids beginning
with the specified letter. If C<$letter> is more than one
letter, all distribution names matching C<$letter-*> are returned,
for C<mode=dist>, or all module names matching C<$letter::*>
are returned, for C<mode=module>.

=item C<recent=$age>

This brings up a page listing all distributions uploaded
in the last C<$age> days.

=item C<chapterid=$id>

This brings a page listing all subchapters with a
chapterid of C<$id>.

=item C<chapterid=$id;subchapter=$subchapter>

This brings a page listing all distributions categorized in
the given C<$subchapter> in the C<$id> chapter.

=item C<module=$name> or C<mod_id=$id>

This brings up an information page for the module
with the specified module name or module table id.

=item C<dist=$name> or C<dist_id=$id>

This brings up an information page for the distribution
with the specified distribution name or distribution table id.

=item C<cpanid=$cpanid> or C<author=$cpanid> or C<auth_id=$id>

This brings up an information page for the author
with the specified CPAN id name or author table id.

=back

=head1 NOTE

Make sure to check the values of C<$db>, C<$user>,
C<$passwd>, and C<$tt2> at the top of this file.

=head1 SEE ALSO

L<Apache2::CPAN::Query>, L<CPAN::Search::Lite::Query>, and L<mod_perl>.

=cut

