############################################################
#
#   Bib::CrossRef - Uses crossref to robustly parse bibliometric references.
#
############################################################

package Bib::CrossRef;

use 5.8.8;
use strict;
use warnings;
no warnings 'uninitialized';

require Exporter;
use LWP::UserAgent;
use JSON qw/decode_json/;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use HTML::Entities qw(decode_entities encode_entities);
use XML::Simple;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);

#use Data::Dumper;

$VERSION = '0.10';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(
sethtml clearhtml parse_text parse_doi print printheader printfooter
doi score date atitle jtitle volume issue genre spage epage authcount auth query
);
%EXPORT_TAGS = (all => \@EXPORT_OK);

sub new {
    my $self;
    $self->{html} = 0; # use html for error messages ?
    $self->{ref} = {}; # the reference itself
    bless $self;
    return $self;
}

sub sethtml {
  $_[0]->{html} = 1;
}

sub clearhtml {
  $_[0]->{html} = 0;
}

sub _err {
  my ($self, $str) = @_;
  if ($self->{html}) {
    print "<p style='color:red'>",$str,"</p>";
  } else {
    print $str,"\n";
  }
}

sub doi {
  my $self = shift @_;
  return $self->{ref}->{'doi'};
}

sub _setdoi {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'doi'}=$val;
}

sub url {
  my $self = shift @_;
  return $self->{ref}->{'url'};
}

sub _seturl {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'url'}=$val;
}

sub score {
  my $self = shift @_;
  return $self->{ref}->{'score'};
}

sub _setscore {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'score'}=$val;
}

sub atitle {
  my $self = shift @_;
  return $self->{ref}->{'atitle'};
}

sub _setatitle {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'atitle'}=$val;
}

sub jtitle {
  my $self = shift @_;
  return $self->{ref}->{'jtitle'};
}

sub _setjtitle {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'jtitle'}=$val;
}

sub volume {
  my $self = shift @_;
  return $self->{ref}->{'volume'};
}

sub _setvolume {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'volume'}=$val;
}

sub issue {
  my $self = shift @_;
  return $self->{ref}->{'issue'};
}

sub _setissue {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'issue'}=$val;
}

sub date {
  my $self = shift @_;
  return $self->{ref}->{'date'};
}

sub _setdate {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'date'}=$val;
}

sub genre {
  my $self = shift @_;
  return $self->{ref}->{'genre'};
}

sub _setgenre {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'genre'}=$val;
}

sub spage {
  my $self = shift @_;
  return $self->{ref}->{'spage'};
}

sub _setspage {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'spage'}=$val;
}

sub epage {
  my $self = shift @_;
  return $self->{ref}->{'epage'};
}

sub _setepage {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'epage'}=$val;
}

sub authcount {
  my $self = shift @_;
  return $self->{ref}->{'authcount'};
}

sub _setauthcount {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'authcount'}=$val;
}

sub auth {
  my ($self, $num) = @_;
  return $self->{ref}->{'au'.$num};
}

sub _setauth {
  my $self = shift @_;
  my $i = shift @_;
  my $val = shift @_;
  $self->{ref}->{'au'.$i}=$val;
}

sub query {
  my $self = shift @_;
  return $self->{ref}->{'query'};
}

sub _setquery {
  my $self = shift @_;
  my $val = shift @_;
  $self->{ref}->{'query'}=$val;
}

sub parse_text {
  # given free format text, use crossref.org to try to convert into a paper reference and doi
  my ($self, $cites) = @_;
  
  my $cites_clean = $cites;
  # tidy up string, escape nasty characters etc.
  $cites_clean =~ s/\s+/+/g; #$cites_clean = uri_escape_utf8($cites_clean);
  my $req = HTTP::Request->new(GET => 'http://search.crossref.org/dois?q='.$cites_clean);
  my $ua = LWP::UserAgent->new;
  my $res = $ua->request($req);
  if ($res->is_success) {
    # extract json response
    my $json = decode_json($res->decoded_content);
    my $ref={};
    # keep a record of the query string we used
    $ref->{'query'} = $cites;
    # extract doi and matching score
    $ref->{'doi'} = $json->[0]{'doi'};
    $ref->{'url'} = $json->[0]{'doi'};
    $ref->{'score'} = $json->[0]{'score'}; #$json->[0]{'normalizedScore'};
    # and get the rest of the details from the coins encoded payload ...
    if (exists $json->[0]{'coins'}) {
      my $coins = $json->[0]{'coins'};
      my @list = split(';',$coins);
      my $authcount=0;
      foreach my $val (@list) {
        my @pieces = split('=',$val);
        $pieces[0] =~ s/rft\.//;
        if ($pieces[0] =~ m/au$/) {
          $authcount++;
          $pieces[0] = 'au'.$authcount;
        }
        $pieces[1] = uri_unescape($pieces[1]);
        $pieces[1] = decode_entities($pieces[1]); # shouldn't be needed, but some html can creep into titles etc
        $pieces[1] =~ s/\&$//; $pieces[1] =~ s/\s+//g; $pieces[1] =~ s/\+/ /g;
        $pieces[1] =~ s/^\s+//;
        $ref->{$pieces[0]} = $pieces[1];
      }
      $ref->{'authcount'} = $authcount;
      $self->{ref} = $ref;
    }
  } else {
    $self->_err("Problem with search.crossref.org: ".$res->status_line);
  }
}

sub parse_doi {
  # given a DOI, use unixref interface to convert into a full citation
  my ($self, $doi) = @_;
  
  my $req = HTTP::Request->new(GET =>'http://dx.doi.org/'.$doi,['Accept' =>'application/vnd.crossref.unixsd+xml']);
  my $ua = LWP::UserAgent->new;
  my $res = $ua->request($req);
  if ($res->is_success) {
    # now parse the xml
    my $xs = XML::Simple->new();
    my $data = $xs->XMLin($res->decoded_content);
    my $cite =  $data->{'query_result'}->{'body'}->{'query'}->{'doi_record'}->{'crossref'};
    my $cc = undef;
    if (exists($cite->{'conference'})) {
      $self->_setgenre('proceeding');
      if (exists($cite->{'conference'}->{'proceedings_metadata'})) {
        $self->_setjtitle($cite->{'conference'}->{'proceedings_metadata'}->{'proceedings_title'});
        if (exists $cite->{'conference'}->{'proceedings_metadata'}->{'publication_date'}) {$self->_setdate($cite->{'conference'}->{'proceedings_metadata'}->{'publication_date'}->{'year'});}
      } else {
        $self->_setjtitle($cite->{'conference'}->{'proceedings_series_metadata'}->{'series_metadata'}->{'proceedings_title'});
        $self->_setvolume($cite->{'conference'}->{'proceedings_series_metadata'}->{'series_metadata'}->{'volume'});
        if (exists $cite->{'conference'}->{'proceedings_series_metadata'}->{'publication_date'}) {$self->_setdate($cite->{'conference'}->{'proceedings_series_metadata'}->{'publication_date'}->{'year'});}
      }
      $cc = $cite->{'conference'}->{'conference_paper'};
    } elsif (exists($cite->{'journal'})) {
      $self->_setgenre('article');
      $self->_setjtitle($cite->{'journal'}->{'journal_metadata'}->{'full_title'});
      $cc = $cite->{'journal'}->{'journal_issue'};
      if (exists($cc->{'journal_volume'})) {$self->_setvolume($cc->{'journal_volume'}->{'volume'});}
      if (exists($cc->{'issue'})) {$self->_setissue($cc->{'issue'});}
      $cc = $cite->{'journal'}->{'journal_article'};
    } elsif (exists($cite->{'book'})) {
      if ($cite->{'book'}->{'book_type'} ne 'other' ) {
        $self->_setgenre('book');
      } else {
        $self->_setgenre('bookitem');
      }
      my $jtitle = '';
      if (exists($cite->{'book'}->{'book_series_metadata'})) {
        if (exists($cite->{'book'}->{'book_series_metadata'}->{'titles'}->{'title'})) {
          $jtitle .= $cite->{'book'}->{'book_series_metadata'}->{'titles'}->{'title'}.': ';
        }
        $jtitle .= $cite->{'book'}->{'book_series_metadata'}->{'series_metadata'}->{'titles'}->{'title'};
        $self->_setvolume($cite->{'book'}->{'book_series_metadata'}->{'volume'});
        if (exists $cite->{'book'}->{'book_series_metadata'}->{'publication_date'}) {$self->_setdate($cite->{'book'}->{'book_series_metadata'}->{'publication_date'}->{'year'});}
      } elsif (exists($cite->{'book'}->{'book_metadata'})) {
        $jtitle .= $cite->{'book'}->{'book_metadata'}->{'titles'}->{'title'};
        if (exists($cite->{'book'}->{'book_metadata'}->{'series_metadata'}->{'titles'}->{'title'})) {
          $jtitle .= ": ".$cite->{'book'}->{'book_metadata'}->{'series_metadata'}->{'titles'}->{'title'};
          if (exists $cite->{'book'}->{'book_metadata'}->{'series_metadata'}->{'volume'}) {$self->_setvolume($cite->{'book'}->{'book_metadata'}->{'series_metadata'}->{'volume'});}
        }
        if (exists $cite->{'book'}->{'book_metadata'}->{'volume'}) {$self->_setvolume($cite->{'book'}->{'book_metadata'}->{'volume'});}
        if (exists $cite->{'book'}->{'book_metadata'}->{'publication_date'}) {$self->_setdate($cite->{'book'}->{'book_metadata'}->{'publication_date'}->{'year'});}
      } else {
        if (exists($cite->{'book'}->{'book_set_metadata'}->{'titles'}->{'title'})) {
          $jtitle .= $cite->{'book'}->{'book_set_metadata'}->{'titles'}->{'title'}.': ';
        }
        $jtitle .= $cite->{'book'}->{'book_set_metadata'}->{'set_metadata'}->{'titles'}->{'title'};
      }
      $self->_setjtitle($jtitle);
      $cc = $cite->{'book'}->{'content_item'};
    } else {
        # something else -- might be dissertation, report-paper, standard, sa-component, database
        # fall back to alternative interface for now
        $self->parse_text($doi);
        return; # stop here
    }
    $self->_setscore(1);
    $self->_setquery($doi);
    $self->_setdoi($doi);
    if (!defined $cc) {
      # seems like an incomplete entry
      return;
    }
    #$self->_setatitle($cc->{'titles'}->{'title'});
    my $title;
    if  (ref $cc->{titles} ne "HASH") {
      $title =  $cc->{titles}->[0];
    } else {
      $title = $cc->{'titles'}->{'title'};
    }
    $self->_setatitle($title);
    $self->_setdoi($cc->{'doi_data'}->{'doi'});
    if (ref($cc->{'publication_date'}) eq "HASH") {
      $self->_setdate($cc->{'publication_date'}->{'year'});
    } else { # we have multiple dates, lets try and pick put the print date
      my $found = 0; my $count=0;
      foreach my $d (@{$cc->{'publication_date'}}) {
        if ($d->{'media_type'} eq 'print') {
          $self->_setdate($d->{'year'}); $found = 1;
        }
        $count++;
      }
      if ((!$found) && ($count>0)) {$self->_setdate(${$cc->{'publication_date'}}[0]->{'year'});}
    }
    if (exists(${$cc}{'pages'})) {
      if (exists(${$cc->{'pages'}}{'first_page'})) {$self->_setspage($cc->{'pages'}->{'first_page'});}
      if (exists(${$cc->{'pages'}}{'last_page'})) {$self->_setepage($cc->{'pages'}->{'last_page'});}
    }
    $cc = $cc->{'contributors'}->{'person_name'};
    if (ref($cc) eq "HASH") {
      $self->_setauthcount(1);
      $self->_setauth(1,$cc->{'given_name'}.' '.$cc->{'surname'});
    } else {
      my $count = 0;
      foreach my $au (@{$cc}) {
        if ($au->{'contributor_role'} ne 'author') {next;}
        $count++;
        $self->_setauth($count, $au->{'given_name'}.' '.$au->{'surname'});
      }
      $self->_setauthcount($count);
    }
  } else {
    $self->_err("Problem with search.crossref.org/guestquery: ".$res->status_line);
  }
}

sub printheader {
  my $self = shift @_;
  my $id = shift @_;
  my $str = '';
  if (defined $id) {$str = 'id="'.$id.'"';}
  return  '<table '.$str.'><tr style="font-weight:bold"><td></td><td>Use</td><td></td><td>Type</td><td>Year</td><td>Authors</td><td>Title</td><td>Journal</td><td>Volume</td><td>Issue</td><td>Pages</td><td>DOI</td><td>url</td><td></td></tr>'."\n";
}

sub printfooter {
  return "</table>\n";
}

sub _authstring {
  my $self = shift @_;
  my $out='';
  if ($self->authcount > 0) {
    $out = $self->auth(1);
    for (my $j = 2; $j <= $self->authcount; $j++) {
      $out.=' and '.$self->auth($j);
    }
  }
  return $out;
}

sub print {
  # return a reference in human readable form
  my ($self, $id, $add) = @_;
  my $ref = $self->{ref};
  if (!defined $id) {$id='';}
  if (!defined $add) {$add='';}
  
  my $out='';
  if ($self->{html}) {
    $out.=sprintf "%s", '<tr id="cite">';
    $out.=sprintf "%s",  '<td>'.$id.'</td>';
    if ($self->score<1) {
      $out.=sprintf "%s",  '<td><input type="checkbox" name="'.$id.'" value=""></td>';
      $out.=sprintf "%s",  '<td style="color:red">Poor match</td>';
    } else {
      $out.=sprintf "%s",  '<td><input type="checkbox" name="'.$id.'" value="" checked></td><td></td>';
    }
    $out.=sprintf "%s",  '<td contenteditable="true">'.$self->genre.'</td><td contenteditable="true">'.$self->date.'</td>';
    $out.=sprintf "%s",  '<td contenteditable="true">'.$self->_authstring.'</td>';
    $out.=sprintf "%s",  '<td contenteditable="true">'.$self->atitle.'</td><td contenteditable="true">'.encode_entities($self->jtitle).'</td>';
    $out.=sprintf "%s",  '<td contenteditable="true">';
    if (defined $self->volume) {
      $out.=sprintf "%s",  $self->volume;
    }
    $out.=sprintf "%s",  '</td><td contenteditable="true">';
    if (defined $self->issue) {
      $out.=sprintf "%s",  $self->issue;
    }
    $out.=sprintf "%s",  '</td><td contenteditable="true">';
    if (defined $self->spage) {
      $out.=sprintf "%s",  $self->spage;
    }
    if (defined $self->epage) {
      $out.=sprintf "%s",  '-'.$self->epage;
    }
    $out.=sprintf "%s",  '</td><td contenteditable="true">';
    if (defined $self->doi) {
      my $doi = $self->doi;
      $doi =~ s/http:\/\/dx.doi.org\///;
      $out.=$doi;
    }
    $out.=sprintf "%s",  '</td><td contenteditable="true">';
    if (defined $self->url) {
      $out.=sprintf "%s",  '<a href='.$self->url.'>'.$self->url.'</a>';
    }
    $out.= '</td><td>'.$add;
    $out.=sprintf "%s",  '</td></tr>'."\n";
    $out.=sprintf "%s",  '<tr><td colspan=12 style="color:#C0C0C0">'.encode_entities($self->query).'</td></tr>'."\n";
  } else {
    if (length($id)>0) {$out .= $id.". ";}
    if ($self->score<1) {
      $out.=sprintf "%s",  'Poor match (score='.$self->score."):\n";
      $out.=sprintf "%s", $self->query."\n";
    } else {
      #print "$count. ";
    }
    $out.=sprintf "%s",  $self->genre.': '.$self->date.", ".$self->_authstring.", ";
    $out.=sprintf "%s",  "\'".$self->atitle."\'. ".$self->jtitle;
    if (defined $self->volume) {
      $out.=sprintf "%s",  ", ".$self->volume;
      if (defined $self->issue) {
        $out.=sprintf "%s",  "(".$self->issue.")";
      }
    }
    if (defined $self->spage) {
      $out.=sprintf "%s",  ",pp".$self->spage;
    }
    if (defined $self->epage) {
      $out.=sprintf "%s",  '-'.$self->epage;
    }
    if (defined $self->doi) {
      my $doi = $self->doi;
      $doi =~ s/http:\/\/dx.doi.org\///;
      $out.=sprintf "%s",  ", DOI: ".$doi;
    }
    if (defined $self->url) {
      $out.=sprintf "%s",  ", ".$self->url;
    }
  }
  return $out;
}

1;

=pod
 
=head1 NAME
 
Bib::CrossRef - Uses crossref to robustly parse bibliometric references.
 
=head1 SYNOPSIS

 use strict;
 use Bib::CrossRef;

# Create a new object

 my $ref = Bib::CrossRef->new();

# Supply some details, Bib::CrossRef will do its best to use this to derive full citation details e.g. the DOI of a document ...

 $ref->parse_text('10.1109/jstsp.2013.2251604');
 
# Show the full citation details, in human readable form

 print $ref->print();

 article: 2013, Alessandro Checco and Douglas J. Leith, 'Learning-Based Constraint Satisfaction With Sensing Restrictions'. IEEE Journal of Selected Topics in Signal Processing, 7(5),pp811-820, DOI: http://dx.doi.org/10.1109/jstsp.2013.2251604

# Show the full citation details, in html format

 $ref->sethtml;
 print $ref->printheader;
 print $ref->print;
 print $ref->printfooter;


=head1 EXAMPLES

A valid DOI will always be resolved to a full citation
e.g.

 $ref->sparse_text('10.1109/jstsp.2013.2251604');
 print $ref->print();
 
 article: 2013, Alessandro Checco and Douglas J. Leith, 'Learning-Based Constraint Satisfaction With Sensing Restrictions'. IEEE Journal of Selected Topics in Signal Processing, 7(5),pp811-820, DOI: http://dx.doi.org/10.1109/jstsp.2013.2251604

An attempt will be made to resolve almost any text containing citation info 
e.g. article title only

 $ref->parse_text('Learning-Based Constraint Satisfaction With Sensing Restrictions');

e.g. author and journal

 $ref->parse_text('Alessandro Checco, Douglas J. Leith, IEEE Journal of Selected Topics in Signal Processing, 7(5)');

Please bear in mind that crossref provides a great service for free -- don't abuse it by making excessive queries.  If making many queries, be
sure to rate limit them to a sensible level or you will likely get blocked.

=head1 METHODS
 
=head2 new

 my $ref = Bib::CrossRef->new();

Creates a new Bib::CrossRef object

=head2 parse_text

 $ref->parse_text($string)

Given a text string, Bib::CrossRef will try to resolve into a full citation with the help of crossref.org

=head2 parse_doi

 $ref->parse_doi($doi)

Given a string containing a DOI e.g. 10.1109/tnet.2012.2202686, resolve into a full citation with the unixref
interface of crossref.org.  This should be definitive publishers DOI and is usually
much as the same as calling $ref->parse_text($doi), but is included completeness.

=head2 doi

 my $info = $ref->doi

Returns a string containg the DOI (digital object identifier) field from a full citation.  If present, this 
should be unique to the document.

=head2 score

 my $info = $ref->score

Returns a matching score from crossref.org.  If less than 1, the text provided to set_details() was likely
insufficient to allow the correct full citation to be obtained.

=head2 genre

 my $info = $ref->genre

Returns the type of publication e.g. jounal paper, conference paper etc

=head2 date

 my $info = $ref->date

Returns the year of publication

=head2 atitle

 my $info = $ref->atitle

Returns the article title

=head2 jtitle

 my $info = $ref->jtitle

Returns the name of the journal (in long form)

=head2 authcount

 my $info = $ref->authcount

Returns the number of authors

=head2 auth

 my $info = $ref->auth($num)

Get the name of author number $num (first author is $ref->auth(1))

=head2 volume

 my $info = $ref->volume

Returns the volume number in which paper appeared

=head2 issue

 my $info = $ref->issue

Returns the issue number in which paper appeared

=head2 spage

 my $info = $ref->spage

Returns the start page

=head2 epage

 my $info = $ref->epage

Returns the end page

=head2 url

Return the url, if any

=head2 query

 my $info = $ref->query
 
Returns the free form string from which full citation is derived

=head2 print

 print $ref->printheader;

Prints full citation in human readable form.

=head2 sethtml

 $ref->sethtml

Set output format to be html

=head2 clearhtml

 $ref->clearhtml

Set output format to be plain text

=head2 printheader

 print $ref->printheader;

When html formatting is enabled, prints some html header tags

=head2 printfooter

 print $ref->printfooter;

When html formatting is enabled, prints some html footer tags

=head1 EXPORTS
 
You can export the following functions if you do not want to use the object orientated interface:

parse_text parse_doi sethtml clearhtml set_details print printheader printfooter
doi score date atitle jtitle volume issue genre spage epage authcount auth query url

The tag C<all> is available to easily export everything:
 
use Bib::CrossRef qw(:all);

=head1 VERSION
 
Ver 0.09
 
=head1 AUTHOR
 
Doug Leith 
    
=head1 BUGS
 
Please report any bugs or feature requests to C<bug-rrd-db at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bib-CrossRef>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.
 
=head1 COPYRIGHT
 
Copyright 2015 D.J.Leith.
 
This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.
 
=cut


__END__
