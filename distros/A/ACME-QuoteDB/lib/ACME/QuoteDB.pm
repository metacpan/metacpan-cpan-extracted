#$Id: QuoteDB.pm,v 1.36 2009/09/30 07:37:09 dinosau2 Exp $
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

package ACME::QuoteDB;

use 5.008005;        # require perl 5.8.5, re: DBD::SQLite Unicode
use warnings;
use strict;

#major-version.minor-revision.bugfix
use version; our $VERSION = qv('0.1.2');

#use criticism 'brutal'; # use critic with a ~/.perlcriticrc

use Exporter 'import';
our @EXPORT = qw/quote/; # support one liner

use Carp qw/croak/;
use Data::Dumper qw/Dumper/;
use ACME::QuoteDB::LoadDB;
use aliased 'ACME::QuoteDB::DB::Attribution' => 'Attr';
use aliased 'ACME::QuoteDB::DB::QuoteCatg'  => 'QuoteCatg';
use aliased 'ACME::QuoteDB::DB::Category'  => 'Catg';
use aliased 'ACME::QuoteDB::DB::Quote'    => 'Quote';

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

# provide 1 non OO method for one liners
sub quote {
    my ($arg_ref) = @_;
    return get_quote(q{}, $arg_ref);
}

# list of quote attributions (names) (makes searching easier)
sub list_attr_names {
   return _get_field_all_from('name', Attr->retrieve_all);
}

# list of quote categories
sub list_categories {
   return _get_field_all_from('catg', Catg->retrieve_all);
}

## list of quote sources
sub list_attr_sources {
   return _get_field_all_from('source', Quote->retrieve_all);
}

sub _get_field_all_from {
   my ($field, @all_stored) = @_;

    my $arr_ref = [];
    RECORDS:
    foreach my $f_obj (@all_stored){
        my $s = $f_obj->$field;
        # if doesn't exist and not a dup
        if (! $f_obj->$field || scalar grep {/$s/sm} @{$arr_ref}){
            next RECORDS;
        }
        push @{ $arr_ref }, $f_obj->$field;
    }
    return join "\n", sort @{$arr_ref};
}

sub _get_attribution_ids_from_name {
    my ($attr_name) = @_;

    my $c_ids = [];
    # a bug: what if string starts with what we specify
    #i.e. => %Griffin% doesn' match 'Griffin' (no quotes)
    RESULTS:
    foreach my $c_obj (Attr->search_like(name => "%$attr_name%")){
       next RESULTS unless $c_obj->attr_id;
       push @{ $c_ids }, $c_obj->attr_id;
    }

    if (not scalar @{$c_ids}) {
        croak 'attribution not found';
    }

    return $c_ids;

}

sub _get_quote_id_from_quote {
    my ($quote) = @_;

    my $q_ids = [];
    # a bug: what if string starts with what we specify
    #i.e. => %Griffin% doesn' match 'Griffin' (no quotes)
    RESULTS:
    foreach my $c_obj (Quote->search(quote => $quote)){
       next RESULTS unless $c_obj->quot_id;
       push @{ $q_ids }, $c_obj->quot_id;
    }

    if (not scalar @{$q_ids}) {
        croak 'quote not found';
    }

    return $q_ids;

}

# can handle scalar or array ref
sub _rm_beg_end_space {
    my ($v) = @_;
    return unless $v;
    if (ref $v eq 'ARRAY'){
      my $arr_ref = ();
      foreach my $vl (@{$v}){
          push @{$arr_ref}, _rm_beg_end_space($vl);
      }
      return $arr_ref;
    }
    else {
      $v =~ s/\A\s+//xmsg;
      $v =~ s/\s+\z//xmsg;
      return $v;
    }
  return;
}

sub _get_one_rand_quote_from_all {
    #my $quotes_ref = [];
    #foreach my $q_obj (Quote->retrieve_all){
    #    next unless $q_obj->quote;
    #    my $record = Attr->retrieve($q_obj->attr_id);
    #    my $attr_name = $record->name || q{};
    #    push @{ $quotes_ref }, $q_obj->quote . "\n-- $attr_name";
    #}
    my $quotes_ref = _get_quote_ref_from_all(Quote->retrieve_all);
    return $quotes_ref->[rand scalar @{$quotes_ref}];
}

sub _get_rating_params {
    my ($rating) = @_;
    return unless $rating;

    my ($lower, $upper) = (q{}, q{});
    ($lower, $upper) = split /-/sm, $rating;

    if ($upper && !$lower) { croak 'negative range not permitted'};

    return (_rm_beg_end_space($lower), _rm_beg_end_space($upper));
}

sub _get_if_rating {
    my ($lower, $upper) = @_;

    if ($lower and $upper) { # a range, find within
        $lower =  qq/ AND rating >= '$lower' /;
        $upper =  qq/ AND rating <= '$upper' /;
    }
    elsif ($lower and not $upper) { # not a range, find exact rating
        $lower =  qq/ AND rating = '$lower' /
        #$upper = q{};
    }
    elsif ($upper and not $lower) {
        $upper =  qq/ AND rating = '$upper' /
        #$lower = q{};
    }

    return ($lower, $upper);
}

sub _get_ids_if_catgs_exist {
    my ($catgs) = @_;

    my $catg_ids = ();
    # get category id
    RECS:
    foreach my $c_obj (Catg->retrieve_all){
        next RECS if not $c_obj->catg;

        if (ref $catgs eq 'ARRAY'){
          foreach my $c (@{$catgs}){
            if ($c_obj->catg eq $c){
              # use cat_id if already exists
              push @{$catg_ids}, $c_obj->catg_id;
            }
          }
        }
        else {
          if ($c_obj->catg eq $catgs){
            # use cat_id if already exists
            push @{$catg_ids}, $c_obj->catg_id;
          }
        }
    }
    return $catg_ids;
}

sub _get_quote_id_from_catg_id {
    my ($catg_ids) = @_;

    my $quote_ids = ();
    RECS:
    foreach my $qc_obj (QuoteCatg->retrieve_all){
        next RECS if not $qc_obj->quot_id;

        if (ref $catg_ids eq 'ARRAY'){
          foreach my $c (@{$catg_ids}){
            if ($qc_obj->catg_id eq $c){
              # use cat_id if already exists
              push @{$quote_ids}, $qc_obj->quot_id;
            }
          }
        }
        else {
          if ($qc_obj->catg_id eq $catg_ids){
            # use cat_id if already exists
            push @{$quote_ids}, $qc_obj->quot_id;
          }
        }
    }
    return $quote_ids;
}

sub _untaint_data {
   my ($arr_ref) = @_;
   my $ut_ref = ();
   foreach my $q (@{$arr_ref}){
      if ($q =~ m{\A([0-9]+)\z}sm){
          push @{$ut_ref}, $1;
      }
   }
   return $ut_ref;
}

# TODO fixme: arg list too long
sub _get_rand_quote_for_attribution {
    my ($attr_name, $lower, $upper, $limit, $contain, $source, $catgs) = @_;

    $attr_name ||= q{};
    $lower     ||= q{};
    $upper     ||= q{};
    $limit     ||= q{};
    $contain   ||= q{};
    $source    ||= q{};
    $catgs     ||= q{};

    my $ids = _get_attribution_ids_from_name($attr_name);
    my $phs = _make_correct_num_of_sql_placeholders($ids);

    if ($attr_name) {
        $attr_name =  qq/ attr_id IN ($phs) /;
    }
    else {
        # why would we want this method without a attribution arg?
        # still, let's handle gracefully
        $attr_name =  q/ attr_id IS NOT NULL /;
        $ids = [];
    }

    if ($source) {
        $source =~ s{'}{''}gsm; # sql escape single quote
        $source =  qq/ AND source = '$source' /;
    }
    my $qids =  q{};
    if ($catgs) {
        $catgs  = _get_ids_if_catgs_exist($catgs);
        my $qid_ref = _get_quote_id_from_catg_id($catgs);
        $qids =  join ',', @{_untaint_data($qid_ref)};
        $qids  =  qq/ AND quot_id IN ($qids) /;
    }

    ($lower, $upper) = _get_if_rating($lower, $upper);

    if ($contain) { $contain =  qq/ AND quote LIKE '%$contain%' / }
    if ($limit) { $limit =  qq/ LIMIT '$limit' / };

    my @q = Quote->retrieve_from_sql(
              qq{ $attr_name $lower $upper $source $qids $contain $limit },
              @{$ids}
            );

    # XXX code duplication but smaller footprint
    # choosing not less code duplication, we'll see,...
    #my $quotes_ref = [];
    #foreach my $q_obj ( @q ){
    #    next unless $q_obj->quote;
    #    my $record = Attr->retrieve($q_obj->attr_id);
    #    my $attr_name = $record->name || q{};
    #    push @{ $quotes_ref }, $q_obj->quote . "\n-- $attr_name";
    #}
    #return _get_quote_ref_from_all(\@q);
    # XXX array_ref does not work here!
    return _get_quote_ref_from_all(@q);

    #return $quotes_ref;
}

sub _get_quote_ref_from_all {
    my (@results) = @_;
    #my ($results) = @_;

    my $quotes_ref = [];
    #foreach my $q_obj ( @{$results} ){
    foreach my $q_obj ( @results ){
        next unless $q_obj->quote;
        my $rec = Attr->retrieve($q_obj->attr_id);
        my $attr_name = $rec->name || q{};
        push @{ $quotes_ref }, $q_obj->quote . "\n-- $attr_name";
    }

    return $quotes_ref;
}

sub _args_are_valid {
    my ( $arg_ref, $accepted ) = @_;

    my $arg_ok = 0;
    foreach my $arg ( %{$arg_ref} ) {
        if ( scalar grep { $arg =~ $_ } @{$accepted} ) {
            $arg_ok = 1;
        }
    }

   if (!$arg_ok) {croak 'unsupported argument option passed'}
}

sub add_quote {
    my ( $self, $arg_ref ) = @_;

    _args_are_valid($arg_ref, [qw/Quote AttrName Source Rating Category/]);

    my $load_db = ACME::QuoteDB::LoadDB->new({
                                #verbose => 1,
                  });

    $load_db->set_record(quote  => $arg_ref->{Quote});
    $load_db->set_record(name   => $arg_ref->{AttrName});
    $load_db->set_record(source => $arg_ref->{Source});
    $load_db->set_record(catg   => $arg_ref->{Category});
    $load_db->set_record(rating => $arg_ref->{Rating});

    if ($load_db->get_record('quote') and $load_db->get_record('name')) {
        return $load_db->write_record;
    }
    else {
        croak 'quote and attribution name are mandatory parameters';
    }

    return;
}

# XXX lame, can only get an id from exact quote
sub get_quote_id {
    my ( $self, $arg_ref ) = @_;

    if (not $arg_ref) {croak 'Quote required'}

    _args_are_valid($arg_ref, [qw/Quote/]);

    my $ids = _get_quote_id_from_quote($arg_ref->{'Quote'});

    return join "\n", sort @{$ids};
}

sub update_quote {
    my ( $self, $arg_ref ) = @_;

    if (not $arg_ref) {croak 'QuoteId and Quote required'}

    _args_are_valid($arg_ref, [qw/Quote QuoteId Source 
                                  Category Rating AttrName/]);

    my $q = Quote->retrieve($arg_ref->{'QuoteId'});

    my $atr = Attr->retrieve($q->attr_id);

    # XXX need to support multi categories
    #my $ctg = Catg->retrieve($q->catg_id);
    my $qc = QuoteCatg->retrieve($q->quot_id);

    my $ctg = Catg->retrieve($qc->catg_id);

    $q->quote($arg_ref->{'Quote'});

    if ($arg_ref->{'Source'}){$q->source($arg_ref->{'Source'})}

    if ($arg_ref->{'Rating'}){$q->rating($arg_ref->{'Rating'})};

    if ($arg_ref->{'AttrName'}){$atr->name($arg_ref->{'AttrName'})};

    # XXX need to support multi categories
    if ($arg_ref->{'Category'}){
       $ctg->catg($arg_ref->{'Category'})
    }

    return ($q->update && $atr->update && $ctg->update);
}

sub delete_quote {
    my ( $self, $arg_ref ) = @_;

    if (not $arg_ref) {croak 'QuoteId required'}

    _args_are_valid($arg_ref, [qw/QuoteId/]);

    my $q = Quote->retrieve($arg_ref->{'QuoteId'});

    #$q->quote($arg_ref->{'QuoteId'});

    return $q->delete;

}

sub get_quote {
    my ( $self, $arg_ref ) = @_;

    # default use case, return random quote from all
    if (not $arg_ref) {
        return _get_one_rand_quote_from_all;
    }

    _args_are_valid($arg_ref, [qw/Rating AttrName Source Category/]);

    my ($lower, $upper) = (q{}, q{});
    if ($arg_ref->{'Rating'}) {
        ($lower, $upper) = _get_rating_params($arg_ref->{'Rating'});
    }

    my $attr_name = q{};
    if ( $arg_ref->{'AttrName'} ) {
        $attr_name = _rm_beg_end_space($arg_ref->{'AttrName'});
    }

    my $source = q{};
    if ( $arg_ref->{'Source'} ) {
        $source = _rm_beg_end_space($arg_ref->{'Source'});
    }

    my $catg; # will become scalar or array ref
    if ( $arg_ref->{'Category'} ) {
       $catg = _rm_beg_end_space($arg_ref->{'Category'});
    }

    # use case for attribution, return random quote
    my $quotes_ref =
          _get_rand_quote_for_attribution($attr_name, $lower,
                     $upper, q{}, q{}, $source, $catg);

    # one random from specified pool
    return $quotes_ref->[rand scalar @{$quotes_ref}];

}

# XXX isn't there a method in DBI for this, bind something,...
# TODO follow up 
sub _make_correct_num_of_sql_placeholders {
    my ($ids) = @_;
    # XXX a hack to make a list of '?' placeholders
    my @qms = ();
    for (1..scalar @{$ids}) {
       push @qms, '?';
    }
    return join ',', @qms;
}

sub get_quotes {
    my ( $self, $arg_ref ) = @_;

    # default use case, return random quote from all
    if (not $arg_ref) {
        return _get_one_rand_quote_from_all;
    }

    _args_are_valid($arg_ref, [qw/Rating AttrName Limit Category Source/]);

    my ($lower, $upper) = (q{}, q{});
    if ($arg_ref->{'Rating'}) {
        ($lower, $upper) = _get_rating_params($arg_ref->{'Rating'});
    }

    my $limit = q{};
    if ($arg_ref->{'Limit'}) {
        # specify 'n' amount of quotes to limit by
        $limit = _rm_beg_end_space($arg_ref->{'Limit'});
    }

    my $attribution = q{};
    if ( $arg_ref->{'AttrName'} ) {
        $attribution = _rm_beg_end_space($arg_ref->{'AttrName'});
    }

    my $source = q{};
    if ( $arg_ref->{'Source'} ) {
        $source = _rm_beg_end_space($arg_ref->{'Source'});
    }

    my $catg = q{};
    if ( $arg_ref->{'Category'} ) {
        $catg = _rm_beg_end_space($arg_ref->{'Category'});
    }
    # use case for attribution, return random quote
    return _get_rand_quote_for_attribution($attribution, $lower,
                     $upper, $limit, q{}, $source, $catg);

}


sub get_quotes_contain {
    my ( $self, $arg_ref ) = @_;


    my $contain = q{};
    if ($arg_ref->{'Contain'}) {
        $contain = _rm_beg_end_space($arg_ref->{'Contain'});
    }
    else {
        croak 'Contain is a mandatory parameter';
    }

    _args_are_valid($arg_ref, [qw/Contain Rating AttrName Limit/]);

    my ($lower, $upper) = (q{}, q{});
    if ($arg_ref->{'Rating'}) {
        ($lower, $upper) = _get_rating_params($arg_ref->{'Rating'});
    }

    my $limit = q{};
    if ($arg_ref->{'Limit'}) {
        $limit = _rm_beg_end_space($arg_ref->{'Limit'});
    }

    # default use case for attribution, return random quote
    my $attr_name = q{};
    if ( $arg_ref->{'AttrName'} ) {
        # return 'n' from random from specified pool
        $attr_name = _rm_beg_end_space($arg_ref->{'AttrName'});
    }

    return _get_rand_quote_for_attribution($attr_name, $lower, $upper, $limit, $contain);
}

1 and 'Chief Wiggum: Uh, no, you got the wrong number. This is 9-1... 2.';


__END__

=head1 NAME

ACME::QuoteDB - API implements CRUD for a Collection of Quotes (adages/proverbs/sayings/epigrams, etc)


=head1 VERSION

Version 0.1.2


=head1 SYNOPSIS

Easy access to a collection of quotes (the 'Read' part)

As quick one liner:

    # randomly display one quote from all available. (like motd, 'fortune')
    perl -MACME::QuoteDB -le 'print quote()'

    # Say you have populated your quotes database with some quotes from 
    # 'The Simpsons'
    # randomly display one quote from all available for person 'Ralph'
    perl -MACME::QuoteDB -le 'print quote({AttrName => "ralph"})'

    # example of output
    Prinskipper Skippel... Primdable Skimpsker... I found something!
    -- Ralph Wiggum

    # get 1 quote, only using these categories (you have defined)
    perl -MACME::QuoteDB -le 'print quote({Category => [qw(Humor Cartoon ROTFLMAO)]})'


In a script/module, OO usage:

    use ACME::QuoteDB;

    my $sq = ACME::QuoteDB->new;

    # get random quote from any attribution
    print $sq->get_quote; 

    # get random quote from specified attribution
    print $sq->get_quote({AttrName => 'chief wiggum'}); 

    # example of output
    I hope this has taught you kids a lesson: kids never learn.
    -- Chief Wiggum

    # get all quotes from one source
    print @{$sq->get_quotes({Source => 'THE SimPSoNs'})}; # is case insensitive

    # get 2 quotes, with a low rating that contain a specific string
    print @{$sq->get_quotes_contain({
                  Contain =>  'til the cow',
                  Rating  => '1-5',
                  Limit   => 2
            })};

    # get 5 quotes from given source
    print @{$sq->get_quotes({Source => 'The Simpsons',
                             Limit  => 5
           })};

    # list all sources
    print $sq->list_attr_sources;

    # list all categories
    print $sq->list_categories;


=head1 DESCRIPTION

This module provides an easy to use programmitic interface 
to a database (sqlite3 or mysql) of 'quotes'.  (any content really, 
that can fit into our L<"defined format"|/"record format">)

For simplicty you can think of it as a modern fancy perl version 
of L<fortune|/fortune> 
(with a management interface, remote database
connection support, 
plus additional features and some not (yet) supported)

Originally, this module was designed for a collection of quotes from a well 
known TV show, once I became aware that distributing it as such would be 
L<copyright infringement|/'copyright infringement'>, I generalized the module, so it can be loaded 
with 'any' content. (in the quote-ish L<format|/"record format">)

=head4 Supported actions include: (CRUD)

=over 4

=item 1 Create

       * Adding quote(s)
       * 'Batch' Loading quotes from a file (stream, other database, etc)

=item 1 Read

       * Displaying a single quote, random or based on some criteria
       * Displaying multiple quotes, based on some criteria
       * Displaying a specific number of quotes, based on some search criteria

=item 1 Update

       * Update an existing quote

=item 1 Delete

       * Remove an existing quote

=back


=head4 Examples of L<Read|/Read>

    my $sq = ACME::QuoteDB->new;

    # on Oct 31st, one could get an appropriate (humorous) quote:
    # (providing, of course that you have defined/populated these categories)
    print $sq->get_quote({Category => [qw(Haloween Humor)]}); 

    # get everthing from certain attributor:
    print @{$sq->get_quotes({AttrName => 'comic book guy'})};

    # get all quotes with a certain rating
    $sq->get_quotes({Rating => '7.0'});

    # get all quotes containing some specific text:
    $sq->get_quotes_contain({Contain => 'til the cow'});


=head4 Examples of L<Create|/Create>

(See L<ACME::QuoteDB::LoadDB> for batch loading)
 
    # add a quote to the database
    my $id_of_added = $sq->add_quote({
                          Quote     => 'Hi, I'm Peter,...",
                          AttrName  => 'Peter Griffin',
                          Source    => 'Family American Dad Guy',
                          Rating    => '1.6',
                          Category  => 'TV Humor',
                      });

=head4 Example of L<Update|/Update>

    # update a quote in the database
    my $quote_id = $sq->get_quote_id({Quote => 'Hi, I'm Peter,..."});

    $sq->update_quote({
        QuoteId   => $quote_id,
        Quote     => 'Hi, I'm Peter, and your not!',
        AttrName  => 'Peter Griffin',
        Source    => 'Family Guy',
        Rating    => '5.7',
        Category  => [qw(TV Humor Crude Adolescent)]
    });

    # category/quote is a many to many relationship: 
    # 1 quote can be in many categories. (and of course 1 category can have many quotes)


=head4 Example of L<Delete|/Delete>

    # delete a quote from the database
    $sq->delete_quote({QuoteId => $quote_id});
    

=over 2

=item record format

One full quote database record currently consits of 5 fields:

Quote, AttrName, Source, Rating, Category

    Quote     => 'the quote desired' # mandatory
    AttrName  => 'who said it'       # mandatory
    Source    => 'where was it said'
    Rating    => 'how you rate the quote/if at all',
    Category  => 'what category is the quote in',

For example:

    Quote     => 'Hi, I'm Peter,...",
    AttrName  => 'Peter Griffin',
    Source    => 'Family Guy',
    Rating    => '8.6',
    Category  => 'TV Humor',

=item * NOTE: In order for this module to be useful one has to load some quotes
 to the database.  Hey, just once though :) (see below - L<Loading Quotes|/"LOADING QUOTES">)

=back

=head1 OVERVIEW

Easy, quick auto-CRUD access to a collection of quotes. (which you provide)

Some ideal uses for this module could be:

=over 4

=item 1 

Quotes Website (quotes/movie/lyrics/limerick/proverbs/jokes/etc)

=item 2 

perl replacement for 'fortune'

=item 3 

Dynamic signature generation

=item 4 

international languages (has utf8 support)

=item 5 

convenient storing/sharing collections of quotes

=item 6 

for me to finally have a place to store (and manage) quotes (that can
be easily backed up or even to a remote db if desired)

=item 7 

anywhere perl is supported and 'quotes' are desired.

=item 8

others? (let me know what you do, if you want, if you do)

=back

See L</DESCRIPTION> above

Also see L<ACME::QuoteDB::LoadDB>


=head1 USAGE

    use ACME::QuoteDB;

    my $sq = ACME::QuoteDB->new;

    print $sq->get_quote;

    # examples are based on quotes data in the test database. 
    # (see tests t/data/)

    # get specific quote based on basic text search.
    # search all 'ralph' quotes for string 'wookie'
    print $sq->get_quotes_contain({
                  Contain   => 'wookie', 
                  AttrName => 'ralph',
                  Limit     => 1          # only return 1 quote (if any)
           });
    # output:
    I bent my wookie.
    -- Ralph Wiggums

    # returns all quotes attributed to 'ralph', with a rating between 
    # (and including) 7 to 9
    print join "\n",  @{$sq->get_quotes({
                                          AttrName => 'ralph', 
                                          Rating    => '7-9'
                                        })
                       };
    
    # same thing but limit to 2 results returned
    # (and including) 7 to 9
    print join "\n",  @{$sq->get_quotes({
                                          AttrName => 'ralph', 
                                          Rating    => '7-9',
                                          Limit     => 2
                                         })
                       };

    # get 6 random quotes (any attribution)
    foreach my $q ( @{$sq->get_quotes({Limit => 6})} ) {
        print "$q\n";
    }


    # get list of available attributions (that have quotes provided by this module)
    print $sq->list_attr_names;

    # any unique part of name will work
    # i.e these will all return the same results (because of our limited
    # quotes db data set)
    print $sq->get_quotes({AttrName => 'comic book guy'});
    print $sq->get_quotes({AttrName => 'comic book'});
    print $sq->get_quotes({AttrName => 'comic'});
    print $sq->get_quotes({AttrName => 'book'});
    print $sq->get_quotes({AttrName => 'book guy'});
    print $sq->get_quotes({AttrName => 'guy'});

   # get all quotes, only using these categories (you have defined)
   print @{$sq->get_quotes({ Category => [qw(Humor ROTFLMAO)] })};

   # get all quotes from Futurama
   print @{$sq->get_quotes({Source => Futurama})};


Also see t/02* included with this distribution.
(available from the CPAN if not included on your system)


=head1 SUBROUTINES/METHODS 

For the most part this is an OO module. There is one function (quote) provided
for command line 'one liner' convenience. 

=head2 quote
    
    returns one quote. (is exported).
    this takes identical arguments to 'get_quote'. (see below)
     
    example:

    perl -MACME::QuoteDB -le 'print quote()'

=head2 new

    instantiate a ACME::QuoteDB object.

    takes no arguments

    # example
    my $sq = ACME::QuoteDB->new;

=head2 get_quote
     
    returns one quote

    # get random quote from any attribution
    print $sq->get_quote;

    # get random quote from specified attribution
    print $sq->get_quote({AttrName => 'chief wiggum'});

    Optional arguments, a hash ref.

    available keys: AttrName, Rating

    my $args_ref = {
                     AttrName => 'chief wiggum'
                     Rating    => 7,
                    };

    print $sq->get_quote($args_ref);

    Note: The 'Rating' option is very subjective. 
    It's a 0-10 scale of 'quality' (or whatever you decide it is)

    To get a list of the available AttrNames use the list_attr_names method
    listed below.  
    
    Any unique part of name will work

    Example, for attribution 'comic book guy'

    # these will all return the same results
    print $sq->get_quotes({AttrName => 'comic book guy'});

    print $sq->get_quotes({AttrName => 'comic book'});

    print $sq->get_quotes({AttrName => 'comic'});

    print $sq->get_quotes({AttrName => 'book'});

    print $sq->get_quotes({AttrName => 'book guy'});

    print $sq->get_quotes({AttrName => 'guy'});
 
    # However, keep in mind the less specific the request is the more results
    # are returned, for example the last one would match, 'Comic Book Guy', 
    # 'Buddy Guy' and 'Guy Smiley',...

=begin comment
    
    # XXX this is a bug with sub _get_attribution_ids_from_name 
    #print $sq->get_quotes({AttrName => 'guy'}); would not match 'Guy Smiley'

=end comment

=head2 add_quote
     
    Adds the supplied record to the database

    possible Key arguments consist of:
        Quote, AttrName, Source, Rating, Category  

    with only Quote and AttrName being mandatory (all are useful though):

    For Example: 

      my $q = 'Lois: Peter, what did you promise me?' .
      "\nPeter: That I wouldn't drink at the stag party." .
      "\nLois: And what did you do?" .
      "\nPeter: Drank at the stag pa-- ... Whoa. I almost walked into that one.";
      
      $sq->add_quote({
          Quote     => $q,
          AttrName  => 'Peter Griffin',
          Source    => 'Family Guy',
          Rating    => '8.6',
          Category  => 'TV Humor',
      });


=head2 get_quote_id (very beta)
 
   given a (verbatim) quote, will retrieve that quotes id
   (only useful for then doing an L</update> or L</delete>

   possible Key arguments consist of: Quote

   my $q = 'Lois: Peter, what did you promise me?' .
  "\nPeter: That I wouldn't drink at the stag party." .
  "\nLois: And what did you do?" .
  "\nPeter: Drank at the stag pa-- ... Whoa. I almost walked into that one.";
  
  my $qid = $sq->get_quote_id({Quote => $q});
  print $qid; # 30

=head2 delete_quote (very beta)

    deletes an existing quote in the database
    takes an valid quote id (see L</get_quote_id>)

    possible Key arguments consist of: QuoteId

      $sq->delete_quote({QuoteId => $qid});


=head2 update_quote (very beta)
     
    updates an existing quote in the database

    possible Key arguments consist of: QuoteId, Quote

      my $q = 'Lois: Peter, what did you promise me?' .
      "\nPeter: That I wouldn't drink at the stag party." .
      "\nLois: And what did you do?" .
      "\nPeter: Drank at the stag pa-- ... Whoa. I almost walked into that one.";

      $q =~ s/Lois/Marge/xmsg;
      $q =~ s/Peter/Homer/xmsg;
 
      $sq->update_quote({
          QuoteId   => $qid, # as returned from L</get_quote_id>
          Quote     => $q,
          AttrName  => 'Lois Simpson',
          Source    => 'The Simpsons Guys',
          Rating    => '9.6',
          Category  => 'Sometimes Offensive Humor',
      });


=head2 get_quotes

    returns zero or more quote(s)

    Optional arguments, a hash ref.

    available keys: AttrName, Rating, Limit

    # returns 2 ralph wiggum quotes with a rating between 
    # (and including) 7 to 9
    print join "\n",  @{$sq->get_quotes({
                                          AttrName => 'ralph', 
                                          Rating    => '7-9',
                                          Limit     => 2
                                         })
                       };

    AttrName and Rating work exactely the same as for get_quote (docs above)
    
    Limit specifies the amout of results you would like returned. (just like
    with SQL)


=head2 get_quotes_contain

    returns zero or more quote(s), based on a basic text search.

    # get specific quote based on basic text search.
    # search all ralph wiggum quotes for string 'wookie'
    print $sq->get_quotes_contain({
                  Contain   => 'wookie', 
                  AttrName => 'ralph',
                  Limit     => 1          # only return 1 quote (if any)
           })->[0]; # q{Ralph: I bent my wookie.};


    Optional arguments, a hash ref.

    available keys: AttrName, Contain, Limit

    AttrName and Limit work exactly the same as for get_quotes (docs above)
    
    Contain specifies a text string to search quotes for. If a AttrName
    option is included, search is limited to that attribution.

    Contain is a simple text string only. Regex not supported
    Contain literally becomes: AND quote LIKE '%$contain%'


=head2 list_attr_names

    returns a list of attributions (name) for which we have quotes.

    # get list of available attributions (that have quotes provided by this module)
    print $sq->list_attr_names;


=head2 list_categories

    returns a list of categories defined in the database

    # get list of available categories (that have quotes provided by this module)
    print $sq->list_categories;


=head2 list_attr_sources

    returns a list of attribution sources defined in the database

    # get list of attribution sources (that have quotes provided by this module)
    print $sq->list_attr_sources;


=head1 LOADING QUOTES

In order to actually use this module, one has to load quotes content,
hopefully this is relativly easy,... (see t/01-load_quotes.t in tests)

=over 4

=item 1 add_quote, one record at a time, probably within an iteration loop

see L</add_quote>

=item 1 (Batch Load) load quotes from a csv file. (tested with comma and tab delimiters)

  format of file must be as follows: (headers)
  "Quote", "Attribution Name", "Attribution Source", "Category", "Rating"
 
  for example:
  "Quote", "Attribution Name", "Attribution Source", "Category", "Rating"
  "I hope this has taught you kids a lesson: kids never learn.","Chief Wiggum","The Simpsons","Humor",9
  "Sideshow Bob has no decency. He called me Chief Piggum. (laughs) Oh wait, I get it, he's all right.","Chief Wiggum","The Simpsons","Humor",8

=item 1 if these dont suit your needs, ACME::QuoteDB::LoadDB is sub-classable, 

  so one can extract data anyway they like and populate the db themselves. 
  (there is a test that illustrates overriding the stub method, 'dbload')

   you need to populate a record data structure:

    $self->set_record(quote  => q{}); # mandatory
    $self->set_record(name   => q{}); # mandatory
    $self->set_record(source => q{}); # optional but useful
    $self->set_record(catg   => q{}); # optional but useful
    $self->set_record(rating => q{}); # optional but useful

   # then to write the record you call
   $self->write_record;

   NOTE: this is a record-by-record operation, so one would perform this within a
   loop. there is no bulk (memory dump) write operation currently.


=back


For more see L<ACME::QuoteDB::LoadDB>


=begin comment
 
    keep pod coverage happy.

    # Coverage for ACME::QuoteDB is 71.4%, with 3 naked subroutines:
    # Attr
    # Quote
    # Catg
    # QuoteCatg

    pod tests incorrectly state, Attr, Quote and Catg are subroutines, well they
    are,... (as aliases) but act on a different object. 
    
    TODO: explore the above (is this a bug, if so, who's?, version effected, 
    create use case, etc) 
    
=head2 Attr

=head2 Quote

=head2 Catg

=head2 QuoteCatg

=end comment

=head1 DIAGNOSTICS

An error such as:

C<DBD::SQLite::db prepare_cached failed: no such table: ,...>

probably means that you do not have a database created in the correct format.

basically, you need to create the database, usually, on a first run

you need to add the flag (to the loader):

create_db => 1, # first run, create the db

appending to an existing database is the default behaviour

see L<ACME::QuoteDB::LoadDB/create_db_tables>

=head1 CONFIGURATION AND ENVIRONMENT

if you are running perl > 5.8.5 and have access to
install cpan modules, you should have no problem installing this module
(utf-8 support in DBD::SQLite not avaible until 5.8 - we don't support 'non
utf-8 mode)

=over 1

=item * By default, the quotes database used by this module installs in the 
system path, 'lib', (See L<Module::Build/"INSTALL PATHS">)
as world writable - i.e. 0666 (and probably owned by root)
If you don't like this, you can modify Build.PL to not chmod the file and it
will install as 444/readonly, you can also set a chown in there for whoever
you want to have RW access to the quotes db.

Alternativly, one can specify a location to a quotes database (file) to use.
(Since the local mode is sqlite3, the file doesn't even need to exist, just
needs read/write access to the path on the filesystem)

Set the environmental variable:

$ENV{ACME_QUOTEDB_PATH} (untested on windows)

(this has to be set before trying a database load and also (everytime before 
using this module, obviouly)

Something such as:

BEGIN { 
    # give alternate path to the DB
    # doesn't need to exist, will create
    $ENV{ACME_QUOTEDB_PATH} = '/home/me/my_stuff/my_quote_db'
}

* (NOTE: be sure this (BEGIN) exists *before* the 'use ACME::QuoteDB' lines)

The default is to use sqlite3.

In order to connect to a mysql database, several environmental variables
are required.

BEGIN {
    # have to set this to use remote database
    $ENV{ACME_QUOTEDB_REMOTE} =  'mysql';
    $ENV{ACME_QUOTEDB_DB}     =  'acme_quotedb';
    $ENV{ACME_QUOTEDB_HOST}   =  'localhost';
    $ENV{ACME_QUOTEDB_USER}   =  'acme_user';
    $ENV{ACME_QUOTEDB_PASS}   =  'acme';
}

Set the above in a begin block.

The database connection is transparent. 

Module usage wise, all operations are the same but now
you will be writing to the remote mysql database specified.

(The user will need read/write permissions to the db/tables)
(mysql admin duties are beyond the scope of this module)

The only supported databases at this time are sqlite and mysql.

It is trivial to add support for others

=back

=head1 DEPENDENCIES

L<Carp>

L<Data::Dumper>

L<criticism> (pragma - enforce Perl::Critic if installed)

L<version>(pragma - version numbers)

L<aliased>

L<Test::More>

L<DBD::SQLite>

L<DBI>

L<Class::DBI>

L<File::Basename>

L<Readonly>

L<Cwd>

L<Module::Build>


=head1 INCOMPATIBILITIES

none known of

=head1 SEE ALSO

man fortune (unix/linux)

L<Fortune>

L<fortune>

L<Acme::RandomQuote::Base>

L<WWW::LimerickDB>

=begin comment

    C<Fortune> http://search.cpan.org/~gward/Fortune-0.2/Fortune.pm
    C<fortune> http://search.cpan.org/~cwest/ppt-0.14/bin/fortune
    C<Acme::RandomQuote::Base> http://search.cpan.org/~mangaru/Acme-RandomQuote-Base-0.01/lib/Acme/RandomQuote/Base.pm
    C<WWW::LimerickDB> http://search.cpan.org/~zoffix/WWW-LimerickDB-0.0305/lib/WWW/LimerickDB.pm

=end comment


=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>

=head1 TODO

=over 2

=item 1 if the database cannot be found, no error is printed!!!

or if you have no write access to it!
"you'll just get 'no attribute can be found,,...", which is cryptic to say
the least!

=item 1 add a dump backup to csv

a backup mechanism for your db to a regular text csv file.

=item 1 clean up tests 'skip if module X' not installed

(one of sqlite3 or mysql is required). currently dies if DBD::SQLite not
installed

=item 1 support multiple categories from LoadDB

how to load multipul categories from a csv file? 
(try to avoid somthing ugly in our csv file format). or maybe don't support
this.

=item 1 (possibly) support long/short quotes output (see 'man fortune')

=back


=head1 BUGS AND LIMITATIONS

The CRUD stuff is weak for sure.
(i.e. add_quote, update_quote, delete_quote, get_quote_id)

For example, currently you can only get the quote id from the exact quote

In the future, I may just expose the DBI::Class object directly
to those that need/want it.

=begin comment

get_quotes_contain  uses %search% to do it's pattern mattching, so that will
miss some obvious searches, which it should find.

i.e.
'Bill' will not find 'Bill' , beginning and endings of words will be off.

XXX - look at search_like, instead of what you are doing now

=end comment

currently, I am not encapsulating the record data structure used 
by LoadDB->write. (i.e. it's a typical perl5 ojbect, the blessed hash)

I will for sure be encapsulating all data in a future version.
(so, don't have code that does $self->{record}->{name} = 'value', or you won't
be happy down the road). Instead use $self->get_record('name') (getter) or
$self->set_record(name => 'my attrib') (setter)


When we are using a SQLite database backend ('regular' local usage), we 
should probably be using, ORLite instead of Class::DBI 
(although we have not seen any issues yet).

Please report any bugs or feature requests to C<bug-acme-quotedb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ACME-QuoteDB>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ACME::QuoteDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ACME-QuoteDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ACME-QuoteDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ACME-QuoteDB>

=item * Search CPAN

L<http://search.cpan.org/dist/ACME-QuoteDB/>

=back

=head1 ACKNOWLEDGEMENTS

The construction of this module was guided by:

Perl Best Practices - Conway

Test Driven Development

Object Oriented Programming

Gnu

vim 

Debian Linux

Mac OSX

The collective wisdom and code of The CPAN

this module was created with module-starter

module-starter --module=ACME::QuoteDB \
        --author="David Wright" --mb --email=david_v_wright@yahoo.com

=head1 ERRATA

    Q: Why did you put it in the ACME namespace?
    A: Seemed appropriate. I emailed modules@cpan.org and didn't get a
       different reaction.

    Q: Why did you write this?
    A: At a past company, a team I worked on a project with had a test suite, 
    in which at the completion of successful tests (100%), a 'wisenheimer' 
    success message would be printed. (Like a quote or joke or the like)
    (Interestingly, it added a 'fun' factor to testing, not that one is needed 
    of course ;). It was hard to justify spending company time to find and 
    add decent content to the hand rolled process, this would have helped.

    Q: Don't you have anything better to do, like some non-trivial work?
    A: Yup

    Q: Hey Dood! why are u uzing Class::DBI as your ORM!?  Haven't your heard 
       of L<DBIx::Class>?
    A: Yup, and I'm aware of 'the new hotness' L<Rose::DB>. If you use this 
       module and are unhappy with the ORM, feel free to change it. 
       So far L<Class::DBI> is working for my needs.


=head1 FOOTNOTES

=over 4

=item fortune 

unix application in 'games' (FreeBSD) type 'man fortune' from the command line

=item copyright infringement 

L<http://www.avvo.com/legal-answers/is-it-copyright-trademark-infringement-to-operate--72508.html>

=item wikiquote

interesting reading, wikiquote fair use doc: L<http://en.wikiquote.org/wiki/Wikiquote:Copyrights>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ACME::QuoteDB
