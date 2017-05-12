package Ace::Sequence::Multi;
use strict;

use Carp;
use strict;
use Ace 1.50 qw(:DEFAULT rearrange);
use Ace::Sequence;

use vars '@ISA';
@ISA = 'Ace::Sequence';

# backward compatibility
*db_id = \&db;

sub new {
  my $pack = shift;
  my ($secondary,$rest) = rearrange([['SECONDARY','DBS']],@_);
  return unless my $obj = $pack->SUPER::new($rest);

  if (defined $secondary) {
    my @s = ref $secondary eq 'ARRAY' ? @$secondary : $secondary;
    $obj->{'secondary'} = { map { $_=> $_} @s };
  }

  return bless $obj,$pack;
}

sub secondary {
  return unless my $s = $_[0]->{'secondary'};
  return values %{$s};
}

sub add_secondary {
  my $self = shift;
  foreach (@_) {
    $self->{'secondary'}->{$_}=$_;
  }
}

sub delete_secondary {
  my $self = shift;
  foreach (@_) {
    delete $self->{'secondary'}->{$_};
  }
}

sub db {
  return $_[0]->SUPER::db() unless $_[1];
  return $_[0]->{'secondary'}->{$_[1]} || $_[0]->SUPER::db();
}

# return list of features quickly
sub feature_list {
  my $self = shift;
  return $self->{'feature_list'} if $self->{'feature_list'};
  my $raw;

  for my $db ($self->db,$self->secondary) {
    $raw .= $self->_query($db,'seqfeatures -version 2 -list');
    $raw .= "\n";  # avoid nulls
  }

  return $self->{'feature_list'} = Ace::Sequence::FeatureList->new($raw);
}

# return a unified gff file
sub gff {
  my $self = shift;
  my ($abs,$features) = rearrange([['ABS','ABSOLUTE'],'FEATURES'],@_);
  my   $db = $self->db;

  my $gff = $self->SUPER::gff(-Abs=>$abs,-Features=>$features,-Db=>$db);
  return unless $gff;
  return $gff unless $self->secondary;

  my(%seen,@lines);

  foreach (grep !$seen{$_}++,split("\n",$gff)) {  #ignore duplicates
    next if m!^//!;  # ignore comments
    push @lines,/^\#/ ? $_ : join "\t",$_,$db;
  }

  my $opt = $self->_feature_filter($features);

  for my $db ($self->secondary) {
    my $supplement = $self->_gff($opt,$db);
    $self->transformGFF(\$supplement) unless $abs;

    my $string = $db->asString;

    foreach (grep !$seen{$_}++,split("\n",$supplement)) {  #ignore duplicates
      next if m!^(//|\#)!;  # ignore comments
      push(@lines, join "\t",$_,$string);   # add database as an eighth field
    }
  }

  return join("\n",@lines,'');
}

# turn a GFF file and a filter into a list of Ace::Sequence::Feature objects
sub _make_features {
  my $self = shift;
  my ($gff,$filter) = @_;

  my @dbs = ($self->db,$self->secondary);
  my %dbs = map { $_->asString => $_ } @dbs;

  my ($r,$r_offset,$r_strand) = $self->refseq;
  my $abs = $self->absolute;
  if ($abs) {
    $r_offset  = 0;
    $r = $self->parent;
    $r_strand = '+1';
  }
  my @features;
  foreach (split("\n",$gff)) {
    next if m[^(?:\#|//)];
    next unless $filter->($_);
    next unless my ($dbname) = /\t(\S+)$/;
    next unless my $db = $dbs{$dbname};
    next unless my $parent = $self->parent;
    push @features,Ace::Sequence::Feature->new($parent,$r,$r_offset,$r_strand,$abs,$_,$db);
  }

  return @features;
}

1;

__END__

=head1 NAME

Ace::Sequence::Multi - Combine Feature Tables from Multiple Databases

=head1 SYNOPSIS

    use Ace::Sequence::Multi;

    # open reference database
    $ref = Ace->connect(-host=>'stein.cshl.org',-port=>200009);

    # open some secondary databases
    $db1 = Ace->connect(-host=>'stein.cshl.org',-port=>200010);
    $db2 = Ace->connect(-path=>'/usr/local/acedb/mydata');

    # Make an Ace::Sequence::Multi object
    $seq = Ace::Sequence::Multi->new(-name   => 'CHROMOSOME_I,
                                     -db     => $ref,
			             -offset => 3_000_000,
			             -length => 1_000_000);

    # add the secondary databases
    $seq->add_secondary($db1,$db2);

    # get all the homologies (a list of Ace::Sequence::Feature objs)
    @homol = $seq->features('Similarity');

    # Get information about the first one -- goes to the correct db
    $feature = $homol[0];
    $type    = $feature->type;
    $subtype = $feature->subtype;
    $start   = $feature->start;
    $end     = $feature->end;
    $score   = $feature->score;

    # Follow the target
    $target  = $feature->info;

    # print the target's start and end positions
    print $target->start,'-',$target->end, "\n";

=head1 DESCRIPTION

I<Ace::Sequence::Multi> transparently combines information stored
about a sequence in a reference database with features tables from any 
number of annotation databases.  The resulting object can be used just 
like an Ace::Sequence object, except that the features remember their
database of origin and go back to that database for information.

This class will only work properly if the reference database and all
annotation databases share the same cosmid map.

=head1  OBJECT CREATION

You will use the new() method to create new Ace::Sequence::Multi
objects.  The arguments are identical to the those in the
Ace::Sequence parent class, with the addition of an option
B<-secondary> argument, which points to one or more secondary databases 
from which to fetch annotation information.

=over 4

=item -source

The sequence source.  This must be an I<Ace::Object> of the "Sequence" 
class, or be a sequence-like object containing the SMap tag (see
below).

=item -offset

An offset from the beginning of the source sequence.  The retrieved
I<Ace::Sequence> will begin at this position.  The offset can be any
positive or negative integer.  Offets are B<0-based>.

=item -length

The length of the sequence to return.  Either a positive or negative
integer can be specified.  If a negative length is given, the returned 
sequence will be complemented relative to the source sequence.

=item -refseq

The sequence to use to establish the coordinate system for the
returned sequence.  Normally the source sequence is used to establish
the coordinate system, but this can be used to override that choice.
You can provide either an I<Ace::Object> or just a sequence name for
this argument.  The source and reference sequences must share a common
ancestor, but do not have to be directly related.  An attempt to use a
disjunct reference sequence, such as one on a different chromosome,
will fail.

=item -name

As an alternative to using an I<Ace::Object> with the B<-source>
argument, you may specify a source sequence using B<-name> and B<-db>.
The I<Ace::Sequence> module will use the provided database accessor to
fetch a Sequence object with the specified name. new() will return
undef is no Sequence by this name is known.

=item -db

This argument is required if the source sequence is specified by name
rather than by object reference.  It must be a previously opened
handle to the reference database.

=item -secondary

This argument points to one or more previously-opened annotation
databases.  You may use a scalar if there is only one annotation
database.  Otherwise, use an array reference.  You may add and delete
annotation databases after the object is created by using the
add_secondary() and delete_secondary() methods.

=back

If new() is successful, it will create an I<Ace::Sequence::Multi>
object and return it.  Otherwise it will return undef and return a
descriptive message in Ace->error().  Certain programming errors, such
as a failure to provide required arguments, cause a fatal error.


=head1 OBJECT METHODS

Most methods are inherited from I<Ace::Sequence>.  The following
additional methods are supported:

=over 4

=item secondary()

  @databases = $seq->secondary;

Return a list of the secondary databases currently in use, or an empty 
list if none.

=item add_secondary()

  $seq->add_secondary($db1,$db2,...)

Add one or more secondary databases to the list of annotation
databases.  Duplicate databases will be silently ignored.

=item delete_secondary()

  $seq->delete_secondary($db1,$db2,...)

Delete one or more secondary databases from the list of annotation
databases.  Databases not already in use will be silently ignored.

=back

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Sequence>,L<Ace::Sequence::Homol>,
L<Ace::Sequence::FeatureList>, L<Ace::Sequence::Feature>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@w3.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut


