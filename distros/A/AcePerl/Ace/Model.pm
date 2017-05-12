package Ace::Model;
# file: Ace/Model.pm
# This is really just a placeholder class.  It doesn't do  anything interesting.
use strict;
use vars '$VERSION';
use Text::Tabs 'expand';

use overload
  '""' => 'asString',
  fallback => 'TRUE';

$VERSION = '1.51';

my $TAG     = '\b\w+\b';
my $KEYWORD  = q[^(XREF|UNIQUE|ANY|FREE|REPEAT|Int|Text|Float|DateType)$];
my $METAWORD = q[^(XREF|UNIQUE|ANY|FREE|REPEAT|Int|Text|Float|DateType)$];

# construct a new Ace::Model
sub new {
  my $class = shift;
  my ($data,$db,$break_cycle)  = @_;
  $break_cycle ||= {};

  $data=~s!\s+//.*$!!gm;  # remove all comments
  $data=~s!\0!!g;
  my ($name) = $data =~ /\A[\?\#](\w+)/;
  my $self = bless { 
		    name      => $name,
		    raw       => $data,
		    submodels => [],
	       },$class;

  if (!$break_cycle->{$name} && $db && (my @hashes = grep {$_ ne $name} $data =~ /\#(\S+)/g)) {
    $break_cycle->{$name}++;
    my %seen;
    my @submodels = map {$db->model($_,$break_cycle)} grep {!$seen{$_}++} @hashes;
    $self->{submodels} = \@submodels;
  }

  return $self;
}

sub name {
  return shift()->{name};
}

# return all the tags in the model as a hashref.
# in a list context returns the tags as a long list result
sub tags {
  my $self = shift;
  $self->{tags} ||= { map {lc($_)=>1}
		      grep {!/^[\#\?]/o} 
		      grep {!/$KEYWORD/o} 
		      $self->{raw}=~m/(\S+)/g,
		      map {$_->tags} @{$self->{submodels}}
		    };
  return wantarray ? keys %{$self->{tags}} : $self->{tags};
}

# return the path to a particular tag
sub path {
  my $self = shift;
  my $tag = lc shift;
  $self->parse;
  return unless exists $self->{path}{$tag};
  return @{$self->{path}{$tag}};
}

# parse out the paths to each of the tags
sub parse {
  my $self = shift;
  return if exists $self->{path};
  my @lines = grep { !m[^\s*//] } $self->_untabulate;

  # accumulate a list of all the paths
  my (@paths,@path,@path_stack);
  my $current_position = 0;

 LINE:
  for my $line (@lines) {

  TOKEN:
    while ($line =~ /(\S+)/g) { # get a token
      my $tag = $1;
      my $position = pos($line) - length $tag;
      next TOKEN if $tag =~ /$METAWORD/o;
      if ($tag =~ /^[?\#]/) {
	next TOKEN if $position == 0;   # the name of the model, so get next token
	next LINE;                      # otherwise abandon this line
      }
      
      if ($position > $current_position) {  # here's a subtag
	push @path_stack,[$current_position,[@path]];  # remember a copy of partial path
	push @paths,[@path];                           # remember current path
	push @path,$tag;                               # append to the current path
      } elsif ($position == $current_position) {  # here's a sibling tree
	push @paths,[@path];                      # remember current path
	$path[-1] = $tag;                         # replace last item
	
	# otherwise, we're done with a subtree and need to restore context of parent
      } else {
	push @paths,[@path];                  # remember current path
	@path = ();                           # nuke path
	while (@path_stack) {
	  my $s = pop @path_stack;            # pop off an earlier partial path
	  if ($s->[0] == $position) {         # found correct context to restore
	    @path = @{$s->[1]};               # restore
	    last;
	  }
	}
	$path[-1] = $tag;                # replace sibling
      }
      
      $current_position = $position;
    }
  }
  push @paths,[@path] if @path;
  
  # at this point, @paths contains a list of paths to each terminal tag
  foreach (@paths) {
    my $tag = pop @{$_};
    $self->{path}{lc($tag)} = $_;
  }
}

sub _untabulate {
  my $self = shift;
  my @lines = split "\n",$self->{raw};
  return expand(@lines);
}

# return true if the tag is a valid one
sub valid_tag {
  my $self = shift;
  my $tag = lc shift;
  return $self->tags->{$tag};
}

# just return the model as a string
sub asString {
  return shift()->{'raw'};
}

1;

__END__

=head1 NAME

Ace::Model - Get information about AceDB models

=head1 SYNOPSIS

  use Ace;
  my $db = Ace->connect(-path=>'/usr/local/acedb/elegans');
  my $model = $db->model('Author');
  print $model;
  $name = $model->name;
  @tags = $model->tags;
  print "Paper is a valid tag" if $model->valid_tag('Paper');

=head1 DESCRIPTION

This class is provided for access to AceDB class models.  It provides
the model in human-readable form, and does some limited but useful
parsing on your behalf.  

Ace::Model objects are obtained either by calling an Ace database
handle's model() method to retrieve the model of a named class, or by
calling an Ace::Object's model() method to retrieve the object's
particular model.

=head1 METHODS

=head2 new()

  $model = Ace::Model->new($model_data);

This is a constructor intended only for use by Ace and Ace::Object
classes.  It constructs a new Ace::Model object from the raw string
data in models.wrm.

=head2 name()

  $name = $model->name;

This returns the class name for the model.

=head2 tags()

   @tags = $model->tags;

This returns a list of all the valid tags in the model.

=head2 valid_tag()

   $boolean  = $model->valid_tag($tag);

This returns true if the given tag is part of the model.

=head2 path()
   
   @path = $model->path($tag)

Returns the path to the indicated tag, returning a list of intermediate tags.
For example, in the C elegans ?Locus model, the path for 'Compelementation_data"
will return the list ('Type','Gene').

=head2 asString()

   print $model->asString;

asString() returns the human-readable representation of the model with
comments stripped out.  Internally this method is called to
automatically convert the model into a string when appropriate.  You
need only to start performing string operations on the model object in
order to convert it into a string automatically:

   print "Paper is unique" if $model=~/Paper ?Paper UNIQUE/;

=head1 SEE ALSO

L<Ace>

=head1 AUTHOR

Lincoln Stein <lstein@w3.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1997-1998, Lincoln D. Stein

This library is free software; 
you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut


