package Ace::Graphics::Fk;

use strict;
*stop        = \&end;
*primary_tag = \&name;
*exons       = \&segments;

# usage:
# Ace::Graphics::Fk->new(
#                         -start => 1,
#                         -end   => 100,
#                         -name  => 'fred feature',
#                         -info  => $additional_stuff_to_store,
#                         -strand => +1);
#
# Alternatively, use -segments => [ [start,stop],[start,stop]...]
# to create a multisegmented feature.
sub new {
  my $class= shift;
  my %arg = @_;

  my $self = bless {},$class;

  $arg{-strand} ||= 0;
  $self->{strand} = $arg{-strand} >= 0 ? +1 : -1;
  $self->{name}   = $arg{-name};
  $self->{info}   = $arg{-info};

  if (my $s = $arg{-segments}) {

    my @segments;
    for my $seg (@$s) {
      if (ref($seg) eq 'ARRAY') {
	push @segments,$class->new(-start=>$seg->[0],
				   -stop=>$seg->[1],
				   -strand=>$self->{strand});
      } else {
	push @segments,$seg;
      }
    }

    $self->{segments} = [ sort {$a->start <=> $b->start } @segments ];

  } else {
    $self->{start} = $arg{-start};
    $self->{end}   = $arg{-end} || $arg{-stop};
  }

  $self;
}

sub segments {
  my $self = shift;
  my $s = $self->{segments} or return;
  @$s;
}
sub strand   { shift->{strand}      }
sub name     { shift->{name}        }
sub start    {
  my $self = shift;
  if (my @segments = $self->segments) {
    return $segments[0]->start;
  }
  return $self->{start};
}
sub end    {
  my $self = shift;
  if (my @segments = $self->segments) {
    return $segments[-1]->end;
  }
  return $self->{end};
}
sub length {
  my $self = shift;
  return $self->end - $self->start + 1;
}
sub introns {
  my $self = shift;
  return;
}
sub source_tag { 'dummy' }
sub target { }
sub info {
  my $self = shift;
  return $self->{info} || $self->name;
}

1;

__END__

=head1 NAME

Ace::Graphics::Fk - A dummy feature object used for generating panel key tracks

=head1 SYNOPSIS

None.  Used internally by Ace::Graphics::Panel.

=head1 DESCRIPTION

None.  Used internally by Ace::Graphics::Panel.

=head1 SEE ALSO

L<Ace::Sequence>,L<Ace::Sequence::Feature>,
L<Ace::Graphics::Track>,L<Ace::Graphics::Glyph>,
L<GD>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
