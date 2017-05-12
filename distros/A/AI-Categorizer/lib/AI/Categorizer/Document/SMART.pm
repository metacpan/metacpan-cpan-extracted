package AI::Categorizer::Document::SMART;

use strict;
use AI::Categorizer::Document;
use base qw(AI::Categorizer::Document);

sub parse {
  my ($self, %args) = @_;
  
  $args{content} =~ s{
		   ^(?:\.I)?\s+(\d+)\n  # ID number - becomes document name
		   \.C\n
		   ([^\n]+)\n     # Categories
		   \.T\n
		   (.+)\n+        # Title
		   \.W\n
		  }
                  {}sx
     
     or die "Malformed record: $args{content}";
  
  my ($id, $categories, $title) = ($1, $2, $3);

  $self->{name} = $id;
  $self->{content} = { title => $title,
		       body  => $args{content} };

  my @categories = $categories =~ m/(.*?)\s+\d+[\s;]*/g;
  @categories = map AI::Categorizer::Category->by_name(name => $_), @categories;
  $self->{categories} = \@categories;
}

1;
