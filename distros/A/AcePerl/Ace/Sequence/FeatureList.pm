package Ace::Sequence::FeatureList;

use overload '""' => 'asString';

sub new {
  local $^W = 0;  # to prevent untrackable uninitialized variable warning
  my $package =shift;
  my @lines = split("\n",$_[0]);
  my (%parsed);
  foreach (@lines) {
    next if m!^//!;
    my ($minor,$major,$count) = split "\t";
    next unless $count > 0;
    $parsed{$major}{$minor} += $count;
    $parsed{_TOTAL} += $count;
  }
  return bless \%parsed,$package;
}

# no arguments, scalar context -- count all features
# no arguments, array context  -- list of major types
# 1 argument, scalar context   -- count of major type
# 1 argument, array context    -- list of minor types
# 2 arguments                  -- count of subtype
sub types {
  my $self = shift;
  my ($type,$subtype) = @_;
  my $count = 0;

  unless ($type) {
    return wantarray ? grep !/^_/,keys %$self : $self->{_TOTAL};
  }

  unless ($subtype) {
    return keys %{$self->{$type}} if wantarray;
    foreach (keys %{$self->{$type}}) {
      $count += $self->{$type}{$_};
    }
    return $count;
  }
  
  return $self->{$type}{$subtype};
}

# human-readable summary table
sub asString {
  my $self = shift;
  my ($type,$subtype);
  for my $type ( sort $self->types() ) {
    for my $subtype (sort $self->types($type) ) {
      print join("\t",$type,$subtype,$self->{$type}{$subtype}),"\n";
    }
  }
}

1;

=head1 NAME

Ace::Sequence::FeatureList - Lightweight Access to Features

=head1 SYNOPSIS

    # get a megabase from the middle of chromosome I
    $seq = Ace::Sequence->new(-name   => 'CHROMOSOME_I,
                              -db     => $db,
			      -offset => 3_000_000,
			      -length => 1_000_000);

    # find out what's there
    $list = $seq->feature_list;

    # Scalar context: count all the features
    $feature_count = $list->types;

    # Array context: list all the feature types
    @feature_types = $list->types;

    # Scalar context, 1 argument.  Count this type
    $gene_cnt = $list->types('Predicted_gene');
    print "There are $gene_cnt genes here.\n";

    # Array context, 1 argument.  Get list of subtypes
    @subtypes = $list->types('Predicted_gene');

    # Two arguments. Count type & subtype
    $genefinder_cnt = $list->types('Predicted_gene','genefinder');

=head1 DESCRIPTION

I<Ace::Sequence::FeatureList> is a small class that provides
statistical information about sequence features.  From it you can
obtain summary counts of the features and their types within a
selected region.

=head1 OBJECT CREATION

You will not ordinarily create an I<Ace::Sequence::FeatureList> object
directly.  Instead, objects will be created by calling a
I<Ace::Sequence> object's feature_list() method.  If you wish to
create an I<Ace::Sequence::FeatureList> object directly, please consult
the source code for the I<new()> method.

=head1 OBJECT METHODS

There are only two methods in I<Ace::Sequence::FeatureList>.

=over 4

=item type()

This method has five distinct behaviors, depending on its context and
the number of parameters.  Usage should be intuitive

 Context       Arguments       Behavior
 -------       ---------       --------

 scalar         -none-         total count of features in list
 array          -none-         list feature types (e.g. "exon")
 scalar          type          count features of this type
 array           type          list subtypes of this type
 -any-       type,subtype      count features of this type & subtype

For example, this code fragment will count the number of exons present
on the list:

  $exon_count = $list->type('exon');

This code fragment will count the number of exons found by "genefinder":

  $predicted_exon_count = $list->type('exon','genefinder');

This code fragment will print out all subtypes of "exon" and their
counts: 

  for my $subtype ($list->type('exon')) {
      print $subtype,"\t",$list->type('exon',$subtype),"\n";
  }

=item asString()

  print $list->asString;

This dumps the list out in tab-delimited format.  The order of columns
is type, subtype, count.

=back

=head1 SEE ALSO

L<Ace>, L<Ace::Object>, L<Ace::Sequence>,
L<Ace::Sequence::Feature>, L<GFF>

=head1 AUTHOR

Lincoln Stein <lstein@w3.org> with extensive help from Jean
Thierry-Mieg <mieg@kaa.crbm.cnrs-mop.fr>

Copyright (c) 1999, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

