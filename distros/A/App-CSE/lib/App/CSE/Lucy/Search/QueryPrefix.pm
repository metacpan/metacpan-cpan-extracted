package App::CSE::Lucy::Search::QueryPrefix;
$App::CSE::Lucy::Search::QueryPrefix::VERSION = '0.016';
## Copied from http://api.metacpan.org/source/CREAMYG/Lucy-0.3.3/sample/PrefixQuery.pm

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use base qw( Lucy::Search::Query );
use Carp;
use Scalar::Util qw( blessed );


# Inside-out member vars and hand-rolled accessors.
my %query_string;
my %field;
my %highlight_terms;
my %keep_case;

sub get_query_string { my $self = shift; return $query_string{$$self} }
sub get_field        { my $self = shift; return $field{$$self} }
sub highlight_terms  { my $self = shift; return $highlight_terms{$$self} }
sub keep_case        { my $self = shift; return $keep_case{$$self} }



sub new {
    my ( $class, %args ) = @_;
    my $query_string = delete $args{query_string};
    my $field        = delete $args{field};
    my $keep_case    = delete $args{keep_case} || 0;

    my $self         = $class->SUPER::new(%args);


    confess("'query_string' param is required")
        unless defined $query_string;
    confess("Invalid query_string: '$query_string'")
        unless $query_string =~ /\*\s*$/;
    confess("'field' param is required")
        unless defined $field;

    $query_string{$$self} = $query_string;
    $field{$$self}        = $field;
    $highlight_terms{$$self} = [];
    $keep_case{$$self} = $keep_case;

    return $self;
  }

sub highlight_query{
  my ($self, $field) = @_;
  my $query = Lucy::Search::ORQuery->new();
  foreach my $term ( @{$self->highlight_terms()} ){
    $query->add_child(Lucy::Search::TermQuery->new(
                                                   field => $field || $self->get_field(),
                                                   term  => $term,
                                                  ));
  }
  return $query;
}


sub add_matching_term{
  my ($self, $term ) = @_;
  push @{$self->highlight_terms()}, $term;
}

sub DESTROY {
    my $self = shift;
    delete $query_string{$$self};
    delete $field{$$self};
    delete $highlight_terms{$$self};
    $self->SUPER::DESTROY;
  }

sub equals {
    my ( $self, $other ) = @_;
    return 0 unless blessed($other);
    return 0 unless $other->isa("App::CSE::Lucy::Search::QueryPrefix");
    return 0 unless $field{$$self} eq $field{$$other};
    return 0 unless $query_string{$$self} eq $query_string{$$other};
    return 1;
  }

sub to_string {
    my $self = shift;
    return "$field{$$self}:$query_string{$$self}";
  }

sub make_compiler {
  my ( $self, %args ) = @_;
  my $subordinate = delete $args{subordinate};
  my $compiler = App::CSE::Lucy::Search::PrefixCompiler->new( %args, parent => $self );
  $compiler->normalize unless $subordinate;
  return $compiler;
}

1;

package App::CSE::Lucy::Search::PrefixCompiler;
$App::CSE::Lucy::Search::PrefixCompiler::VERSION = '0.016';
use base qw( Lucy::Search::Compiler );

sub make_matcher {
  my ( $self, %args ) = @_;
  my $seg_reader = $args{reader};

  # Retrieve low-level components LexiconReader and PostingListReader.
  my $lex_reader
    = $seg_reader->obtain("Lucy::Index::LexiconReader");
  my $plist_reader
    = $seg_reader->obtain("Lucy::Index::PostingListReader");


  # Acquire a Lexicon and seek it to our query string.
  my $substring = $self->get_parent->get_query_string;
  $substring =~ s/\*\s*$//;

  ## Making that case insensitive only if the parent says so
  unless( $self->get_parent->keep_case() ){
    $substring = lc( $substring );
  }

  my $field = $self->get_parent->get_field;
  my $lexicon = $lex_reader->lexicon( field => $field );
  return unless $lexicon;


  $lexicon->seek($substring);

  # Accumulate PostingLists for each matching term.
  my @posting_lists;
  while ( defined( my $term = $lexicon->get_term ) ) {
    last unless $term =~ /^\Q$substring/;

    $self->get_parent()->add_matching_term($term);

    my $posting_list = $plist_reader->posting_list(
                                                   field => $field,
                                                   term  => $term,
                                                  );
    if ($posting_list) {
      push @posting_lists, $posting_list;
    }
    last unless $lexicon->next;
  }
  return unless @posting_lists;

  return App::CSE::Lucy::Search::PrefixMatcher->new( posting_lists => \@posting_lists );
}

package App::CSE::Lucy::Search::PrefixMatcher;
$App::CSE::Lucy::Search::PrefixMatcher::VERSION = '0.016';
use base qw( Lucy::Search::Matcher );

# Inside-out member vars.
my %doc_ids;
my %tick;

sub score{
  return 1.0 ; # Fixed score of 1.0
}

sub new {
  my ( $class, %args ) = @_;
  my $posting_lists = delete $args{posting_lists};
  my $self          = $class->SUPER::new(%args);

  # Cheesy but simple way of interleaving PostingList doc sets.
  my %all_doc_ids;
  for my $posting_list (@$posting_lists) {
    while ( my $doc_id = $posting_list->next ) {
      $all_doc_ids{$doc_id} = undef;
    }
  }
  my @doc_ids = sort { $a <=> $b } keys %all_doc_ids;
  $doc_ids{$$self} = \@doc_ids;

  $tick{$$self}  = -1;

  return $self;
}

sub DESTROY {
  my $self = shift;
  delete $doc_ids{$$self};
  delete $tick{$$self};
  $self->SUPER::DESTROY;
}

sub next {
  my $self    = shift;
  my $doc_ids = $doc_ids{$$self};
  my $tick    = ++$tick{$$self};
  return 0 if $tick >= scalar @$doc_ids;
  return $doc_ids->[$tick];
}

sub get_doc_id {
  my $self    = shift;
  my $tick    = $tick{$$self};
  my $doc_ids = $doc_ids{$$self};
  return $tick < scalar @$doc_ids ? $doc_ids->[$tick] : 0;
}

1;
