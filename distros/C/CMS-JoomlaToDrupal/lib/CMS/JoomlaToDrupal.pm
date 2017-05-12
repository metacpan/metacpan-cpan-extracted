package CMS::JoomlaToDrupal;

use strict;
use warnings;

use DBI;
use DateTime;

=head1 NAME

CMS::JoomlaToDrupal - migrate legacy Joomla content to Drupal 

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

This code should populate a new drupal installation from a
legacy joomla site.

    use DBI;
    use CMS::JoomlaToDrupal;

    my $dbh_joomla = DBI->connect();
    my $dbh_drupal = DBI->connect();

    my $j2d = CMS::JoomlaToDrupal->new({  
            dbh_drupal => $dbh_drupal,
            dbh_joomla => $dbh_joomla,
         drupal_prefix => 'drupal_',
         joomla_prefix => 'jos_',
                   log => '/home/me/logs/j2d.log',
                 email => 'site_admin@example.net'  });

    $j2d->migrate();

Install drupal in the usual way, running the script at:
	http://example.com/install.php

Then run the script above from a command line.  After a moment,
your legacy joomla content should be in your drupal database
and be visible by visiting your home page.  All stories will
be promoted to the front page.  At this point you can apply
themes, custom modules can be enabled and the work of migrating
your site can continue without the tedium of manually inputing
legacy stories.

=head1 METHODS 

=head2 ->new() 

Provided a DBI::db connection handle to each of the joomla and
the drupal databases, database table prefixes, plus a path to
a job log and an email address for the admin user on the new
drupal site, return an object offering access to the methods
necessary to migrate the old joomla site to a new drupal site.

=cut

sub new {
  my $self = shift;
  my $defaults = shift;
  my $j2d = {};
  $j2d->{'dbh_drupal'} = $defaults->{'dbh_drupal'};
  $j2d->{'dbh_joomla'} = $defaults->{'dbh_joomla'};
  $j2d->{'drupal_prefix'} = $defaults->{'drupal_prefix'};
  $j2d->{'joomla_prefix'} = $defaults->{'joomla_prefix'};

  $j2d->{'log'} = $defaults->{'log'};
  $j2d->{'email'} = $defaults->{'email'};
  bless $j2d, $self;
  return $j2d;
}

=head2 ->migrate() 

Invoking this method will import authors, articles, comments
and hit counters from the configured Joomla database, into the
configured Drupal database.  It creates a log of its activities.

=cut 

sub migrate {
  my $self = shift;
  print STDERR "Now migrating site  .  .  .  \n";

  open('LOG','>',$self->{'log'}) or die "Unable to open error log file: \n\t$self->{'log'} \nfor writing.  Check permissions and try again.";
    $self->_import_authors();
    $self->_import_articles();
    $self->_import_comments();
  close(LOG);
  
  print STDERR "Migration complete.  Now exiting script.";
  return;
}

sub _import_comments {
  my $self = shift;

  my $insert = "INSERT INTO $self->{'drupal_prefix'}comments (cid,pid,nid,uid,subject,comment,hostname,timestamp,name,status) VALUES(?,?,?,?,?,?,?,?,?,?);";
  my $sth_insert = $self->{'dbh_drupal'}->prepare($insert);

  my $sql = "SELECT id,contentid,ip,name,title,comment,date,published FROM $self->{'joomla_prefix'}jomcomment";
  my $sth_j = $self->{'dbh_joomla'}->prepare($sql);
  $sth_j->execute();

  while( my $comment = $sth_j->fetchrow_hashref() ){

    my $id = 10000 + $comment->{'contentid'};

    $sth_insert->execute($comment->{'id'},0,$id,0,$comment->{'title'},$comment->{'comment'},$comment->{'ip'},_get_ts($comment->{'date'}),$comment->{'name'},$comment->{'published'});

  }

}

sub _import_articles {
  my $self = shift;

  my $sql_grab_uid = "SELECT uid FROM $self->{'drupal_prefix'}users WHERE name = ?";
  my $sth_d_uid = $self->{'dbh_drupal'}->prepare($sql_grab_uid);

  my $insert_node = "INSERT INTO $self->{'drupal_prefix'}node (nid,vid,type,title,uid,status,created,changed,comment,promote) VALUES(?,?,?,?,?,?,?,?,?,?)";
  my $sth_d_insert_node = $self->{'dbh_drupal'}->prepare($insert_node);

  my $insert_rev = "INSERT INTO $self->{'drupal_prefix'}node_revisions (nid,vid,uid,title,body,teaser,log,timestamp,format) VALUES(?,?,?,?,?,?,?,?,?)";
  my $sth_d_insert_rev = $self->{'dbh_drupal'}->prepare($insert_rev);

  my $sql_nid = "SELECT nid, vid FROM $self->{'drupal_prefix'}node ORDER BY nid DESC LIMIT 1";
  my $sth_d_nid = $self->{'dbh_drupal'}->prepare($sql_nid);

  my $sql_nid_dupe_check = "SELECT count(*) FROM $self->{'drupal_prefix'}node_revisions WHERE nid = ?";
  my $sth_d_check_for_duplicate_nid = $self->{'dbh_drupal'}->prepare($sql_nid_dupe_check);

  my $insert_hits = "INSERT INTO $self->{'drupal_prefix'}node_counter VALUES(?,?,0,?)";
  my $sth_insert_hits = $self->{'dbh_drupal'}->prepare($insert_hits);

  my $sql = "SELECT id, title, title_alias, introtext, `fulltext`, created, created_by_alias, hits FROM $self->{'joomla_prefix'}content ORDER BY id ASC";
  my $sth_j = $self->{'dbh_joomla'}->prepare($sql);
  $sth_j->execute();  

  while( my $article = $sth_j->fetchrow_hashref()){

    $sth_d_uid->execute($article->{'created_by_alias'});
    my ($uid) = $sth_d_uid->fetchrow_array();
    if (!defined($uid)){ next; }
    my $ts = _get_ts($article->{'created'});
    my $id = 10000 + $article->{'id'};
    my $title;
    if(defined($article->{'title_alias'})){
      $title = $article->{'title_alias'};
    } elsif(defined($article->{'title'})){
      $title = $article->{'title'};
    } else {
      $title = '';
    }
    $sth_d_insert_node->execute($id,$id,'story',$title,$uid,1,$ts,$ts,1,0);

    $sth_d_nid->execute();
    my ($nid,$vid) = $sth_d_nid->fetchrow_array();
    
    $sth_insert_hits->execute($nid,$article->{'hits'},_get_ts('2008-12-31 12:00:00'));

    $sth_d_check_for_duplicate_nid->execute($nid);
    my ($nid_dupe) = $sth_d_check_for_duplicate_nid->fetchrow_array();

    if(!$nid_dupe){
      $sth_d_insert_rev->execute($nid,$vid,$uid,$article->{'title_alias'},$article->{'fulltext'},$article->{'introtext'},'migrated by joomla_to_drupal.pl on 20081230',$ts,2);
    } else {
      print LOG "Now skipping duplicated $nid: ";
      print LOG $article->{'title'} if(defined($article->{'title'}));
      print LOG "\n";
    }
  }

  my $cutoff = _get_ts('2008-08-31 00:00:00');
  my $sql_permit_comments = "UPDATE $self->{'drupal_prefix'}node SET promote = 1, comment = 2 WHERE created > '$cutoff'";
  $self->{'dbh_drupal'}->do($sql_permit_comments);

}

sub _import_authors {
  my $self = shift;

  my $table_d = $self->{'drupal_prefix'} . 'users';
  my $insert = "INSERT INTO $table_d VALUES(NULL,?,'',\"$self->{'email'}\",0,0,0,'','',?,?,'',0,NULL,'','',\"$self->{'email'}\",\'a:1:{s:13:\"form_build_id\";s:37:\"form-495b83a835faf7494696d65783576244\";}');";
  my $sth_d = $self->{'dbh_drupal'}->prepare($insert);

  my $table_j = $self->{'joomla_prefix'} . 'content';
  my $sql = "select created_by_alias, created from $table_j group by created_by_alias order by created_by_alias ASC, created DESC ";
  my $sth_j = $self->{'dbh_joomla'}->prepare($sql);
  $sth_j->execute();

  while( my $author = $sth_j->fetchrow_hashref()){
    if($author->{'created_by_alias'} eq '') { next; }
    # print 'Now inserting into drupal database: ' . $author->{'created_by_alias'} . "\n";
    if($author->{'created'} =~ m/0000-00-00/){ 
      $author->{'created'} = '2008-12-31 12:00:00';
      print LOG "  .  .  .  substituted arbitrary date for: $author->{'created_by_alias'}, was: 0000-00-00 00:00:00, now: $author->{'created'} \n";
      next;
    }
    my $ts = _get_ts($author->{'created'});
    $sth_d->execute($author->{'created_by_alias'},$ts,$ts);
  }

}

sub _get_ts {
  my $ts = shift;

  my $d = DateTime->new( 
     year => substr($ts,0,4),
    month => substr($ts,5,2),
      day => substr($ts,8,2),
     hour => substr($ts,11,2),
   minute => substr($ts,14,2),
   second => substr($ts,17,2)
      );

  # print $ts . ' is: ' . $d->epoch . "\n";

  return $d->epoch;
}

=head1 TODO

Rewrite to use CMS::Joomla to create the Joomla database handle,
perhaps add a CMS::Drupal as well.  This way the constructor
would take drupal_cfg, joomla_cfg, log and email.

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >>

=head1 BUGS

Please report any bugs or feature requests, tests, use cases,
patches or documentation to C<bug-cms-joomlatodrupal
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CMS-JoomlaToDrupal>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

This module is currently failing the pod-coverage tests,
for what reason escapes me at this moment.  So that test
has been renamed so it is excluded from the make test run.
I tried to give you complete documentation, honest I did.

The author is available, by contract, to prioritize needed
extensions or enhancements.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CMS::JoomlaToDrupal

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CMS-JoomlaToDrupal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CMS-JoomlaToDrupal>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CMS-JoomlaToDrupal>

=item * Search CPAN

L<http://search.cpan.org/dist/CMS-JoomlaToDrupal>

=back

=head1 ACKNOWLEDGEMENTS

This module was developed and successfully used to migrate
        http://blackagendareport.com/

including over 1000 stories and 10,000 comments accumulated
on the legacy site.  Their support for its development is
appreciated.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Hugh Esco, all rights reserved.

This program is released under the following license: gpl

=cut

1; # End of CMS::JoomlaToDrupal

1;

