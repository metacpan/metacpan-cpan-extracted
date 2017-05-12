use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    use DBIStagTest;
    plan tests => 2;
}
use DBIx::DBIStag;
use DBI;
use FileHandle;
use strict;

use Getopt::Long;
use Data::Stag;

my ($fmt, $outfmt, $type);
$type = 'seq';
$outfmt = 'chadosxpr';
GetOptions("fmt|i=s"=>\$fmt,
           "outfmt|o=s"=>\$outfmt,
           "type|t=s"=>\$type);

my $db = shift @ARGV;
my $dbh = DBIx::DBIStag->connect($db);
##my $dbh = DBIx::DBIStag->new;

$dbh->mapping([
               Data::Stag->from('sxprstr',
                                '(map (table "cvterm_dbxref") (col "dbxrefstr") (fkcol "dbxrefstr") (fktable "dbxref"))'),

               Data::Stag->from('sxprstr',
                                '(map (table "cvterm") (col "termtype_id") (fktable_alias "termtype") (fkcol "cvterm_id") (fktable "cvterm"))'),

               Data::Stag->from('sxprstr',
                                '(map (table "cvrelationship") (col "subjterm_id") (fktable_alias "subjterm") (fkcol "cvterm_id") (fktable "cvterm"))'),

               Data::Stag->from('sxprstr',
                                '(map (table "cvrelationship") (col "objterm_id") (fktable_alias "objterm") (fkcol "cvterm_id") (fktable "cvterm"))'),

               Data::Stag->from('sxprstr',
                                '(map (table "cvrelationship") (col "reltype_id") (fktable_alias "reltype") (fkcol "cvterm_id") (fktable "cvterm"))'),


              ]);

my %h =
  (
   cvrelationship => sub {
       my ($self, $stag) = @_;
       return unless $self->{pass} == 2;
       foreach (qw(subjterm objterm)) {
           my $v = $stag->get($_);
           $stag->set($_,
                      [Data::Stag->new(cvterm=>[ [dbxrefstr=>$v] ])]);
       }
       my $v = $stag->get('reltype');
       $stag->set('reltype',
                  [Data::Stag->new(cvterm=>[ 
                                            [termname=>$v],
                                           ]
                                  )
                  ]
                 );
       print $stag->xml;
       my $dbh = $self->{dbh};
       $dbh->storenode($stag);
       return;
   },
   cvterm => sub {
       my ($self, $stag) = @_;
       return unless $self->{pass} == 1;
       print $stag->xml;
       my $dbh = $self->{dbh};
       $dbh->storenode($stag);
       return;
   },
   cvterm_dbxref => sub {
       my ($self, $stag) = @_;
       my $dbxref = $stag->duplicate;
       $dbxref->element('dbxref');
       $dbxref->set_dbxrefstr($dbxref->get_dbname . ':' .
                              $dbxref->get_accession);
       $stag->data([$dbxref]);
       0;
   },
   dbxref => sub {
       my ($self, $stag) = @_;
       $stag->element('dbxrefstr');
   },
   termdefintion => sub {
       my ($self, $stag) = @_;
       $stag->element('termdefinition');
   },
  );

my $handler = Data::Stag->makehandler(%h);
$handler->{dbh} = $dbh;

foreach my $f (@ARGV) {
    $handler->{pass} = 1;
    my $stag = Data::Stag->new->parse(-file=>$f, -handler=>$handler);
    $handler->{pass} = 2;
    my $stag = Data::Stag->new->parse(-file=>$f, -handler=>$handler);
}

exit 0;
package LoadChado;
use strict;
use base qw(Data::Stag::BaseHandler);

sub dbh {
    my $self = shift;
    $self->{_dbh} = shift if @_;
    return $self->{_dbh};
}

sub e_cvrelationship {
    my $self = shift;
    my $stag = shift;

    printf "CATCH END:%s\n", $self->depth;
    
    my $dbh = $self->dbh;

    foreach (qw(subjterm objterm)) {
        my $v = $stag->get($_);
        $stag->set($_,
                   [Data::Stag->new(cvterm=>[ [dbxrefstr=>$v] ])]);
    }
    my $v = $stag->get('reltype');
    $stag->set('reltype',
               [Data::Stag->new(cvterm=>[ 
                                         [termname=>$v],
                                         [termtype=>'relationship']
                                        ]
                               )
               ]
              );
    print $stag->sxpr;
    $dbh->storenode($stag);
    return;
}

sub e_cvterm {
    my $self = shift;
    my $stag = shift;

    
}

sub zcatch_end {
    my $self = shift;
    my $ev = shift;
    my $stag = shift;

    return unless $self->depth == 1;

    printf "CATCH END:$ev:%s\n", $self->depth;

    my $dbh = $self->dbh;

    if ($stag->element eq 'cvrelationship') {
        foreach (qw(subjterm objterm)) {
            my $v = $stag->get($_);
            $stag->set($_,
                       [Data::Stag->new(cvterm=>[ [dbxrefstr=>$v] ])]);
        }
        my $v = $stag->get('reltype');
        $stag->set('reltype',
                   [Data::Stag->new(cvterm=>[ 
                                             [termname=>$v],
                                             [termtype=>'relationship']
                                            ]
                                   )
                   ]
                  );
    }

    $stag->iterate(sub {
                       my $n = shift;
                       if ($n->element eq 'dbxref') {
                           $n->element('dbxrefstr');
                       }
                       if ($n->element eq 'termtype') {
                           my $v = $n->data;
                           $n->data([Data::Stag->new(cvterm=>[
                                                              [termname=>$v],
                                                              [termtype=>'type']
                                                             ])]);
                       }
                       0;
                   });
#        $dbh->store($stag);

    print $stag->sxpr;
    print "\n";

    return;
}

1;
