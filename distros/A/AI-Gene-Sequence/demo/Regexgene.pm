package Regexgene;
use strict;
use warnings;

=head1 NAME

  Regexgene - An example of a AI::Gene::Sequence

=head1 SYNOPSIS

This is a short module which illustrates the way to use the
AI::Gene::Sequence module.

 use Regexgene;
 $regex = Regexgene->new(5);
 print $regex->regex, "\n";
 $regex->mutate;
 print $regex->regex, "\n";
 $copy = $regex->clone;
 $copy->mutate;
 print $regex->regex, "\n", $copy->regex, "\n";

=head1 DESCRIPTION

The following is a code / pod mix, use the source.  A programme
using this module is available as C<spamscan.pl>.

=head1 The module code

=cut

=head2

First we need to be nice, do our exporting and versions, we
also need to tell perl that we want objects in this class
to inherit from AI::Gene::Sequence by placing it in
our @ISA array.

=cut

BEGIN {
  use Exporter   ();
  use AI::Gene::Sequence;
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION     = 0.01;
  @ISA         = qw(Exporter AI::Gene::Sequence);
  @EXPORT      = ();
  %EXPORT_TAGS = ();
  @EXPORT_OK   = qw();
}
our @EXPORT_OK;

=head2 Globals

We have a load of globals, these form the basis of our token types, anything
from the same array, is the same type eg.

 @modifiers = qw( * *? + +? ?? ); # are of type 'm' for modifier

=cut

our @modifiers  = qw( * *? + +? ?? );
our @char_types = qw( \w \W \d \D \s \S .);
our @ranges     = qw( [A-Z] [a-z] [0-9] );
our @chars      = ((0..9,'a'..'z','A'..'Z','_'),
                  (map '\\'.chr, 32..47, 58..64, 91..94, 96, 123..126));


=head2 Constructor

As we want to be able to fill our regular expression at the same
time as we create it and because we will want to nest sequences
we will need some way to know how deep we are, then a different
B<new> method is needed.

If called as an object method (C<$obj->new>), this decreases the depth
count by one from the invoking object.  It also adds tokens to the regular
expression and uses the B<valid_gene> method to ensure we stay sane 
from the start.

As can be seen, we use array offsets above $self->[1] to store information
which is specific to our implementation.

=cut

sub new {
  my $gene = ['',[], ref($_[0]) ? $_[0]->[2]-1 : 3 ]; # limit recursion
  bless $gene, ref($_[0]) || $_[0];
  my $length = $_[1] || 5;
  for (1..$length) {
    my @token = $gene->generate_token();
    my $new = $gene->[0] . $token[0];
    redo unless $gene->valid_gene($new); # hmmmm, enter turing from the wings
    $gene->[0] = $new;
    push @{$gene->[1]}, $token[1];
  }
  return $gene;
}

=head2 clone

As we are going to allow nested sequences, then we need to make sure that
when we copy an object we create new versions of everthing, rather than
reusing pointers to data used by other objects.

=cut

sub clone {
  my $self = shift;
  my $new = bless [$self->[0], [], $self->[2]], ref($self);
  @{$new->[1]} = map {ref($_) ? $_->clone : $_} @{$self->[1]}; # woohoo, recursive objects
  return $new;
}

=head2 generate_token

This is where we really start needing to have our own implementation.
This method is used by AI::Gene::Sequence when it needs a new
token, we also use it ourselves when we create a new object, but we
did not have to.

If we are provided with a token type, we use that, otherwise we chose
one at random.  We make sure that we return a two element list.
If we had wanted, when passed a type of 'g' along with a second
argument, we could have caused this method to mutate the nested
regex, instead, we just create a different one.

=cut

sub generate_token {
  my $self = shift;
  my $type = $_[0] || (qw(m t c r a g))[rand 6];
  my @rt;
  $rt[0] = $type;
 SWITCH: for ($type) {
    /^m/ && do {$rt[1] = $modifiers[rand@modifiers]  ;last SWITCH}; # modifier
    /^t/ && do {$rt[1] = $char_types[rand@char_types];last SWITCH}; # type
    /^c/ && do {$rt[1] = $chars[rand@chars]          ;last SWITCH}; # lone char
    /^r/ && do {$rt[1] = $ranges[rand@ranges]        ;last SWITCH}; # range
    /^a/ && do {$rt[1] = '|'                         ;last SWITCH}; # altern
    /^g/ && do {
      if ($self->[2] > 0) {  # recursion avoidance...
	$rt[1] = $self->new;
      }
      else {
	$rt[1] = $chars[rand@chars];
      }
      ;last SWITCH}; # grouping
    die "Unknown type of regex token ($type)";
  }
  return @rt[0,1];
}

# returns true if a valid regex, otherwise false, ignores optional posn arg

=head2 valid_gene

Because we have restricted ourselves to simple regular
expressions we only need to make sure that modifers and alternation
do not follow or precede things they should not.

Note that we do not use the current version of the gene in $self->[0].
This is because it is the un-mutated version, if we do not accept the
mutation then $self will be left alone by our calling methods.

That said, if you want to use $self->[0] then you can, but it would
be unwise to modify it here.

=cut

sub valid_gene {
  my $self = shift;
  my $gene = $_[0];
  if ($gene =~ /mm|am|aa|^a|^m|a$/) {
    return undef;
  }
  else {
    return 1;
  }
}

=head2

Having created a way to create, modify and verify our genetically
encoded regular expressions, we could do with some way to actually
use them.  This method retuns a non compiled regular expression and
calls itself recursively when it finds nested genes.

=cut

sub regex {
  my $self = shift;
  my $rt;
  warn "$0: empty gene turned into empty regex" unless scalar @{$self->[1]};
  foreach (@{$self->[1]}) {
    $rt .= ref($_) ? '(?:'. $_->regex .')' : $_;
  }
  return $rt;
}

=head1 AUTHOR

Alex Gough (F<alex@rcon.org>).

=head1 COPYRIGHT

Copyright (c) 2001 Alex Gough <F<alex@rcon.org>>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
__END__;
