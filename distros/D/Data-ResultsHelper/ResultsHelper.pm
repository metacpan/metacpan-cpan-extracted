#!/usr/bin/perl -w

package Data::ResultsHelper;

use vars qw($AUTOLOAD $VERSION);
use strict;

$VERSION = '1.04';

sub new {
  my $type  = shift;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    prefs                 => {},

    prefix                => 'rh',

    back_text             => 'back',
    next_text             => 'next',

    set_cookie            => 1,
    cookie_ttl            => '1 hour',
    base_dir              => "/tmp/results_helper",
    cookie_filename       => time . "." . $$,
    cookie_brick_over     => 0,

    #delimiter             => '\|',
    #filter_columns_offset => 0,
    #sort_code             => [],
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  unless($ARGS{cookie_name}) {
    if($0 && $0 =~ m@.+/(.+)$@) {
      $ARGS{cookie_name} = "rh_$1";
    } else {
      $ARGS{cookie_name} = "results_helper";
    }
  }
  my $self = bless \%ARGS, $type;

  my $prefs_defaults = {
    at_a_time             => 25,
    start_number          => 1,
    sort_column           => 0,
  };

  foreach my $key (qw(at_a_time start_number sort_column)) {
    if(exists $self->{prefs}{$key}) {
      next;
    } elsif(exists $self->form->{$key}) {
      $self->{prefs}{$key} = $self->form->{$key};
    } elsif(exists $prefs_defaults->{$key}) {
      $self->{prefs}{$key} = $prefs_defaults->{$key};
    }
  }
  return $self;
}

sub form {
  my $self = shift;
  unless($self->{form}) {

    $self->{form} = {};

    require CGI;
    my $q = CGI->new;

    my %form = $q->Vars;
    foreach my $key (keys %form) {
      my $value = $form{$key};
      if($value =~ /\0/) {
        $self->{form}{$key} = [split /\0/, $value];
      } else {
        $self->{form}{$key} = $value;
      }
    }
  }
  return $self->{form};
}

sub generate_results_ref {
  my $self = shift;

  unless($self->retrieve_results) {
    return {};
  }

  $self->_filter;

  $self->cache_results;

  if ($self->{headers} && (ref($self->{headers}) eq 'ARRAY')) {
    unshift(@{$self->{results}},$self->{headers});
  }

  $self->{results_ref} = {
  };

  $self->generate_toc_ref;
  $self->generate_show_cols_ref;
  $self->generate_header_ref;
  return $self->{results_ref};
}

sub cache_results {
  my $self = shift;
  if($self->set_cookie) {
    require File::CacheDir;
    my $cookie_name = $self->cookie_name;
    my $cache_dir = File::CacheDir->new({
      filename          => $self->cookie_filename,
      ttl               => $self->cookie_ttl,
      base_dir          => $self->base_dir,
      cookie_name       => $cookie_name,
      cookie_brick_over => $self->cookie_brick_over,
      set_cookie        => 1,
    });
    $cache_dir->{content_typed} = $ENV{CONTENT_TYPED} if($ENV{CONTENT_TYPED});
    my $filename = $cache_dir->cache_dir;

    $self->store($self->{results}, $filename) || $self->my_die("store to $filename failed");
  }
}

sub store {
  my $self = shift;
  require Storable;
  return Storable::store(@_);
}

sub retrieve {
  my $self = shift;
  require Storable;
  return Storable::retrieve(@_);
}

sub my_die {
  my $self = shift;
  die "@_";
}

sub generate_show_cols_ref {
  my $self = shift;
  my $ref = $self->{results_ref};
  for(my $i=0;$i<@{$self->{results}->[0]};$i++) {
    $ref->{"$self->{prefix}_show_cols"} ||= [];
    if($self->{results}[0][$i]) {
      push @{$ref->{"$self->{prefix}_show_cols"}}, $i;
    }
  }
}

sub second_page {
  my $self = shift;
  return ($self->get_pages > 1) ? 1 : 0;
}

sub generate_toc_ref {
  my $self = shift;

  return if(!$self->second_page && $self->smart_second_page_toc);

  my $ref = $self->{results_ref};
  $ref->{$self->{prefix} . "_low"}  = $self->low;
  $ref->{$self->{prefix} . "_high"} = $self->high;
  $ref->{$self->{prefix} . "_rows"} = $self->rows;

  $ref->{$self->{prefix} . "_toc_page_text"} = [];
  $ref->{$self->{prefix} . "_toc_page_href"} = [];

  my $more_form_tack_on_string = $self->more_form_tack_on_string;
  my $script_name = $self->script_name;
  my $href = "$script_name?start_number=-start-$more_form_tack_on_string";
  my $start;
  for(my $i=1;$i<=$self->get_pages($self->rows);$i++) {
    last if($self->toc_limit && $i > $self->toc_limit);
    $start = 1 + $self->{prefs}{at_a_time} * ($i - 1);
    my $tmp_href = $href;
    $tmp_href =~ s/-start-/$start/;
    push @{$ref->{$self->{prefix} . "_toc_page_text"}}, $i;
    push @{$ref->{$self->{prefix} . "_toc_page_href"}}, $tmp_href;
  }

  $ref->{$self->{prefix} . "_toc_back_text"} = $self->back_text;
  $ref->{$self->{prefix} . "_toc_next_text"} = $self->next_text;

  $self->link_current_page;
  $self->link_back_button($href);
  $self->link_next_button($href);
}

sub link_current_page {
  my $self = shift;
  my $ref = $self->{results_ref};

  my $temp_page = int($self->{prefs}{start_number}/$self->{prefs}{at_a_time}) + 1;
  my $temp_start_number = ($temp_page - 1) * $self->{prefs}{at_a_time} + 1;
  $ref->{$self->{prefix} . "_toc_page_href"}[$temp_page - 1] = '';
}

sub link_back_button {
  my $self = shift;
  my $href = shift;

  my $ref = $self->{results_ref};
  my $start = $self->{prefs}{start_number} - $self->{prefs}{at_a_time};

  ### if this is the first page, don't link the back button
  if($start < 1) {
    $ref->{$self->{prefix} . "_toc_back_href"} = '';
  } else {
    my $tmp_href = $href;
    $tmp_href =~ s/-start-/$start/;
    $ref->{$self->{prefix} . "_toc_back_href"} = $tmp_href;
  }
}

sub link_next_button {
  my $self = shift;
  my $href = shift;

  my $ref = $self->{results_ref};
  my $start = $self->{prefs}{start_number} + $self->{prefs}{at_a_time};

  ### if this is the last page, don't link the next button
  if($start > $self->rows) {
    $ref->{$self->{prefix} . "_toc_next_href"} = '';
  } else {
    my $tmp_href = $href;
    $tmp_href =~ s/-start-/$start/;
    $ref->{$self->{prefix} . "_toc_next_href"} = $tmp_href;
  }
}

sub script_name {
  my $self = shift;
  unless($self->{script_name}) {
    $ENV{HTTP_HOST}   ||= "";
    $ENV{SCRIPT_NAME} ||= "";
    $ENV{PATH_INFO}   ||= "";
    $self->{script_name} = "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}$ENV{PATH_INFO}";
  }
  return $self->{script_name};
}

sub generate_header_ref {
  my $self = shift;
  my $headers = shift || $self->{results}[0];

  my $ref = $self->{results_ref};
  $ref->{$self->{prefix} . "_header_text"}  = [];
  $ref->{$self->{prefix} . "_header_href"}  = [];

  ### set up the passed along query_string
  my $form_tack_on_string = $self->get_form_tack_on_string;

  ### do the table header row
  unless ($self->{no_header}){

    my $add_sort_column = ($self->{prefs}->{sort_column} =~ /^-?\d+(,[,\-\d]+)/) ? $1 : "";
    foreach my $i (@{$ref->{"$self->{prefix}_show_cols"}}) {
      next unless length($self->{results}[0][$i]);

      # doing the toggle for the links
      my $link = $self->script_name . "?";
      if(!exists $self->{prefs}{sort_column}) {
        $link .= "sort_column=$i$add_sort_column$form_tack_on_string";
      } elsif($self->{prefs}->{sort_column} =~ /^\-$i\b/) {
        $link .= "sort_column=$i$add_sort_column$form_tack_on_string";
      } elsif($self->{prefs}->{sort_column} =~ /^\b$i\b/) {
        $link .= "sort_column=-$i$add_sort_column$form_tack_on_string";
      } else {
        $link .= "sort_column=$i$add_sort_column$form_tack_on_string";
      }

      push @{$ref->{$self->{prefix} . "_header_text"}}, $self->{results}[0][$i];
      push @{$ref->{$self->{prefix} . "_header_href"}}, $link;
    }

  }

}

sub AUTOLOAD {
  my $self = shift;
  my $return;
  if($AUTOLOAD =~ /.+::(.+)/) {
    my $method = $1;
    $return = $self->{$method} if(exists $self->{$method});
  }
  return $return;
}

sub _filter {
  my $self = shift;

  ### want to change sort_code to an array ref
  if(ref $self->{sort_code} eq 'HASH') {
    my $tmp = [];
    foreach(sort keys %{$self->{sort_code}}) {
      $tmp->[$_] = $self->{sort_code}->{$_};
    }
    $self->{sort_code} = $tmp;
  }

  my $rows = $self->rows; 
  if(( exists $self->{prefs}{sort_column}) && $self->{prefs}{sort_column} =~ /^[0-9,\-]+$/) {
    # the 1 signifies there is a header row
    require Sort::ArrayOfArrays;
    $self->{results} = Sort::ArrayOfArrays::sort_it($self->{results}, $self->{prefs}->{sort_column}, $self->{sort_code}, 1);
  }  
}

sub retrieve_results {
  my $self = shift;

  return $self->{results} if defined($self->{results}) && ref($self->{results}) && $#{ $self->{results} } > -1;

  require CGI;
  my $cookie_name = $self->cookie_name;
  my $cookie_value = CGI::cookie($cookie_name);
  my $filename = $cookie_value || "";
  $filename = $self->base_dir . $filename unless ($filename =~ /^$self->{base_dir}/);
  if( $filename && -f $filename ) {
    $self->{results} = $self->retrieve($filename);
  }elsif( $self->can('generate_results') ) {
    $self->generate_results;
  }else{
    return "";
  }

  return $self->{results};
}

sub rows {
  my $self = shift;

  ### need to subtract 1 since the zeroth row is the header information
  return @{$self->{results}} - 1;
}

sub get_pages {
  my $self = shift;
  my $rows = shift || $self->rows;
  my $pages = int($rows / $self->{prefs}->{at_a_time}) + 1;
  $pages-- unless($rows % $self->{prefs}->{at_a_time});
  return $pages;
}

sub low {
  my $self = shift;
  return $self->{prefs}{start_number};
}

sub high {
  my $self = shift;
  my $rows = shift || $self->rows;
  return ($self->{prefs}->{start_number} + $self->{prefs}->{at_a_time} - 1 > $rows)
      ? $rows : $self->{prefs}->{start_number} + $self->{prefs}->{at_a_time} - 1;
}

sub get_values {
  my $values=shift;
  return () unless defined $values;
  if (ref $values eq "ARRAY") {
    return @$values;
  }
  return ($values);
}

sub get_form_tack_on_string {
  my $self = shift;
  my $form_tack_on_string = '';
  my %hash = (%{$self->form}, %{$self->{prefs}});
  while(my ($key, $value) = each %hash) {
    next if(!$value || $key eq 'sort_column' || $key eq 'start_number');
    foreach(get_values($value)) {
      $form_tack_on_string .= "&" . URLEncode($key) . "=" . URLEncode($_);
    }
  }
  return $form_tack_on_string;
}

sub more_form_tack_on_string {
  my $self = shift;
  my $more_form_tack_on_string = $self->get_form_tack_on_string || "";
  foreach (qw(sort_column) ){
    $more_form_tack_on_string .= "&$_=$self->{prefs}->{$_}" if(exists $self->{prefs}{$_});
  }
  return $more_form_tack_on_string;
}

sub URLEncode {
  my $arg = shift;
  my ($ref,$return) = ref($arg) ? ($arg,0) : (\$arg,1) ;

  if (defined $$ref) {
    $$ref =~ s/([^\w\.\-\ \@\/\:])/sprintf("%%%02X",ord($1))/eg;
    $$ref =~ y/\ /+/;
  }

  return $return ? $$ref : '';
}

sub URLDecode {
  my $arg = shift;
  my ($ref,$return) = ref($arg) ? ($arg,0) : (\$arg,1) ;

  if (defined $$ref) {
    $$ref =~ y/+/ /;
    $$ref =~ s/%([a-f0-9]{2})/chr hex $1/eig;
  }

  return $return ? $$ref : '';
}

sub to_char {
  my $self = shift;
  my ($time, $format, $localtime) = @_;
  return "" unless($time && length $time);
  my @array;
  if($localtime) {
    @array = localtime($time);
  } else {
    @array = gmtime($time);
  }
  my @mm = qw(01 02 03 04 05 06 07 08 09 10 11 12);
  my @mon = qw(jan feb mar apr may jun jul aug sep oct nov dec);
  my @Mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @month = qw(January February March April May June July August September October November December);
  my @wday = qw(SUN MON TUE WED THU FRI SAT);
  my @weekday = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
  my @short_weekday = qw(Sun Mon Tue Wed Thu Fri Sat);
  $format =~ s/\bd\b|\bday\b/$array[3]/ige;
  $format =~ s/dd/sprintf "%02u", $array[3]/ige;
  $format =~ s/mm/$mm[$array[4]]/ige;
  $format =~ s/\bmon\b/$mon[$array[4]]/ge;
  $format =~ s/\bMon\b/$Mon[$array[4]]/ge;
  $format =~ s/\bmonth\b/$month[$array[4]]/ige;
  $format =~ s/yyyy/$array[5]+1900/ige;
  $format =~ s/\byy\b/substr($array[5], 1, 2)/ige;
  $format =~ s/\bhour\b|\bhr\b|\bh\b|\bhh24\b/sprintf "%02u", $array[2]/ige;
  $format =~ s/\b12hour\b|\b12hr\b|\b12h\b/get_12hour($array[2])/ige;
  $format =~ s/\bhour\b|\bhr\b|\bh\b/$array[2]/ige;
  $format =~ s/\bminute\b|\bmin\b|\bm\b/sprintf "%02u", $array[1]/ige;
  $format =~ s/\bsecond\b|\bsec\b|\bs\b|\bss\b/sprintf "%02u", $array[0]/ige;
  $format =~ s/\bwdy\b/$weekday[$array[6]]/ige;
  $format =~ s/\bwd\b/$short_weekday[$array[6]]/ige;
  $format =~ s/\bdy\b/$wday[$array[6]]/ige;
  return $format;
}

1;

__END__

=head1 NAME

Data::ResultsHelper - Perl module to helps sort, paginate and display results sets

=head1 OVERVIEW

  Data::ResultsHelper was written to help display results that can be thought of as an array of arrays.  I
  call the structure results.  Examples abound, and the more I work with it, the more I see examples.  
  Search results, stock ticker quotes, email message summaries, a directory listing, sql query results, 
  this and so much more!

  Data::ResultsHelper takes the results and changes them into a nicely organized hash ref, which can then be
  outputted using Template::Toolkit or the like.

=head1 EXAMPLE

  In the below example, I sub-class the Data::ResultsHelper::HTML.  Data::ResultsHelper is general enough that
  results could be outputted in any number of ways: a csv file, XML, etc.  Please consult the Data::ResultsHelper::HTML
  perldoc for more information.  I simply write a generate_results method which sets $self->{results}.  If 
  $self->{set_cookie} is true, I attempt to cache result sets.  In that case, generate_results would only be 
  called to generate fresh results.
  
  #!/usr/bin/perl -w

  use strict;

  {
    my $self = Helper->new({
      results_dir => '/tmp/stuff',
    });
    print "Content-type: text/html\n\n";
    print $self->results2html;
  }

  package Helper;

  use strict;

  use Data::ResultsHelper::HTML;
  use base qw(Data::ResultsHelper::HTML);

  sub generate_results {
    my $self = shift;
    my $dir = shift || $self->{results_dir};
    my $results = [
      ['File', 'Directory', 'Size', 'Modified time'],
    ];
    require File::Find;
    File::Find::find(sub {
      my $fullpath = $File::Find::name = $File::Find::name;
      my $dir = $File::Find::dir;
      my @stat = stat $fullpath;
      return if($fullpath =~ /^\.\.?$/);
      return if(-d _);
      push @{$results}, [$_, $File::Find::dir, $stat[7], $stat[9]];
    }, $dir);
    $self->{results} = $results;
  }

=head1 COPYRIGHT

  Copyright 2003-2004 Earl Cahill
