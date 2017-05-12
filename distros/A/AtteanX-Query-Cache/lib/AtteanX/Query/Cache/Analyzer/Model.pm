package AtteanX::Query::Cache::Analyzer::Model;

use v5.14;
use warnings;

use Moo;
use Types::Standard qw(ArrayRef Str);
use namespace::clean;

extends 'AtteanX::Model::SPARQLCache::LDF';

has 'try' => (is => 'rw', isa => Str);

1;
