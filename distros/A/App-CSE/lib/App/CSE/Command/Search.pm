package App::CSE::Command::Search;
$App::CSE::Command::Search::VERSION = '0.012';
use Moose;
extends qw/App::CSE::Command/;

use App::CSE::Command::Check;
use App::CSE::Command::Index;
use App::CSE::Lucy::Highlight::Highlighter;
use App::CSE::Lucy::Search::QueryPrefix;
use DateTime;
use File::Find;
use File::MimeInfo::Magic;
use Log::Log4perl;
use Lucy::Analysis::RegexTokenizer;
use Lucy::Search::Hits;
use Lucy::Search::IndexSearcher;
use App::CSE::Lucy::Search::QueryParser;
use Lucy::Search::SortSpec;
use Lucy::Search::SortRule;
use Path::Class::Dir;
use Time::HiRes;

my $LOGGER = Log::Log4perl->get_logger();

# Parameter stuff

# Inputs
has 'query_str' => ( is => 'ro' , isa => 'Str' , lazy_build => 1);
has 'dir_str' => ( is => 'ro' , isa => 'Maybe[Str]', lazy_build => 1);
has 'num' => ( is => 'ro' , isa => 'Int', lazy_build => 1);
has 'offset' => ( is => 'ro' , isa => 'Int' , lazy_build => 1);
has 'sort_str' => ( is => 'ro' , isa => 'Str' , lazy_build => 1);

# Calculated
has 'filtered_query' => ( is => 'ro' , isa => 'Lucy::Search::Query' , lazy_build => 1);
has 'query' => ( is => 'ro', isa => 'Lucy::Search::Query' , lazy_build => 1);
has 'sort_spec' => ( is => 'ro' , isa => 'Lucy::Search::SortSpec', lazy_build => 1);

# Operational stuff.
has 'hits' => ( is => 'ro', isa => 'Lucy::Search::Hits', lazy_build => 1);
has 'searcher' => ( is => 'ro' , isa => 'Lucy::Search::IndexSearcher' , lazy_build => 1);
has 'highlighter' => ( is => 'ro' , isa => 'App::CSE::Lucy::Highlight::Highlighter' , lazy_build => 1);

sub _build_sort_spec{
  my ($self) = @_;

  my @rules = ( Lucy::Search::SortRule->new( type => 'score'),
                Lucy::Search::SortRule->new( field => 'path' )
              );
  if( $self->sort_str() eq 'score' ){
    # Nothing to do.
    1;
  }elsif( $self->sort_str() eq 'path' ){
    @rules = (
              Lucy::Search::SortRule->new( field => 'path' ),
              Lucy::Search::SortRule->new( type => 'score'),
             );
  }elsif( $self->sort_str() eq 'mtime' ){
    @rules = (
              Lucy::Search::SortRule->new( field => 'mtime' , reverse => 'true' ),
              Lucy::Search::SortRule->new( field => 'path' ),
             );
  }else{
    $LOGGER->error($self->cse->colorizer->colored("Unknown sort mode ".$self->sort_str().". Falling back to 'score'", 'red bold'));
  }

  return Lucy::Search::SortSpec->new(rules => \@rules );
}


sub _build_highlighter{
  my ($self) = @_;

  ## Note that this only builds a content highlighter.

  $LOGGER->debug("Using highlight_query = ".$self->highlight_query('content')->to_string());
  return App::CSE::Lucy::Highlight::Highlighter->new(
                                                     searcher => $self->searcher(),
                                                     query    => $self->highlight_query(),
                                                     field    => 'content',
                                                     excerpt_length => 100,
                                                     cse_command => $self,
                                                    );
}

=head2 highlight_query

Returns the query used to highlight the given field. Will be the original
query or the highlight query of the query prefix.

Usage:

  my $hl_query = $this->highlight_query('content');

=cut

sub highlight_query{
  my ($self, $field) = @_;
  my $query = $self->query();
  if( $query->isa('App::CSE::Lucy::Search::QueryPrefix') ){
    return $query->highlight_query($field || 'content');
  }
  return $query;
}

sub _build_searcher{
  my ($self) = @_;
  my $searcher = Lucy::Search::IndexSearcher->new( index => $self->cse->index_dir().'' );
  return $searcher;
}

sub options_specs{
  return [ 'offset|o=i', 'num|n=i', 'sort|s=s' , 'reverse|r' ];
}

my %legit_sort = ( 'score' => 1,  'path' => 1 , 'mtime' => 1 );

sub _build_sort_str{
  my ($self) = @_;
  my $sort_str =  $self->cse()->options()->{sort} || 'score';
  unless( $legit_sort{$sort_str} ){
    $LOGGER->error($self->cse->colorizer->colored("Unknown sort mode ".$sort_str.". Falling back to 'score'", 'red bold'));
    return 'score';
  }

  my $perl_version = $];
  if( $perl_version >= 5.016 && $sort_str ne 'score' ){
    $LOGGER->warn($self->cse->colorizer->colored("A bug in Lucy doesn't allow this version of Perl($perl_version) to take sort mode (".$sort_str.") into account for now.", 'yellow bold'));
    return 'score'
  }


  return $sort_str;
}

sub _build_offset{
  my ($self) = @_;
  return $self->cse()->options->{offset} || 0;
}

sub _build_num{
  my ($self) = @_;
  my $num = $self->cse->options()->{num};
  return defined($num) ? $num : 5;
}

sub _build_hits{
  my ($self) = @_;

  $LOGGER->info("Searching for '".$self->filtered_query()->to_string()."'");


  {
    my $this_version = $self->cse()->version();
    my $index_version = $self->cse->index_meta->{version};
    unless( $this_version eq $index_version ){
      $LOGGER->warn($self->cse()->colorizer->colored("Index version is too old ($index_version) for this program ($this_version). Please consider re-indexing", 'yellow bold'));
    }
  }

  my $perl_version = $];

  my $hits = $self->searcher->hits( query => $self->filtered_query(),
                                    offset => $self->offset(),
                                    num_wanted => $self->num(),
                                    ## This segfaults on perl 16 and 18 :(
                                    ( $perl_version < 5.016 ) ? ( sort_spec => $self->sort_spec() ) : ()
                                  );
  return $hits;
}

sub _build_query_str{
  my ($self) = @_;

  my $cse = $self->cse();

  my @str_bits = ();
  while($cse->args()->[0] && ! -e $cse->args()->[0] ){
      push @str_bits, ( shift @{$cse->args()} );
  }
  return  join(' ', @str_bits);
}

sub _build_dir_str{
  my ($self) = @_;
  # Give a chance to query STR.
  $self->query_str();
  return shift @{$self->cse->args()} || undef;
}

sub _build_filtered_query{
  my ($self) = @_;
  if( my $dir_str = $self->dir_str() ){
    # Filter the query with a filter on this dir as a prefix.
    my $fq = Lucy::Search::ANDQuery->new();
    $fq->add_child($self->query());
    $fq->add_child(App::CSE::Lucy::Search::QueryPrefix->new( field => 'path.raw',
                                                             query_string => $dir_str.'*',
                                                             keep_case => 1
                                                           )
                  );
    return $fq;
  }

  # General case. Same as the original query.
  return $self->query();
}

sub _build_query{
  my ($self) = @_;

  # if( $self->query_str() =~ /\*$/ ){
  #   return App::CSE::Lucy::Search::QueryPrefix->new(
  #                                                   field        => 'content',
  #                                                   query_string => $self->query_str(),
  #                                                  );
  # }

  my $analyzer;
  my $fields = [ 'content' , 'decl', 'path' ];

  if( $self->query_str() =~ /\*/ ){
    # Let the query parser keep the *'s
    $analyzer = Lucy::Analysis::RegexTokenizer->new( pattern => '\S+' );
    unless( $self->query_str() =~ /\:/ ){
      # No colon. Search only in content
      $fields = [ 'content' ];
    }
  }

  my $qp = App::CSE::Lucy::Search::QueryParser->new( schema => $self->searcher->get_schema,
                                                     default_boolop => 'AND',
                                                     fields => $fields,
                                                     $analyzer ?  ( analyzer => $analyzer ) : (),
                                                   );
  $qp->set_heed_colons(1);

  return $qp->parse($self->query_str());
}

sub execute{
  my ($self) = @_;

  my $colorizer = $self->cse->colorizer();
  my $colored = sub{ $colorizer->colored(@_); };

  unless( $self->query_str() ){
    $LOGGER->warn(&$colored("Missing query. Do cse help" , 'red'));
    return 1;
  }

  # Check the index.
  my $check = App::CSE::Command::Check->new({ cse => $self->cse() });
  if( $check->execute() ){
    $LOGGER->info(&$colored("Rebuilding the index..", 'green bold'));
    my $index_cmd = App::CSE::Command::Index->new( { cse => $self->cse() });
    if( $index_cmd->execute() ){
      $LOGGER->error(&$colored("Building index failed", 'red'));
      return 1;
    }
  }
  my $start_time = Time::HiRes::time();

  ## This will trigger a search. Look at _build_hits
  my $hits = $self->hits();

  my $highlighter = $self->highlighter();

  $LOGGER->info(&$colored('Hits: '. $self->offset().' - '.( $self->offset() + $self->num() - 1).' of '.$hits->total_hits().' sorted by '.$self->sort_str(), 'green bold')."\n\n");

  while ( my $hit = $hits->next ) {

    my $excerpt = $highlighter->create_excerpt($hit);

    my $star = '';
    if( my $stat = File::stat::stat( $hit->{path} ) ){
      if( $hit->{mtime} lt DateTime->from_epoch(epoch => $stat->mtime())->iso8601() ){
        $star = &$colored('*' , 'red bold');
        # Mark the file as dirty.
        $self->cse()->dirty_files()->{$hit->{'path.raw'}} = 1;
      }
    }

    $LOGGER->trace("Score: ".$hit->get_score());

    my $hit_str = &$colored($hit->{path}.'', 'magenta bold').' ('.$hit->{mime}.') ['.$hit->{mtime}.$star.']'.&$colored(':', 'cyan bold');
    $hit_str .= q|
|.( $excerpt || substr($hit->{content} || '' , 0 , 100 ) ).q|

|;


    $LOGGER->info($hit_str);
  }

  my $stop_time = Time::HiRes::time();

  # Save the dirty files memory.
  $self->cse()->save_dirty_files();

  $LOGGER->info("Search took ".sprintf('%.03f', ( $stop_time - $start_time ))." secs");

  return 0;
}

__PACKAGE__->meta->make_immutable();

=head1 NAME

App::CSE::Command::Search - Search the index for keywords or queries.

=cut
