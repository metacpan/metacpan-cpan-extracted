package CPAN::Search::Lite::Query;
use strict;
use warnings;
no warnings qw(redefine);
use utf8;
use CPAN::Search::Lite::Util qw($repositories %chaps
                                $full_id $mode_info);
our $months = {};
our $chaps_desc = {};
our $pages = {};
our $dslip = {};
use CPAN::Search::Lite::Lang qw(load);
use CPAN::Search::Lite::DBI::Query;
use CPAN::Search::Lite::DBI qw($dbh);
use Lingua::Stem qw(:stem);
use constant GB => 1024 * 1024 * 1024;
use constant MB => 1024 * 1024;
use constant KB => 1024;

our ($lang);
our $max_results = 200;
our $VERSION = 0.77;
my $cdbi_query;

my %mode2obj;
$mode2obj{$_} = __PACKAGE__ . '::' . $_ 
    for (qw(dist author module chapter));
 
sub new {
    my ($class, %args) = @_;
    foreach (qw(db user passwd)) {
        die "Please supply a '$_' argument" unless defined $args{$_};
    }
    $cdbi_query = CPAN::Search::Lite::DBI::Query->new(%args);

    $max_results = $args{max_results} if $args{max_results};
    $lang = 'en' unless $lang;
    my $self = {results => undef, error => ''};
    bless $self, $class;
}

sub query {
    my ($self, %args) = @_;
    unless ($months->{$lang}) {
      my $rc = load(lang => $lang, dslip => $dslip, pages => $pages,
                    months => $months, chaps_desc => $chaps_desc);
      unless ($rc == 1) {
        $self->{error} = $rc;
        return;
      }
    }
    my $mode = $args{mode} || 'module';
    unless ($mode) {
        $self->{error} = q{Please specify a 'mode' argument};
        return;
    }
    my $info = $mode_info->{$mode};
    my $table = $info->{table};
    unless ($table) {
      $self->{error} = qq{No table exists for '$mode'};
      return;
    }
    my $cdbi = $cdbi_query->{objs}->{$table};
    my $class = 'CPAN::Search::Lite::DBI::Query::' . $table;
    unless ($cdbi and ref($cdbi) eq $class) {
      $self->{error} = qq{No cdbi object exists for '$table'};
      return;
    }
    my $fields = $args{fields};
    if ($fields and ref($fields) ne 'ARRAY') {
      $self->{error} = q{Please supply an array reference for fields};
      return;
    }
    my $obj;
    eval {$obj = $mode2obj{$mode}->make(table => $table, cdbi => $cdbi);};
    if ($@) {
        $self->{error} = qq{Mode '$mode' is not known};
        return;
    }
    my ($value, $method);
  METHOD: {
        ($mode eq 'dist' and exists $args{recent}) and do {
            $args{search} = {field => 'birth',
                             value => $args{recent} || 7 };
            $method = 'recent';
            last METHOD;
            
        };
        ($mode eq 'chapter') and do {
            ($value = $args{query}) and do {
              $args{search} = {field => {name => $info->{name}, 
                                         text => $info->{text} },
                               value => $value};
#              $args{search} = {field => $info->{name},
#                               value => $value };
              $method = 'query';
              last METHOD;
            };
            $value = $args{id} or do {
                $self->{error} = q{Must supply a chapterid};
                return;
            };
            push @{$args{search}}, {field => $info->{id},
                                    value => $value};
            if (my $subvalue = $args{subchapter}) {
                push @{$args{search}}, {field => $info->{name},
                                        value => $subvalue};
                $method = 'search';
            }
            else {
                $method = 'info';
            }
            last METHOD;
        };
        ($value = $args{query}) and do {
            $args{search} = {field => {name => $info->{name}, 
                                       text => $info->{text} },
                             value => $value };
            $method = 'search';
            last METHOD;
        };
        ($value = $args{letter}) and do {
            $args{search} = {field => $info->{name},
                             value => $value };
            $method = 'letter';
            last METHOD;
        };
        ($value = $args{id}) and do {
            $args{search} = {field => $info->{id},
                             value => $value };
            $method = 'info';
            last METHOD;
        };
        ($value = $args{name}) and do {
            $args{search} = {field => $info->{name},
                             value => $value };
            $method = 'info';
            last METHOD;
        };
        $self->{error} = q{Cannot determine a method name};
        return;
    }
    
    $obj->$method(search => $args{search}, user_fields => $fields);
    $self->{results} = $obj->{results};
    if (my $error = $obj->{error}) {
        $self->{error} = $error;
        return;
    }
    return 1;
}

sub make {
  my ($class, %args) = @_;
  for (qw(table cdbi)) {
    die qq{Must supply an '$_' arg} unless defined $args{$_};
  }
  my $self = {results => undef, error => '',
              table => $args{table}, cdbi => $args{cdbi}};
  bless $self, $class;
}

package CPAN::Search::Lite::Query::author;
use base qw(CPAN::Search::Lite::Query);
use CPAN::Search::Lite::DBI qw($dbh);

sub info {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = $args{user_fields} || 
      [ qw(auth_id cpanid email fullname) ];
    $args{table} = 'auths';

    return unless ($self->{results} = $self->fetch(%args, distinct => 1));
    return 1 if $args{user_fields};

    $args{fields} = [qw(dist_id dist_name birth
                        dist_abs dist_vers dist_file)];
    $args{table} = 'dists';
    $args{search} = {field => 'auth_id', 
                     value => $self->{results}->{auth_id}};
    $args{order_by} = 'dist_name';
    my $cpanid = $self->{results}->{cpanid};
    if ($self->{results}->{dists} = $self->fetch(%args, wantarray => 1)) {
        foreach my $dist (@{$self->{results}->{dists}}) {
            $dist->{download} = 
                $self->download($cpanid, $dist->{dist_file});
            $dist->{birth} = $self->date_format($dist->{birth});
        }
    }
    return 1;
}

sub search {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(auth_id cpanid fullname) ];
    $args{table} = 'auths';
    $args{limit} = $max_results;
    $args{order_by} = 'cpanid';
    return unless $self->{results} = $self->fetch(%args);
    if (ref($self->{results}) ne 'ARRAY') {
        return $self->query(mode => 'author', 
                            id => $self->{results}->{auth_id});
    }
    return 1;
}

sub letter {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(auth_id cpanid fullname) ];
    $args{table} = 'auths';

    $args{order_by} = 'cpanid';
    return unless $self->{results} = $self->fetch(%args, letter => 1,
                                                  wantarray => 1);
    return 1;
}

package CPAN::Search::Lite::Query::module;
use base qw(CPAN::Search::Lite::Query);
use CPAN::Search::Lite::Util qw(%chaps);
use CPAN::Search::Lite::DBI qw($dbh);

sub info {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = $args{user_fields} ||
      [ qw(mod_id mod_name mod_abs doc src mod_vers 
           dslip chapterid dist_id dist_name dist_file
           auth_id cpanid fullname) ];
    $args{table} = 'dists';
    $args{join} = { mods => 'dist_id',
                    auths => 'auth_id',
                  };

    return unless ($self->{results} = $self->fetch(%args, distinct => 1,
                                                   case_sensitive => 1));
    return 1 if $args{user_fields};
    my $mod_name = $self->{results}->{mod_name};

    if ($self->{results}->{doc}) {
        (my $mod_link = $mod_name) =~ s{::}{/}g;
        my $html = $self->{results}->{dist_name} . '/' .
            $mod_link . '.html';
        $self->{results}->{html} = $html;
    }

    if ($self->{results}->{src}) {
        (my $mod_link = $mod_name) =~ s{::}{/}g;
        my $html = $self->{results}->{dist_name} . '/' .
            $mod_link . '.pm.html';
        $self->{results}->{htmlsrc} = $html;
    }

    $self->{results}->{download} = 
        $self->download($self->{results}->{cpanid}, 
                        $self->{results}->{dist_file});

    if (my $chapterid = $self->{results}->{chapterid}) {
        $self->{results}->{chap_link} = $self->chap_link($chapterid);
        $self->{results}->{chap_desc} = $self->chap_desc($chapterid);
        $self->{results}->{subchapter} = $self->mod_subchapter($mod_name);
    }

    if (my $what = $self->{results}->{dslip}) {
        $self->{results}->{dslip_info} = $self->expand_dslip($what);
    }
    
    $args{fields} = [ qw(rep_id ppm_vers browse abs alias)];
    $args{table} = 'ppms';
    $args{join} = {reps => 'rep_id'};
    $args{order_by} = 'alias';
    $args{search} = {field => 'dist_id',
                     value => $self->{results}->{dist_id}};
    $self->{results}->{ppms} = $self->fetch(%args, wantarray => 1);

    my $ppms = $self->{results}->{ppms};
    (my $dist_letter = $self->{results}->{dist_name}) =~ s{^(\w).*}{$1};
    if ($dist_letter and ref($ppms) eq 'ARRAY') {
      foreach my $ppm (@$ppms) {
        my $rep_id = $ppm->{rep_id};
        next unless ($rep_id == 5 || $rep_id == 6);
        $ppm->{browse} =~ s{-A\.html}{-$dist_letter.html};
      }
    }

    return 1;
}

sub search {
  my ($self, %args) = @_;
  return unless $args{search};
  
  $args{fields} = [ qw(mod_id mod_name mod_abs chapterid) ];
  $args{table} = 'mods';
  $args{order_by} = 'mod_name';
  $args{limit} = $max_results;
  return unless $self->{results} = $self->fetch(%args);
  my $results = $self->{results};
  if (ref($results) ne 'ARRAY') {
    return $self->query(mode => 'module',
                        id => $self->{results}->{mod_id});
  }
  else {
    foreach my $result (@$results) {
      next unless my $id = $result->{chapterid};
      next unless my $chap = $chaps{$id};
      next unless my $mod_name = $result->{mod_name};
      my $sub_chapter = $self->mod_subchapter($mod_name);      
      $result->{chapter} = $chap . '/' . $sub_chapter;
    }
  }
  if (scalar @$results == 1) {
    return $self->query(mode => 'module',
                        id => $self->{results}->[0]->{mod_id});
  }
  return 1;
}

sub letter {
  my ($self, %args) = @_;
  return unless $args{search};
  
  $args{fields} = [ qw(mod_id mod_name mod_abs) ];
  $args{table} = 'mods';
  $args{order_by} = 'mod_name';
  my $match;
  return unless $match = $self->fetch(%args, letter => 1,
                                      wantarray => 1);
  $self->{results} = $match;
  my $mod_re = qr{^([^:]+)::};
  if ($args{search}->{value} =~ /^\w$/) {
    my %count;
    foreach my $result (@$match) {
      if ($result->{mod_name} =~ /$mod_re/) {
        $count{$1}++;
      }
    }
    my %seen;
    my $results = [];
    foreach my $result (@$match) {
      if ($result->{mod_name} =~ /$mod_re/) {
        my $letter = $1;
        my $count = $count{$letter};
        if ( $count == 1) {
          push @$results, $result;
        }
        else {
          next if $seen{$letter};
          push @$results, {letter => $letter,
                           count => $count};
          $seen{$letter}++;
        }
      }
      else {
        push @$results, $result;
      }
    }
    $self->{results} = $results;
  }
  return 1;
}

package CPAN::Search::Lite::Query::dist;
use base qw(CPAN::Search::Lite::Query);
use CPAN::Search::Lite::Util qw(%chaps);
use CPAN::Search::Lite::DBI qw($dbh);

sub info {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = $args{user_fields} ||
      [ qw(dist_id dist_name dist_abs dist_vers md5
           dist_file size birth readme changes meta install
           auth_id cpanid fullname) ];
    $args{table} = 'dists';
    $args{join} = {auths => 'auth_id'};

    return unless ($self->{results} = $self->fetch(%args, distinct => 1,
                                                   case_sensitive => 1));
    $self->{results}->{birth} = $self->date_format($self->{results}->{birth});
    $self->{results}->{size} = $self->size_format($self->{results}->{size});
    return 1 if $args{user_fields};

    $self->{results}->{download} = 
        $self->download($self->{results}->{cpanid}, $self->{results}->{dist_file});

    $args{join} = {reps => 'rep_id'};
    $args{table} = 'ppms';
    $args{fields} = [ qw(rep_id ppm_vers browse abs alias) ];
    $args{order_by} = 'alias';
    $args{search} = {field => 'dist_id', 
                     value => $self->{results}->{dist_id}
                    };
    $self->{results}->{ppms} = $self->fetch(%args, wantarray => 1);

    my $ppms = $self->{results}->{ppms};
    (my $dist_letter = $self->{results}->{dist_name}) =~ s{^(\w).*}{$1};
    if ($dist_letter and ref($ppms) eq 'ARRAY') {
      foreach my $ppm (@$ppms) {
        my $rep_id = $ppm->{rep_id};
        next unless ($rep_id == 5 || $rep_id == 6);
        $ppm->{browse} =~ s{-A\.html}{-$dist_letter.html};
      }
    }

    $args{join} = undef;
    $args{table} = 'mods';
    $args{fields} = [ qw(mod_id mod_name mod_abs mod_vers doc dslip src) ];
    $args{order_by} = 'mod_name';
    $self->{results}->{mods} = $self->fetch(%args, wantarray => 1);
    my $mod_dslip;
    my $distname = $self->{results}->{dist_name};
    if (my $mods = $self->{results}->{mods}) {
        foreach my $mod (@$mods) {
            my $mod_name = $mod->{mod_name};
            (my $trial_dist = $mod_name) =~ s!::!-!g;
            $mod_dslip = $mod->{dslip}
                if ($trial_dist eq $distname and $mod->{dslip});
            if ($mod->{doc}) {
                (my $docpath = $mod_name) =~ s!::!/!g;
                $mod->{html} = $distname . '/' . $docpath . '.html';
            }
            if ($mod->{src}) {
                (my $mod_link = $mod_name) =~ s{::}{/}g;
                my $html = $self->{results}->{dist_name} . '/' .
                    $mod_link . '.pm.html';
                $mod->{htmlsrc} = $html;
            }
        }
    }
    if ($mod_dslip) {
        $self->{results}->{dslip} = $mod_dslip;
        $self->{results}->{dslip_info} = $self->expand_dslip($mod_dslip);
    }

    $args{table} = 'chaps';
    $args{fields} = [ qw(chaps.chapterid subchapter chap_link) ];
    $args{join} = {chapters => 'chapterid'};
    $args{order_by} = 'chapterid';
    if ($self->{results}->{chaps} = $self->fetch(%args, wantarray => 1)) {
        foreach my $chap (@{$self->{results}->{chaps}}) {
            my $chapterid = $chap->{'chaps.chapterid'} + 0;
            next unless $chapterid;
            $chap->{chap_desc} = $self->chap_desc($chapterid);
        }
    }
  
    $args{search} = {field => 'reqs.dist_id', 
                     value => $self->{results}->{dist_id},
                    };
    $args{table} = 'reqs';
    $args{join} = {mods => 'mod_id'};
    $args{fields} = [ qw(mod_id req_vers mod_name mod_abs) ];
    $args{order_by} = 'mod_name';
    $self->{results}->{reqs} = $self->fetch(%args, wantarray => 1);
    return 1;
}

sub search {
  my ($self, %args) = @_;
  return unless $args{search};
  
  $args{fields} = [ qw(dist_id dist_name dist_abs chapterid subchapter) ];
  $args{table} = 'dists';
  $args{order_by} = 'dist_name';
  $args{limit} = $max_results;
  $args{left_join} = {chaps => 'dist_id'};
  return unless $self->{results} = $self->fetch(%args);
  my $results = $self->{results};
  if (ref($results) ne 'ARRAY') {
    return $self->query(mode => 'dist',
                        id => $self->{results}->{dist_id});
  }
  else {
    foreach my $result (@$results) {
      next unless my $id = $result->{chapterid};
      next unless my $subchapter = $result->{subchapter};
      next unless my $chap = $chaps{$id};
      $result->{chapter} = $chap . '/' . $subchapter;
    }
  }
  my ($tmp, $chapters, @order, %seen);
  foreach my $result (@$results) {
    my $dist_name = $result->{dist_name};
    unless ($seen{$dist_name}) {
      $seen{$dist_name}++;
      push @order, $dist_name;
    }
    $tmp->{$dist_name} = {dist_id => $result->{dist_id},
                          dist_abs => $result->{dist_abs}};
    next unless $result->{chapter};
    push @{$chapters->{$dist_name}}, $result->{chapter};
  }
  my $pruned;
  foreach my $dist_name(@order) {
    push @$pruned, {dist_name => $dist_name,
                   %{$tmp->{$dist_name}},
                   chapters => $chapters->{$dist_name},
                   };
  }
  if (scalar @$pruned == 1) {
    return $self->query(mode => 'dist',
                        id => $pruned->[0]->{dist_id});
  }
  $self->{results} = $pruned;
  return 1;
}

sub letter {
  my ($self, %args) = @_;
  return unless $args{search};
  
  $args{fields} = [ qw(dist_id dist_name dist_abs) ];
  $args{table} = 'dists';
  $args{order_by} = 'dist_name';
  my $match;
  return unless $match = $self->fetch(%args, letter => 1,
                                      wantarray => 1);
  $self->{results} = $match;

  my $dist_re = qr{^([^-]+)-};
  if ($args{search}->{value} =~ /^\w$/) {
    my %count;
    foreach my $result(@$match) {
      if ($result->{dist_name} =~ /$dist_re/) {
        $count{$1}++;
      }
    }
    my %seen;
    my $results = [];
    foreach my $result (@$match) {
      if ($result->{dist_name} =~ /$dist_re/) {
        my $letter = $1;
        my $count = $count{$letter};
        if ( $count == 1) {
          push @$results, $result;
        }
        else {
          next if $seen{$letter};
          push @$results, {letter => $letter,
                           count => $count};
          $seen{$letter}++;
        }
      }
      else {
        push @$results, $result;
      }
    }
    $self->{results} = $results;
  }
  return 1;
}

sub recent {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(birth dist_id dist_name dist_abs dist_vers
                        dist_file auth_id cpanid) ];
    $args{table} = 'dists';
    $args{join} = {auths => 'auth_id'};
    $args{order_by} = 'birth desc,dist_name';
    my $results;
    return unless $results = $self->fetch(%args, wantarray => 1,
                                                 age => 1);
    foreach my $result(@$results) {
        $result->{download} = $self->download($result->{cpanid}, $result->{dist_file});
        $result->{birth} = $self->date_format($result->{birth});
    }
    $self->{results} = $results;
    return 1;
}


package CPAN::Search::Lite::Query::chapter;
use base qw(CPAN::Search::Lite::Query);
use CPAN::Search::Lite::DBI qw($dbh);

sub info {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(dist_id dist_abs subchapter) ];
    $args{table} = 'chaps';
    $args{order_by} = 'subchapter';
    $args{join} = {dists => 'dist_id'};
    my $match;
    return unless $match = $self->fetch(%args, wantarray => 1,
                                          distinct => 1);
    my %count;
    $count{$_->{subchapter}}++ for @$match;
    my $results = [];
    my %seen;
    foreach my $result (@$match) {
      my $subchapter = $result->{subchapter};
      next if $seen{$subchapter};
      my $count = $count{$subchapter};
      if ($count > 1) {
        push @$results, {subchapter => $subchapter,
                         count => $count};
        $seen{$subchapter}++;
      }
      else {
        push @$results, $result;
      }
    }
    $self->{results} = $results;
    return 1;
}

sub search {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(dist_id dist_name dist_abs) ];
    $args{table} = 'chaps';
    $args{join} = {dists => 'dist_id'};
    $args{order_by} = 'dist_name';
    return unless $self->{results} = $self->fetch(%args, wantarray => 1);
    return 1;
}

sub query {
    my ($self, %args) = @_;
    return unless $args{search};
    
    $args{fields} = [ qw(dist_id dist_name dist_abs 
                         chaps.chapterid chap_link) ];
    $args{table} = 'chaps';
    $args{join} = {dists => 'dist_id', chapters => 'chapterid'};
    $args{order_by} = 'chap_link,dist_name';
    $args{limit} = 2 * $max_results;

    return unless $self->{results} = $self->fetch(%args, wantarray => 1,
                                                  distinct => 1);
    foreach my $result (@{$self->{results}}) {
      my $chapterid = $result->{'chaps.chapterid'} + 0;
      next unless $chapterid;
      $result->{chap_desc} = $self->chap_desc($chapterid);
    }
    return 1;
}

package CPAN::Search::Lite::Query;

sub fetch {
    my ($self, %args) = @_;
    my $fields = $args{fields};
    my @fields = ref($fields) eq 'ARRAY' ? 
        @{$fields} : ($fields);
    my $sql = $self->sql_statement(%args) or do {
        $self->{error} = 'Error constructing sql statement: ' .
            $self->{error};
        return;
    };
    my $sth = $dbh->prepare($sql) or do {
        $self->db_error();
        return;
    };
    $sth->execute();
    if ($sth->rows == 0) {
        $sth->finish;
        return;
    }
 
    if ($sth->rows == 1 and not $args{wantarray}) {
        my %results;
        @results{@fields} = $sth->fetchrow_array;
        $sth->finish;
        return \%results;
    }
    else {
        my (%hash, $results);
        while ( @hash{@fields} = $sth->fetchrow_array) {
            my %tmp = %hash;
            push @{$results}, \%tmp;
        }    
        $sth->finish;
        return (defined $args{distinct} and not defined $args{wantarray}) ? 
            $results->[0] : $results;
    }    
}

sub sql_statement {
    my ($self, %args) = @_;

    my $search = $args{search};
    my $chap = (ref($search) eq 'ARRAY');
    my $distinct = $args{distinct} ? 'DISTINCT' : '';
    my $binary = $args{case_sensitive} ? 'BINARY' : '';
    my $text_search = (not $chap and ref($search->{field}) eq 'HASH');
    my $regex = (not $distinct and not $chap and not ref($search->{value}) 
                 and $search->{value} =~ /\^|\$|\*|\+|\?|\||::|\b-\b/);
    if ($regex) {
        my $v = $search->{value};
        eval{$v =~ /$v/};
        if ($@) {
            $self->{error} = $@;
            return;
        }
    }
    my $letter = $args{letter};
    my $age = $args{age};
    my $not = ($regex or $letter or $chap or $age);
    my ($match, @words);
    if ($text_search and not $not) {
        @words = split ' ', $search->{value};
        my %excl = map {$_ => 1} grep /^-/, @words;
        my $stems = stem(@words);
        my @stems = @$stems;
        for (0 .. $#stems) {
            $stems[$_] = "-$stems[$_]" if $excl{$words[$_]};
        }
        my $join = join ' ', map { /^-/ ? "$_*" : "+$_*" } @stems;
        $match = q/ MATCH (/ .
                           $search->{field}->{text} .
                           q/) AGAINST ('/ . $join .
            q/' IN BOOLEAN MODE )/;
    }

    my $table = $args{table};
    my @tables = ($table);

    my $fields = $args{fields};
    my @fields = ref($fields) eq 'ARRAY' ? 
        @{$fields} : ($fields);
    for (@fields) {
        $_ = $full_id->{$_} if $full_id->{$_};
#        $_ = $table . '.chapterid' if $_ eq 'chapterid';
#        $_ = qq{DATE_FORMAT($_, '%e %b %Y')} if $_ eq 'birth';
#        $_ = qq{FORMAT($_, 0)} if $_ eq 'size';
    }
    push @fields, "$match as abs_score" if defined $match;

    my $str_match;
    if ($regex or $text_search) {
      my $value = $search->{value};
      $value =~ s/[\^\$\*\+\?\|]//g;
      my $name = $search->{field}->{name};
      my $tail = q{([a-zA-Z0-9_]*)?};
    MATCH: {
	($name eq 'dist_name') and do {
	  $value = 'CGI.pm' if (uc $value eq 'CGI');
	  if ($value =~ / /) {
	    (my $re = $value) =~ s@\s+@${tail}-@g;
	    $str_match = qq{$name REGEXP '^$re'};
	  }
	  else {
	    $str_match = ($value =~ /-/) ? 
	      qq{$name REGEXP '^$value'} : 
		qq{$name REGEXP '^$value(-[-a-zA-Z0-9_]*)?\$'};
	  }
	  last MATCH;
	};
	($name eq 'mod_name') and do {
	  if ($value =~ / /) {
	    (my $re = $value) =~ s@\s+@${tail}::@g;
	    $str_match = qq{$name REGEXP '^$re'};
	  }
	  else {
	    $str_match = ($value =~ /::/) ? 
	      qq{$name REGEXP '^$value'} : 
		qq{$name REGEXP '^$value(::[:a-zA-Z0-9_]*)?\$'};
	  }
	  last MATCH;
	};
	($name eq 'cpanid') and do {
	  if ($value =~ / /) {
	    (my $re = $value) =~ s@\s+@$tail @g;
	    $str_match = qq{$search->{field}->{text} REGEXP '^$re'};
	  }
	  else {
	    $str_match = qq{$name REGEXP '^$value([-a-zA-Z0-9_]*)?\$'};
	  }
	  last MATCH;
	};
	$str_match = qq{STRCMP($name, '$value') = 0};
      }
    }
    push @fields, "$str_match as str_score" if $str_match;

    my $sql = qq{SELECT $distinct } . join(',', @fields);

    my $where;
  QUERY: {
        $chap and do {
            $where = qq{ $search->[0]->{field} = $search->[0]->{value} };
            if (defined $search->[1]) {
                $where .= ' AND ' .
                    qq{ $search->[1]->{field} = '$search->[1]->{value}' }; 
            }
            last QUERY;
        };
        $letter and do {
            my $value = $search->{value};
            my $star = ($value =~ /^\w$/) ? '%' : 
                ($table eq 'mods' ? '::%' : '-%');
            $where = qq{ $search->{field} LIKE '$value$star' };
            last QUERY;
        };
        $age and do {
            $where = qq{ TO_DAYS(NOW()) - TO_DAYS($search->{field}) <= $search->{value} };
            last QUERY;
        };
        $regex and do {
            $where = qq{ $search->{field}->{name} REGEXP '$search->{value}' };
            last QUERY;
        };
        $text_search and do {
            my $name = $search->{field}->{name};
            $where = join ' AND ', 
                map {" $name ". (s/^-// ? 'NOT ' : '') . "LIKE '%$_%' "} @words;
            last QUERY;
        };
        $full_id->{$search->{field}} and do {
            $where = qq{ $search->{field} = $search->{value} };
            last QUERY;
        };
        $where = qq{ $binary $search->{field} = '$search->{value}' };
    }

    my $join;
#    if (defined $args{join}) {
#        my @join = ();
#        while (my ($join, $id) = each %{$args{join}}) {
#            push @tables, $join;
#            push @join, ($table.'.'.$id. ' = ' . $join.'.'.$id); 
#        }
#        $join = join ' AND ', @join;
#    }
#    $sql .= ' FROM ' . join ',', @tables;

    $sql .= ' FROM ' . $table;
    my $left_join = $args{join} || $args{left_join};
    if ($left_join) {
      if (ref($left_join) eq 'HASH') {
        foreach my $key(keys %$left_join) {
#          $sql .= " LEFT JOIN $key using ($left_join->{$key}) ";
            my $id = $left_join->{$key};
          $sql .= " LEFT JOIN $key ON $table.$id=$key.$id ";
        }
      }
    }

    if ($text_search and not $not) {
        $sql .= ' WHERE ( ( ' . $where . ' ) OR ( ' . $match . ' ) )';
    }
    else {
        $sql .= ' WHERE ( ' . $where . ' )';
    }
    $sql .= ' AND (' . $join . ')' if $join;

    my $order_by = '';
    if ($str_match) {
      $order_by = 'str_score desc';
    }
    if ($text_search and not $not) {
      $order_by = $str_match ? qq{$order_by,abs_score desc} : 'abs_score desc';
    }
    if (my $user_order_by = $args{order_by}) {
      $order_by = $order_by ? "$order_by,$user_order_by" : $user_order_by;
    }
    if ($order_by) {
      $sql .= qq{ ORDER BY $order_by };
    }

    if (my $limit = $args{limit}) {
        my ($min, $max) = ref($limit) eq 'HASH' ?
            ( $limit->{min} || 0, $limit->{max} ) :
                (0, $limit );
        $sql .= qq{ LIMIT $min,$max };
    }
    return $sql;
}

sub expand_dslip {
    my ($self, $string) = @_;
    my $entries = [];
    my @info = split '', $string;
    my @given = qw(d s l i p);
    for (0 .. 4) {
        my $entry;
        my $given = $given[$_];
        my $info = $info[$_];
        $entry->{desc} = $dslip->{$lang}->{$given}->{desc};
        $entry->{what} = (not $info or $info eq '?') ?
            $pages->{$lang}->{na} : $dslip->{$lang}->{$given}->{$info};
        push @$entries, $entry;
    }
    return $entries;
}

sub download {
    my ($self, $cpanid, $dist_file) = @_;
    (my $fullid = $cpanid) =~ s!^(\w)(\w)(.*)!$1/$1$2/$1$2$3!;
    my $download = $fullid . '/' . $dist_file;
    return $download;
}

sub chap_link {
    my ($self, $id) = @_;
    return $chaps{$id};
}

sub chap_desc {
    my ($self, $id) = @_;
    return $chaps_desc->{$lang}->{$id};
}

sub mod_subchapter {
  my ($self, $mod_name) = @_;
  (my $sc = $mod_name) =~ s{^([^:]+).*}{$1};
  return $sc;
}

sub dist_subchapter {
  my ($self, $dist_name) = @_;
  (my $sc = $dist_name) =~ s{^([^-]+).*}{$1};
  return $sc;
}

sub db_error {
    my ($obj, $sth) = @_;
    return unless $dbh;
    $sth->finish if $sth;
    $obj->{error} = q{Database error: } . $dbh->errstr;
}

sub date_format {
    my ($self, $date) = @_;
    my @e = split /-/, $date;
    return sprintf("%d %s %d", $e[2], $months->{$lang}->{$e[1]}, $e[0]);
}

sub size_format {
    my ($self, $size) = @_;
    my ($test, $string);
  SWITCH: {
        ( ($test = $size / GB) && int($test) > 0) and do {
            $string = sprintf('%.1f GB', $test);
            last SWITCH;
        };
        ( ($test = $size / MB) && int($test) > 0) and do {
            $string = sprintf('%.1f MB', $test);
            last SWITCH;
        };
        ( ($test = $size / KB) && int($test) > 0) and do {
            $string = sprintf('%.1f KB', $test);
            last SWITCH;
        };
        $string = sprintf("%d $pages->{$lang}->{bytes}", $size);
    }
    $string =~ s{\.}{,} unless ($lang eq 'en');
    return $string;
}

1;

__END__

=head1 NAME

CPAN::Search::Lite::Query - perform queries on the database

=head1 SYNOPSIS

  my $max_results = 200;
  my $query = CPAN::Search::Lite::Query->new(db => $db,
                                             user => $user,
                                             passwd => $passwd,
                                             max_results => $max_results);
  $query->query(mode => 'module', name => 'Net::FTP');
  my $results = $query->{results};

=head1 CONSTRUCTING THE QUERY

This module queries the database via various types of queries
and returns the results for subsequent display. The 
C<CPAN::Search::Lite::Query> object is created via the C<new> method as

  my $query = CPAN::Search::Lite::Query->new(db => $db,
                                             user => $user,
                                             passwd => $passwd,
                                             max_results => $max_results);

which takes as arguments

=over 3

=item * db =E<gt> $db

This is the name of the database.

=item * user =E<gt> $user

This is the user under which the database connection will be made.

=item * passwd =E<gt> $passwd

This is the password to use when connecting.

=item * max_results =E<gt> $max_results

This is the maximum value used to limit the number of results
returned under a user query. If not specified, a value contained
within C<CPAN::Search::Lite::Query> will be used.

=item * lang =E<gt> $lang

This is used to specify what language the description of the
CPAN chapter ids and the dslip information is to be returned
in. If not specified, or if specified but not present as
a key in C<%langs> of C<CPAN::Search::Lite::Util>, the
default of C<en> (English) will be used.

=back

A basic query then is constructed as

   $query->query(mode => $mode, $type => $value);

with the results available as

   my $results = $query->{results}

There are four basic modes:

=over 3

=item * module

This is for information on modules.

=item * dist

This is for information on distributions.

=item * author

This is for information on CPAN authors or cpanids.

=item * chapter

This is for information on chapters associated with distributions
and modules.

=back

=head2 C<module>, C<dist>, and C<author> modes

For a mode of C<module>, C<dist>, and C<author>, there are
four basic options to be used for the C<$type =E<gt> $value> option:

=over 3

=item * query =E<gt> $query_term

This will search through module names and abstracts, 
distribution names and abstracts, or CPAN author names
and full names (for C<module>, C<dist>, and C<author> modes
respectively). The results generally are case insensitive.
Matches are reported that match all search terms supplied -
for example, C<$query_term = 'foo bar'> will find occurences
of C<foo> I<and> C<bar>. To exclude a term in C<$query_term>, 
prepend that term with a minus sign = C<$query_term = 'foo -bar'> 
will find all instances C<foo> that don't include C<bar>. 
Regular expressions (as used by C<mysql>) are also supported.

=item * name =E<gt> $name

This will report exact matches (in a case sensitive manner)
for the module name, distribution name, or CPAN author id,
for C<module>, C<dist>, and C<author> modes
respectively.

=item * letter =E<gt> $letter

If C<$letter> is a single letter, this will find all
modules, distributions, or CPAN author ids beginning
with that letter (for C<module>, C<dist>, and C<author> modes
respectively). If C<$letter> is more than one letter,
this will find all distribtion names matching
C<$letter-*> (for the C<dist> mode) or all module
names matching C<$letter::*> (for the C<module> mode).

=item * id =E<gt> $id

This will look up information on the primary key according
to the mode specified. This is more for internal use,
to help speed up queries; using this "publically" is
probably not a good idea, as the ids may change over the
course of time.

=back

As well, for the C<dist> mode there is an additional type:
C<recent =E<gt> $age>, which will report all distribtions
uploaded in the last C<$age> days. If C<$age> is not
specified, it will default to 7.

=head2 C<chapter> mode

For a mode of C<chapter>, one can specify three additional
arguments:

=over 3

=item * id =E<gt> $chapterid

This argument will look up all subchapters
with the specified numerical C<$chapterid> (see C<%chaps>
of L<CPAN::Search::Lite::Util> for a description).

=item * subchapter =E<gt> $subchapter

This argument will look up all distributions
with the specified C<$subchapter> within the given chapter
specified by C<$chapterid>.

=item * query =E<gt> $query_term

This argument will look up all distributions who
have a subchapter matching C<$query_term>.

=back

=head1 RESULTS

After making the query, the results can be accessed through

  my $results = $query->{results};

No results either can mean no matches were found, or
else an error in making the query resulted (in which case,
a brief error message is contained in C<$query-E<gt>{error}>).
Assuming there are results, what is returned depends on
the mode and on the type of query. See L<CPAN::Search::Lite::Populate>
for a description of the fields in the various tables
listed below - these fields are used as the keys of the
hash references that arise.

=head2 C<author> mode

=over 3

=item * C<name> or C<id> query

This returns the C<auth_id>, C<cpanid>, C<email>, and C<fullname>
of the C<auths> table. As well, an array reference
C<$results-E<gt>{dists}> is returned representing
all distributions associated with that C<cpanid> - each
member of the array reference is a hash reference
describing the C<dist_id>, C<dist_name>, C<birth>,
C<dist_abs>, C<dist_vers>, and C<dist_file> fields in the
C<dists> table. An additional entry, C<download>, is
supplied, which can be used as C<$CPAN/authors/id/$download>
to specify the url of the distribution.

=item * C<letter> query

This returns an array reference, each member of which is
a hash reference containing the C<auth_id>, C<cpanid>, 
and C<fullname> fields.

=item * C<query> query

If this results in more than one match, an array reference
is returned, each member of which is a hash reference containg
the C<auth_id>, C<cpanid>, and C<fullname> fields. If there
is only one result found, a C<name> query based on the
matched C<cpanid> is performed.

=back

=head2 C<module> mode

=over 3

=item * C<name> or C<id> query

This returns the C<mod_id>, C<mod_name>, C<mod_abs>, C<doc>, C<mod_vers>,
C<dslip>, C<chapterid>, C<dist_id>, C<dist_name>, C<dist_file>,
C<auth_id>, C<cpanid>, and C<fullname> 
of the C<auths>, C<mods>, and C<dists> tables.
As well, the following entries may be present.

=over 3

=item * C<html>

If C<doc> is true, an entry C<html> is constructed giving the
location (relative to C<html_root>) of the html file.

=item * C<download>

This can be used as C<$CPAN/authors/id/$download>
to specify the url of the distribution.

=item * C<chap_desc>

An accompanying entry C<chap_desc> is supplied giving a
description of C<chapterid>, if present. This is given in
the language specified, if present, with a default of English. 

=item * C<chap_link>

An accompanying entry C<chap_link> is supplied giving a
string (in English) suitable for use in a link for 
C<chapterid>, if present. 

=item * C<dslip_info>

If C<dslip> is available, an array reference C<dslip_info> is supplied,
each entry being a hash reference. The hash reference contains
two keys - C<desc>, whose value is a general description of the
what the dslip entry represents, and C<what>, whose value is
a description of the entry itself.

=item * C<ppms>

If there are ppm packages available for the distribution
containing the module, an array reference C<ppms> is supplied,
each item of which is a hash reference.
There are four keys in this hash reference (coming from
C<$repositories> of L<CPAN::Search::Lite::Util>) - C<rep_id>,
giving the repository's rep_id, C<desc>, giving a description
of the repository, C<alias>, an alias for the repository,
and C<browse>, giving a url to the
repository.

=back

=item * C<letter> query

This returns an array reference, each entry of which can
be of two types. If there are multiple occurrences
of a module matching C<FOO::*> at the top level, then the entry 
is a hash reference with key C<letter> and associated value C<FOO>,
as well as a key C<count> with value giving the number of matching
entries. If there is only one module matching C<FOO::*> at the
top level, then the entry is
a hash reference containing the C<mod_name>, C<mod_id>, and
C<mod_abs> fields.

=item * C<query> query

If this results in more than one match, an array reference
is returned, each member of which is a hash reference containing
the C<mod_id>, C<mod_name>, and C<mod_abs> fields. If there
is only one result found, a C<name> query based on the
matched C<mod_name> is performed.

=back

=head2 C<dist> mode

=over 3

=item * C<name> or C<id> query

This returns the C<dist_id>, C<dist_name>, C<dist_abs>, C<dist_vers>,
C<dist_file>, C<size>, C<birth>, C<readme>, C<changes>, C<meta>,
C<install>, C<auth_id>, C<cpanid>, and C<fullname>
of the C<auths>, C<mods>, and C<dists> tables. Note that
C<readme>, C<changes>, C<meta>, and C<install> are boolean values
just indicating if the corresponding file is present.
As well, the following entries may be present.

=over 3

=item * C<download>

This can be used as C<$CPAN/authors/id/$download>
to specify the url of the distribution.

=item * C<mods>

This is an array reference containing information on the
modules present. Each entry is a hash reference containing the
C<mod_id>, C<mod_name>, C<mod_abs>, C<mod_vers>, C<doc>, and C<dslip>
fields for the module. If C<doc> is present, an C<html> entry
is created giving the location (relative to C<html_root>) of
the documentation.

=item * C<dslip> and C<dslip_info>

If the module name and distribution name are related by
C<s/::/->, the C<dslip> and C<dslip_info> entries for
that module are returned.

=item * C<chaps>

If present, an array reference C<chaps> is returned, each
entry of which is a hash reference containing C<chapterid>,
C<subchapter>, C<chap_desc> (a description of the
chapter id, in the language specified), and C<chap_link>
(a string in English suitable for use as a link to
C<chapterid>).

=item * C<reqs>

If prerequisites for the distribtion have been specified,
an array reference C<reqs> is returned, each item of
which is a hash reference containing C<mod_id>, C<req_vers>, 
C<mod_name>, and C<mod_abs> for each prerequisite.

=item * C<ppms>

If there are ppm packages available for the distribution,
an array reference C<ppms> is supplied,
each item of which is a hash reference.
There are three keys in this hash reference (coming from
C<$repositories> of L<CPAN::Search::Lite::Util>) - C<rep_id>,
giving the repository's rep_id, C<desc>, giving a description
of the repository, and C<browse>, giving a url to the
repository.

=back

=item * C<letter> query

This returns an array reference, each entry of which can
be of two types. If there are multiple occurrences
of a distribution matching C<FOO-*> at the top level, then the entry 
is a hash reference with key C<letter> and associated value C<FOO>,
as well as a key C<count> with value giving the number of matching
entries. If there is only one distribution matching C<FOO-*> at the
top level, then the entry is
a hash reference containing the C<dist_name>, C<dist_id>, and
C<dist_abs> fields.

=item * C<query> query

If this results in more than one match, an array reference
is returned, each member of which is a hash reference containing
the C<dist_id>, C<dist_name>, and C<dist_abs> fields. If there
is only one result found, a C<name> query based on the
matched C<dist_name> is performed.

=item * C<recent> query

This performs a query for all distributions uploaded to
CPAN in the last 7 days. The result is an array reference,
each item of which is a hash reference containing the
C<birth>, C<dist_id>, C<dist_name>, C<dist_abs>, C<dist_vers>,
C<dist_file>, C<auth_id>, and C<cpanid> fields.
As well, for each entry a C<download> entry is present,
which can be used as C<$CPAN/authors/id/$download>
to specify the url of the distribution.

=back

=head2 C<chapter> mode

=over 3

=item * id =E<gt> $chapterid

This will return an array reference, each item of which
is a hash reference containing the corresponding
C<subchapter> field. If there is only one entry within
a subchapter, the C<dist_abs> and C<dist_id> of the associated 
distribution is also returned, while if there is more than one entry,
a key C<count> with value giving the number of matching
entries is returned.

=item * subchapter =E<gt> $subchapter

This will return an array reference corresponding to all
distributions with the specified subchapter within the given chapter.
Each item of the array reference is a hash reference specifying
the C<dist_name>, C<dist_id>, and C<dist_abs> of the
distribution.

=item * query =E<gt> $query_term

This will return an array reference,
each member of which is a hash reference containing
the C<dist_id>, C<dist_name>, C<dist_abs> fields,
C<chapterid>, and C<chap_link> fields. As well,
a C<chap_desc> field is returned, giving a description
of the main chapter.

=back

For a C<name> or C<id> query of C<dist>, C<author>, or
C<module>, if the query is constructed as

  $query->query(mode => $mode, $type => $value, fields => $fields);

where C<$fields> is an array reference, then only those
fields specified will be returned. For C<author>, only the
C<auths> table is searched, for C<module>, the C<mods>,
C<auths>, and C<dists> tables are searched, and for
C<dist>, the C<dists> and C<auths> tables are searched.

=head1 SEE ALSO

L<Apache2::CPAN::Search> and L<Apache2::CPAN::Query>.

=head1 COPYRIGHT

This software is copyright 2004 by Randy Kobes
E<lt>randy@theoryx5.uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself.

=cut

