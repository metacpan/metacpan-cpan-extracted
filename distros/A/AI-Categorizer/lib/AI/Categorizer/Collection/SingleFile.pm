package AI::Categorizer::Collection::SingleFile;
use strict;

use AI::Categorizer::Collection;
use base qw(AI::Categorizer::Collection);

use Params::Validate qw(:types);

__PACKAGE__->valid_params
  (
   path => { type => SCALAR|ARRAYREF },
   categories => { type => HASHREF|UNDEF, default => undef },
   delimiter => { type => SCALAR },
  );

__PACKAGE__->contained_objects
  (
   document => { class => 'AI::Categorizer::Document::Text',
		 delayed => 1 },
  );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  
  $self->{fh} = do {local *FH; *FH};  # double *FH avoids a warning

  # Documents are contained in a file, or list of files
  $self->{path} = [$self->{path}] unless ref $self->{path};
  $self->{used} = [];

  $self->_next_path;
  return $self;
}

sub _next_path {
  my $self = shift;
  close $self->{fh} if $self->{cur_file};

  push @{$self->{used}}, shift @{$self->{path}};
  $self->{cur_file} = $self->{used}[-1];
  open $self->{fh}, "< $self->{cur_file}" or die "$self->{cur_file}: $!";
}

sub next {
  my $self = shift;

  my $fh = $self->{fh}; # Must put in a simple scalar
  my $content = do {local $/ = $self->{delimiter}; <$fh>};

  if (!defined $content) { # File has been exhausted
    unless (@{$self->{path}}) { # All files have been exhausted
      $self->{fh} = undef;
      return undef;
    }
    $self->_next_path;
    return $self->next;
  } elsif ($content =~ /^\s*$self->{delimiter}$/) { # Skip empty docs
    return $self->next;
  }
#warn "doc is $content";
#warn "creating document=>@{[ %{$self->{container}{delayed}{document}} ]}";

  return $self->create_delayed_object('document', content => $content);
}

sub count_documents {
  my ($self) = @_;
  return $self->{document_count} if defined $self->{document_count};
  
  $self->rewind;

  my $count = 0;
  local $/ = $self->{delimiter};
  my $fh = $self->{fh};
  while (1) {
    $count++ while <$fh>;
    last unless @{$self->{path}};
    $self->_next_path;
  }
  
  $self->rewind;

  return $self->{document_count} = $count;
}

sub rewind {
  my ($self) = @_;

  close $self->{fh} if $self->{cur_file};
  unshift @{$self->{path}}, @{$self->{used}};
  $self->{used} = [];
  $self->_next_path;
}

1;
