#!perl -T

use strict;
use warnings;

use Carp qw/croak/;

BEGIN {
    eval "use DBD::SQLite";
    $@ and croak 'DBD::SQLite is a required dependancy';
}

use ACME::QuoteDB;
use ACME::QuoteDB::LoadDB;

#use Test::More 'no_plan';
use Test::More tests => 29;
use File::Basename qw/dirname/;
use Data::Dumper qw/Dumper/;
use File::Spec;

# A. test dry run, show if parsing is succesful but don't load the database
{
  my $q = File::Spec->catfile((dirname(__FILE__),'data'), 
                               'simpsons_quotes.tsv.csv'
          );

  # only 2 supported formats: 'simple' text (which is the default) and 'tsv' 
  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file        => $q,
                              file_format => 'tsv', # the only supported format
                              delimiter   => "\t",
                              # provide a category for all (if not in data)
                              category    => 'Humor',
                              # provide a attr_source for all (if not in data)
                              attr_source => 'The Simpsons',
                              dry_run     => 1, # don't write to the database
                              #verbose    => 1, # show what is being done
                              create_db   => 1, # need to create the database
                          });
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';

  $load_db->data_to_db;

  #flag not set on dry_run
  is $load_db->success, undef; # success only after a database write, 
  
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
  ok ! $sq->list_attr_names;
}

{
  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file =>
                              #dirname(__FILE__).'/data/simpsons_quotes.tsv.csv',
                              File::Spec->catfile(
                                  (dirname(__FILE__),'data'), 
                                     'simpsons_quotes.tsv.csv'
                              ),
                              file_format => 'tsv',
                              delimiter => "\t",
                              #verbose => 1,
                              create_db   => 1, # first run, create the db
                              # provide a attr_source for all (if not in data)
                              attr_source => 'The Simpsons',
                              # provide a category for all (if not in data)
                              category => 'Humor',
                              # provide a rating for all
                              rating   => 6,
                          });
  
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';

  $load_db->data_to_db;

  ok $load_db->success;
  is $load_db->success, 1;
   
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
  
  # expected attribution list from our data
  my @expected_attribution_list = (
           'Apu Nahasapemapetilon',
           'Chief Wiggum',
           'Comic Book Guy',
           'Grandpa Simpson',
           'Ralph Wiggum',
          );
  
  is( $sq->list_attr_names, join "\n", sort @expected_attribution_list);
}

{
  #my $sqf = dirname(__FILE__) .  '/data/simpsons_quotes.csv';

  my $sqf = File::Spec->catfile((dirname(__FILE__),'data'), 
                               'simpsons_quotes.csv'
          );
  my $load_db = ACME::QuoteDB::LoadDB->new({
                              file        => $sqf,
                              file_format => 'csv',
                              #delimiter  => ",", # comma is default
                              #verbose    => 1,
                              create_db   => 1, # first run, create the db
                          });
  
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
  $load_db->data_to_db;
  ok $load_db->success;
  is $load_db->success, 1;
   
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
  
  # expected attribution list from our data
  my @expected_attribution_list = (
           'Apu Nahasapemapetilon',
           'Chief Wiggum',
           'Comic Book Guy',
           'Grandpa Simpson',
           'Ralph Wiggum',
          );
  
  is( $sq->list_attr_names, join("\n", sort(@expected_attribution_list)));
}

{ # load from html is not supported because there are too many 
  # ways to represt the data.
  # this is an example of extracting quotes from html:
  # subclass ACME::QuoteDB::LoadDB and override dbload,
  # to do our html parsing
  package LoadQuoteDBFromHtml;
  use base 'ACME::QuoteDB::LoadDB';
  use Carp qw/croak/;
  use Data::Dumper qw/Dumper/;
  use HTML::TokeParser;

    sub dbload {
      my ($self, $file) = @_;

      my $p = HTML::TokeParser->new($file) || croak $!;
    
      while (my $token = $p->get_tag("p")) {
          my $idn = $token->[1]{class} || q{};
          my $id = $token->[1]{id} || q{}; # if a quotation is continued (id
          #is not set)
          next unless $idn and ( $idn eq 'quotation' || $idn eq 'source');
          #my $data = $p->get_trimmed_text("/p");
          my $data = $p->get_text('p', 'cite');
          #warn Dumper $data;
          # XXX see $self->set_record in ACME::QuoteDB::LoadDB for fields
          # to populate
          if ($idn eq 'quotation' and $id) {
              $self->set_record(quote => $data);
          }
          elsif ($idn eq 'quotation' and not $id) {
              my $d = $self->get_record('quote') || q{};
              $self->set_record(quote => qq{$d $data});
          }
          elsif ($idn eq 'source'){
              my ($name, $source) = split /,/, $data;
              if ($name) {
                chomp $name;
                $name =~ s/\A\s+//xms;
                $name =~ s/\s+\z//xms;
              }
              $self->set_record(name   => $name);
              $self->set_record(source => $source);

              # TODO
              #$self->set_record({
              #           name   => $name,
              #           source => $source
              #});
          }
    
          if ($self->get_record('quote') and $self->get_record('name')) {
              # we provided a category and rating, otherwise would have to
              # parse from data too
              $self->set_record(catg => $self->{category});
              $self->set_record(rating => $self->{rating});

              # TODO
              #$self->set_record({
              #           catg => $self->{category},
              #           rating => $self->{rating}
              #});

              #$self->debug_record;
              $self->write_record;
          }
      }
    }

  package main;
  use File::Basename qw/dirname/;
  use File::Spec;

  # simple glob pattern accepted
  my $py_quot = File::Spec->catfile(
                         dirname(__FILE__), 'data', 'www.amk.ca', 'quotations',
                                'python-quotes', '*.html'
                );

  my $load_db = LoadQuoteDBFromHtml->new({
                              dir => $py_quot,
                              file_format => 'html',
                              create_db   => 1, # first run, create the db
                              # provide a category for all (if not in data)
                              category => 'Python',
                              # provide a rating for all (if not in data)
                              # and desired
                              rating => 5,
                          });
  
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
  $load_db->data_to_db;
  ok $load_db->success;
  is $load_db->success, 1;
   
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
   
  # expected attribution list from our data (ok, so the data has some
  # 'inconsistancies',...
  #grep "'source'" *.html|sed -e 's/,.*$//g' -e 's/<\/p>//g' -e s'/^.*>//g'| sort -u    
  #seems more accurate: grep "'source'" *.html|sed -e "s/^.*source'>//g" -e 's/,.*$//g' | sort -u
  my @expected_attribution_list = (
            'Aaron Watters',
            'Alex Martelli',
            'Allan Bailey',
            'A.M. Kuchling',
            'Andrew Mullhaupt',
            'Anthony Baxter',
            'An unknown poster and Fredrik Lundh',
            'Brett Cannon',
            'Christian Tismer',
            'Donald E. Knuth',
            'Donn Cave uses sarcasm with devastating effect',
            'Fred Drake on the Documentation SIG',
            'Fredrik Lundh',
            'From Kim "Howard" Johnson\'s',
            'Gareth McCaughan',
            'Gordon McMillan',
            'Guido van Rossum',
            'GvR',
            'Jack Jansen',
            'Jeremy Hylton',
            'Jim Ahlstrom',
            'Jim Fulton and Paul Everitt on the Bobo list',
            'Jim Fulton and Tim Peters',
            'John Eikenberry on the Bobo list',
            'John Holmgren',
            'John J. Lehmann',
            'John Redford',
            'Joseph Strout',
            "Kristj\x{E1}n J\x{F3}nsson",
            'Larry Wall',
            'Mark Jackson',
            'Matthew Lewis Carroll Smith',
            'Michael Palin',
            'Mike Meyer',
            'Nick Seidenman and Guido van Rossum',
            'Paul Boddie',
            'Paul Prescod',
            'Paul Winkler',
            'Sriram Srinivasan',
            'Steve Majewski',
            'Steven D. Majewski',
            'Tim Berners-Lee',
            'Tim Chase',
            'Timothy J. Grant and Tim Peters',
            'Tim Peters',
            'Told by Nick Leaton',
            'Tom Christiansen',
            'Vladimir Marangozov and Tim Peters',
        );
  
  is( $sq->list_attr_names, join "\n", sort @expected_attribution_list);
}

{ # prove load a fortune format file
  # this is an example of importing a file in the 'fortune' format
  # subclass ACME::QuoteDB::LoadDB and override dbload, to do our parsing
  package Fortune2QuoteDB;
  use base 'ACME::QuoteDB::LoadDB';
  use Carp qw/croak/;
  use Data::Dumper qw/Dumper/;

  sub dbload {
    my ($self, $file) = @_;

    open my $source, '<:encoding(utf8)', $file || croak $!;

    local $/ = $self->{delim};

    my $q = q{};

    while (my $line = <$source>){

      #$self->debug_record;

      $q .= $line;
      $q =~ s{\A\s+}{}xsmg;
      $q =~ s{\s+\z}{}xsmg;
      $q =~ s/\s+$self->{delim}//g;

      $self->set_record(quote => $q);

      my $name = $self->get_record('quote');
      $name =~ s{\A(.*?):.*}{$1}xmsg; # not accurate,

      $self->set_record(name   => $name);
      $self->set_record(source => $self->{attr_source});
      $self->set_record(catg   => $self->{category} || q{});
      $self->set_record(rating => $self->{rating} || q{});

      $self->write_record;
      $q = q{};
    }
    close $source || croak $!;
  }

  package main;
  use File::Basename qw/dirname/;
  use File::Spec;

  my $fd = File::Spec->catfile(dirname(__FILE__), 'data', 'futurama');

  my $load_db = Fortune2QuoteDB->new({
                              file        => $fd,
                              file_format => 'custom',
                              delimiter  => "%",
                              #verbose     => 1,
                              create_db   => 1, # first run, create the db
                              # provide a attr_source for all (if not in data)
                              # use fortune filename for 'source'
                              attr_source => 'Futurama',
                              # provide a category for all (if not in data)
                              category    => 'Humor',
                              # provide a rating for all
                              rating      => 6.2,
                          });
  
  isa_ok $load_db, 'ACME::QuoteDB::LoadDB';

  $load_db->data_to_db;

  is $load_db->success, 1;
   
  my $sq = ACME::QuoteDB->new;
  isa_ok $sq, 'ACME::QuoteDB';
  is( $sq->list_attr_sources, 'Futurama');
  is( $sq->list_categories, 'Humor');

  is scalar @{$sq->get_quotes({AttrName => 'Leela'})}, 2;
  is scalar @{$sq->get_quotes({AttrName => 'Professor'})}, 2;
  is scalar @{$sq->get_quotes({AttrName => 'Fry'})}, 4;
  is scalar @{$sq->get_quotes({AttrName => 'Bender'})}, 1;
  is scalar @{$sq->get_quotes({AttrName => 'Zapp'})}, 1;
  # set_quote? update  futurama to be in humor and cartoon
}

