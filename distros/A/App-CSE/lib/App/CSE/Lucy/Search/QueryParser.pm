package App::CSE::Lucy::Search::QueryParser;
$App::CSE::Lucy::Search::QueryParser::VERSION = '0.016';
use base qw/Lucy::Search::QueryParser/;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

use Data::Dumper;

sub make_term_query{
  my ($self, %options) = @_;

  my $field = $options{field};
  my $term = $options{term};


  if( $term =~ /\*$/ ){
    $LOGGER->trace("Will make a PREFIX  with ".Dumper(\%options));
    return App::CSE::Lucy::Search::QueryPrefix->new(field => $field,
                                                    query_string => $term);
  }
  $LOGGER->trace("Will make a TERM query with ".Dumper(\%options));
  return $self->SUPER::make_term_query(%options);
}

1;
