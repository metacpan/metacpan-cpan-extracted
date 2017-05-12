#!perl -T

# TODO more tests, make add_quote break!
# TODO see bottom of file for more todo's

use strict;
use warnings;

use ACME::QuoteDB;
use ACME::QuoteDB::LoadDB;

#use Test::More 'no_plan';
use Test::More tests => 24;
use File::Basename qw/dirname/;
use Data::Dumper qw/Dumper/;
use Carp qw/croak/;
use File::Spec;
use Readonly;

BEGIN {
    eval "use DBD::SQLite";
    $@ and croak 'DBD::SQLite is a required dependancy';
}


Readonly my $FG_QUOTE => 'Lois: Peter, what did you promise me?' .
"\nPeter: That I wouldn't drink at the stag party." .
"\nLois: And what did you do?" .
"\nPeter: Drank at the stag pa-- ... Whoa. I almost walked into that one.";
  

{
    #make test db writeable
    use ACME::QuoteDB::DB::DBI;
    # yeah, this is supposed to be covered by the build process
    # but is failing sometimes,...
    chmod 0666, ACME::QuoteDB::DB::DBI->get_current_db_path;

    my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
        'simpsons_quotes.csv'
    );
    my $load_db = ACME::QuoteDB::LoadDB->new({
                                file        => $q,
                                file_format => 'csv',
                                create_db   => 1,
                            });

    isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
    $load_db->data_to_db;
    is $load_db->success, 1;
}

my $sq = ACME::QuoteDB->new;

is $sq->get_quote({Rating => '8.7'}),
    "Me fail English? That's unpossible.\n-- Ralph Wiggum";

is( $sq->list_attr_sources, 'The Simpsons');
is( $sq->list_categories, 'Humor');


{
  eval { # quote is mandatory
     $sq->add_quote({
         Quote     => q{},
         AttrName  => 'Peter Griffin',
         Source    => 'Family Guy',
         Rating    => '8.6',
         Category  => 'TV Humor',
     });
  };
  if ($@) {
      if ($@ =~ m/ are mandatory parameters/){ 
         pass 'correct, exception expected'
      }
      else {fail 'unexpected exception occured'};
  } 
  else {fail 'quote and name are required'};
}


# quote does not yet exist in db
{ 
  eval { # see, not exist yet
      $sq->get_quote({AttrName => 'Griffin'});
  };
  if ($@) {
     pass 'ok' if $@ =~ m/attribution not found/;
  } else {
     fail 'attribution does not yet exist, so should not be found'
  };
}

{ # now, add new quote to the db

  $sq->add_quote({
      Quote     => $FG_QUOTE,
      AttrName  => 'Peter Griffin',
      Source    => 'Family Guy',
      Rating    => '8.6',
      Category  => 'TV Humor',
  });

  # exist now
  ok scalar $sq->get_quote({AttrName => 'GRIFFIN'}); # case insensitve
  my $fgc = $FG_QUOTE;
  $fgc .= "\n-- Peter Griffin";
  is $fgc, $sq->get_quote({AttrName => 'Peter G'});

  # get newly updated source and category
  is( $sq->list_attr_sources, "Family Guy\nThe Simpsons" );
  is( $sq->list_categories, "Humor\nTV Humor");
}

{
  # crud
  # get_quote id, update quote content, delete quote

  my $qid = $sq->get_quote_id({Quote => $FG_QUOTE});

  my $qu = $FG_QUOTE;
  $qu =~ s/Lois/Marge/xmsg;
  $qu =~ s/Peter/Homer/xmsg;
 
  is $sq->get_quote({Rating => '9.6'}), undef;

  $sq->update_quote({
      QuoteId   => $qid,
      Quote     => $qu,
      AttrName  => 'Lois Simpson',
      Source    => 'The Simpsons Guys',
      Rating    => '9.6',
      Category  => 'Cartoon Noir',
  });

  $qu .= "\n-- Lois Simpson";
  eval { # see, updated, should now be 'Lois Simpson'
     $sq->get_quote({AttrName => 'Peter G'});
  };
  if ($@) {
      pass 'ok' if $@ =~ m/attribution not found/;
  } else {fail 'attribution does not yet exist, so should not be found'};

  is $sq->get_quote({AttrName => 'Lois Simpson'}), $qu;
  is $sq->get_quote({AttrName => 'Lois S'}), $qu;
  is $sq->get_quote({Rating => '9.6'}), $qu;

  is $sq->get_quote({Source => 'The Simpsons Guys'}), $qu;
  is $sq->get_quote({Category => 'Cartoon Noir'}), $qu;

  $sq->delete_quote({QuoteId => $qid});
  # see, bye, bye
  is $sq->get_quote({AttrName => 'Lois S'}), undef;
  is $sq->get_quote({Rating => '9.6'}), undef;

}

# TODO
{ # add new quote to the db

  $sq->add_quote({
      Quote     => $FG_QUOTE,
      AttrName  => 'Peter Griffin',
      Source    => 'Family Guy',
      Rating    => '8.6',
      Category => [qw(Humor TV PG13 Crude Cartoon ROTFLMAO)]
  });

  my $qid = $sq->get_quote_id({Quote => $FG_QUOTE});

  # one quote can belong to many categories
  my $q = $FG_QUOTE;
  $q .= "\n-- Peter Griffin";
  is $sq->get_quote({
           Source => 'Family Guy',
           Category => [qw(Humor TV PG13 Crude Cartoon ROTFLMAO)]
  }), $q;

  # get all quotes from these categories
  is $sq->get_quote({
           Category => [qw(Crude Cartoon ROTFLMAO)]
  }), $q;

  is scalar @{$sq->get_quotes({
           Category => [qw(Humor ROTFLMAO)]
  })}, 30;

  ok $sq->delete_quote({QuoteId => $qid}); 
}
