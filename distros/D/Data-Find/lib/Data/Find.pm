package Data::Find;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Scalar::Util qw( refaddr );

use base qw( Exporter );

our @EXPORT_OK = qw( diter dfind dwith );

=head1 NAME

Data::Find - Find data in arbitrary data structures

=head1 VERSION

This document describes Data::Find version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Data::Find qw( diter );

  my $data = {
    ar => [1, 2, 3],
    ha => {one => 1, two => 2, three => 3}
  };
  
  my $iter = diter $data, 3;
  while ( defined ( my $path = $iter->() ) ) {
    print "$path\n";
  }
  
=head1 DESCRIPTION

=head1 INTERFACE 

Nothing is exported by default. Use, eg,

  use Data::Find qw( dwith );

to get the subroutines you need or call them with their fully
qualified name:

  my $iter = Data::Find::diter $data;

=head2 C<< diter >>

Given an arbitrary data structure and (optionally) an expression to
match against elements in that structure returns an iterator which will
yield the path through the data structure to each matching element:

  my $data = {
    ar => [1, 2, 3],
    ha => {one => 1, two => 2, three => 3}
  };
  
  my $iter = diter $data, 3;
  while ( defined ( my $path = $iter->() ) ) {
    print "$path\n";
  }

would print:

  {ar}[2]
  {ha}{one}

In other words it returns paths to each element that contains the scalar
3. The returned paths can be used in conjunction with C<eval> to access
the matching elements.

The match expression can be

=over

=item * a scalar

=item * a regular expression

=item * a code reference

=item * C<undef>

=back

When the match expression is a code ref it will be passed each element
in the data structure in turn and should return true or false.

  my $iter = diter $data, sub {
    my $v = shift;
    defined $v && !ref $v && $v % 2 == 1;
  };

  while ( defined ( my $path = $iter->() ) ) {
    print "$path\n";
  }

Note that the match code will see I<all> of the elements in the data
structure - not just the scalars.

If the match expression is C<undef> it will match those elements whose
value is also C<undef>.

=head3 Iterator

In a scalar context the returned iterator yields successive paths
within the data structure. In an array context it returns the path and
the associated element.

  my $iter = diter $data;
  while ( my ( $path, $obj ) = $iter->() ) {
    print "$path, $obj\n";
  }

=cut

sub diter {
  my ( $obj, @match ) = @_;

  my $matcher = @match ? _mk_matcher( @match ) : sub { !ref shift };
  my @queue = ( [$obj] );
  my %seen = ();

  my %WALK = (
    HASH => sub {
      my ( $obj, @path ) = @_;
      for my $key ( sort keys %$obj ) {
        push @queue,
         [ $obj->{$key}, @path, '{' . _fmt_key( $key ) . '}' ];
      }
    },
    ARRAY => sub {
      my ( $obj, @path ) = @_;
      for my $idx ( 0 .. $#$obj ) {
        push @queue, [ $obj->[$idx], @path, "[$idx]" ];
      }
    }
  );

  return sub {
    while ( my $spec = shift @queue ) {
      my ( $obj, @path ) = @$spec;
      if ( my $ref = ref $obj ) {
        unless ( $seen{ refaddr $obj}++ ) {
          my $handler = $WALK{$ref} or croak "Can't walk a $ref";
          $handler->( $obj, @path );
        }
      }
      if ( $matcher->( $obj ) ) {
        my $path = join '', @path;
        return wantarray ? ( $path, $obj ) : $path;
      }
    }
    return;
  };
}

=head2 C<dfind>

Similar to C<diter> but returns an array of matching paths rather than
an iterator.

=cut

sub dfind {
  my $iter = diter @_;
  my @got  = ();
  while ( defined( my $path = $iter->() ) ) {
    push @got, $path;
  }
  return @got;
}

=head2 C<dwith>

Similar to C<diter> but call a supplied callback with each
matching path.

  dwith $data, qr/nice/, sub {
    my ( $path, $obj ) = @_;
    print "$path, $obj\n";
  };

=cut

sub dwith {
  my $cb   = pop @_;
  my $iter = diter @_;
  while ( my ( $path, $obj ) = $iter->() ) {
    $cb->( $path, $obj );
  }
  return;
}

sub _mk_matcher {
  my $match = shift;
  if ( ref $match ) {
    if ( 'CODE' eq ref $match ) {
      return $match;
    }
    elsif ( 'Regexp' eq ref $match ) {
      return sub {
        my $v = shift;
        return unless defined $v && !ref $v;
        return $v =~ $match;
      };
    }
  }

  if ( defined $match ) {
    return sub { shift eq $match };
  }

  return sub { !defined shift }
}

sub _fmt_key {
  my $key = shift;
  return $key if $key =~ /^(?:\d+|[a-z]\w*)$/i;
  chomp( my $rep
     = Data::Dumper->new( [$key] )->Purity( 1 )->Useqq( 1 )->Terse( 1 )
     ->Dump );
  return $rep;
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-find@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
