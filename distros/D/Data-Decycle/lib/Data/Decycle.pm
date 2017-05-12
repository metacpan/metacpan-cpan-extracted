#
# $Id: Decycle.pm,v 0.2 2010/08/23 09:11:03 dankogai Exp dankogai $
#
package Data::Decycle;
use 5.008001;
use warnings;
use strict;
use Carp;
use Scalar::Util qw/refaddr weaken isweak/;

our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
our $DEBUG = 0;

use base 'Exporter';
our @EXPORT    = ();
our @EXPORT_OK = qw(recsub $CALLEE
  may_leak has_cyclic_ref decycle_deeply weaken_deeply
);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ], );

BEGIN {
    require constant;
    constant->import(
        HAS_PADWALKER => eval {
            require PadWalker;
            $PadWalker::VERSION >= 1.0;
        }
    );
}

sub new {
    my $class = shift;
    my $self = bless [], $class;
    $self->add(@_);
}

sub add {
    my $self = shift;
    for (@_){
	croak "$_ is not a reference" unless ref $_;
	push @{$self}, $_;
    }
    $self;
}

sub DESTROY {
    my $self = shift;
    if ($DEBUG > 1){
	require Data::Dumper and Data::Dumper->import;
	print Dumper($self);
    }
    for (@{$self}){
	next unless ref $_;
	carp "decyling ($_)" if $DEBUG;
	decycle_deeply($_);
    }
}

our $CALLEE;

sub recsub(&) {
    my $code = shift;
    sub {
        local *CALLEE = \$code;
        $code->(@_);
    }
}

sub _mkfinder(&) {
    my $cb = shift;
    return recsub {
        return unless ref $_[0];
        no warnings 'uninitialized';
        return $cb->( $_[0] ) if $_[1]->{ refaddr $_[0] }++;
        if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
            for ( values %{ $_[0] } ) {
                next unless ref $_;
                return 1 if $CALLEE->( $_, $_[1] );
            }
        }
        elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            for ( @{ $_[0] } ) {
                next unless ref $_;
                return 1 if $CALLEE->( $_, $_[1] );
            }
        }
        elsif (UNIVERSAL::isa( $_[0], 'SCALAR' )
            || UNIVERSAL::isa( $_[0], 'REF' ) )
        {
            return $CALLEE->( ${ $_[0] }, $_[1] );
        }
        elsif ( HAS_PADWALKER && UNIVERSAL::isa( $_[0], 'CODE' ) ) {
            my $r = PadWalker::closed_over( $_[0] );
            return unless keys %$r;
            $CALLEE->( $r, $_[1] ) && return 1;
        }
        return;
    }
}

*_has_cyclic_ref = _mkfinder { 1 };
sub has_cyclic_ref($){ _has_cyclic_ref($_[0], {}) }

*_may_leak = _mkfinder { !isweak($_[0]) };
sub may_leak($){ _may_leak($_[0], {}) }

sub _mkwalker(&){
    my $cb = shift;
    return recsub {
        return unless ref $_[0];
        no warnings 'uninitialized';
        return $cb->( $_[0] ) if $_[1]->{ refaddr $_[0] }++;
        if ( UNIVERSAL::isa( $_[0], 'HASH' ) ) {
            $CALLEE->( $_, $_[1] ) for values %{ $_[0] };
        }
        elsif ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            $CALLEE->( $_, $_[1] ) for @{ $_[0] };
        }
        elsif (UNIVERSAL::isa( $_[0], 'SCALAR' )
            || UNIVERSAL::isa( $_[0], 'REF' ) )
        {
            $CALLEE->( ${ $_[0] }, $_[1] );
        }
        elsif ( HAS_PADWALKER && UNIVERSAL::isa( $_[0], 'CODE' ) ) {
            my $r = PadWalker::closed_over( $_[0] );
            return unless keys %$r;
            $CALLEE->( $r, $_[1] );
        }
        return;
    };
}

*_decycle_deeply = _mkwalker { undef $_[0] };
sub decycle_deeply($) { _decycle_deeply( $_[0], {} ) }

*_weaken_deeply = _mkwalker {
    weaken $_[0] unless UNIVERSAL::isa( $_[0], 'CODE' )
};
sub weaken_deeply($) { _weaken_deeply( $_[0], {} ) }

1; # End of Data::Decycle

__END__
=head1 NAME

Data::Decycle - (Cyclic|Circular) reference decycler

=head1 VERSION

$Id: Decycle.pm,v 0.2 2010/08/23 09:11:03 dankogai Exp dankogai $

=head1 SYNOPSIS

  use Data::Decycle;

  # none of them leak
  {
      my $guard = Data::Decycle->new;
      add $guard my $cyclic_sref = \my $dummy;
      $cyclic_sref = \$cyclic_sref;
      add $guard my $cyclic_aref = [];
      $cyclic_aref->[0] = $cyclic_aref;
      add $guard my $cyclic_href = {};
      $cyclic_href->{cyclic} = $cyclic_href;
  }

  # or register all at once
  {
      my $guard = Data::Decycle->new(
        my $cyclic_sref = \my $dummy,
        my $cyclic_aref = [],
        my $cyclic_href = {}
      );
      $cyclic_sref = \$cyclic_sref;
      $cyclic_aref->[0] = $cyclic_aref;
      $cyclic_href->{cyclic} = $cyclic_href;
  }

=head2 Code Reference and PadWalker

If you have PadWalker, you can decycle closures, too.

  {
      my $guard = Data::Decycle->new;
      my $cref;
      $cref = sub{ $_[0] <= 1 ? 1 : $_[0] * $cref->($_[0] - 1) };
      $guard->add($cref);
      print $cref->(10);
  }

=head2 Functional Interface

You can also cope with circular references explicitly

  use Data::Decycle ':all';
  my $obj = bless {}, 'Dummy';
  $obj->{me} = $obj;
  print may_leak($obj);       # true
  weaken_deeply($obj);
  print may_leak($obj);       # false
  print has_cyclic_ref($obj); # true
  decycle_deeply($obj);
  print $obj->{me} == undef;  # true

=head2 as a base class

You can also use it as a base class.

  {
    package Dummy;
    use base 'Data::Decycle';
    sub new { bless $_[1], $_[0] }
    sub DESTROY { warn "($_[0])" }
  }
  {
    my $mom = Dummy->new( {} );
    my $son = Dummy->new( {} );
    say "($mom) has cyclic ref ? ", $mom->has_cyclic_ref ? 'yes' : 'no';
    say "($son) may leak ? ",       $son->may_leak?        'yes' : 'no';
    $mom->{son} = $son;
    $son->{mom} = $mom;
    say "($mom) has cyclic ref ? ", $mom->has_cyclic_ref ? 'yes' : 'no';
    say "($son) may leak ? ",       $son->may_leak?        'yes' : 'no';
    $mom->weaken_deeply;
    $son->weaken_deeply;
    say "($mom) has cyclic ref ? ", $mom->has_cyclic_ref ? 'yes' : 'no';
    say "($son) may leak ? ",       $son->may_leak?        'yes' : 'no';
  }


=head1 DESCRIPTION

Perl programmers love to hate cyclic References, or circular
references.  It easly leaks out of perl's reference-counter based
garbage collection and stays there until perl exits.

Even with the introduction of weak references in Perl 5.8, you still
have to tell perl explicitly to weaken references and which reference
to weaken is tricky.

  use Devel::Peek;
  use Scalar::Util qw/weaken/;
  my $obj = {you => $ENV{USER}};
  $obj->{me} = $obj;

  weaken($obj);      # wrong
  weaken($obj->{me}) # right;

In addition to that, weak references do not work with code references.

  my $cref;
  $cref = sub { $_[0] <= 1 ? 1 : $_[0] * $cref->( $_[0] - 1 ) };
  print $cref->(10);
  weaken($cref);     # does undef($cref)
  print $cref->(10); # goodbye

This module offers something easier than that.

=head2 HOW DOES IT WORK?

See the source :-p

Okay, I'll be nicer.  Consider the code below again.

  {
      my $guard = Data::Decycle->new(
        my $cyclic_sref = \my $dummy,
        my $cyclic_aref = [],
        my $cyclic_href = {}
      );
      $cyclic_sref = \$cyclic_sref;
      $cyclic_aref->[0] = $cyclic_aref;
      $cyclic_href->{cyclic} = $cyclic_href;
  }

What happens when it reaches out of the block?  $guard will surely be
DESTROY()'ed.  So it is guaranteed to trigger $guard->DESTROY.  And in
there it applys C<decycle_deeply> to each reference registered.

Simple, huh?

=head1 DEPENDENCY

None except for core modules.

To handle code references correctly, you need to have L<PadWalker> installed.

=head1 EXPORT

None by default.  Please import explicitly.

=head1 METHODS

=over 4

=item new

=item add

see L</SYNOPSIS>

=back

=head1 SUBROUTINES

=head2 may_leak($obj)

checks if C<$obj> may leak.  That is, contains a circular reference
that is not weak.

=head2 has_cyclic_ref($obj)

checks if cyclic reference exists in C<$obj>.

=head2 decycle_deeply($obj)

C<undef>s all duplicate references in C<$obj> thus breaks all cyclic
reference.  Unlike C<weaken_deeply>, it decycles even code
references.  You shouldn't call it yourself; let C<decycle> take care
of it.

=head2 weaken_deeply($obj)

weaken all duplicate references in C<$obj>.  Unlike C<decycle_deeply>
it leaves code references intact.  So you can safely call it but you
are at your own if C<$obj> contains a code reference that cycles.

=head2 recsub { }

Consider the code below:

  my $fact;
  $fact = sub { $_[0] <= 1 ? 1 : $_[0] * $fact->($_[0]-1) };

This leaks since $fact is now a cyclic reference.
with the combination of C<recsub> and C<$CALLEE>, you can rewrite the code as:

  my $fact = recsub { $_[0] <= 1 ? 1 : $_[0] * $CALLEE->($_[0]-1) };

To use this feature, you should import both C<recsub> and C<$CALLEE> as:

  use Data::Decycle qw(recsub $CALLEE);

or import just C<recsub> and define your own C<$CALLEE>:

  use Data::Decycle qw(recsub);
  our $CALLEE;

Unlike the previous example, this one dow not leak.  See
L<Sub::Recursive> for more complicated examples such as mutually
recursive subrefs.

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-decycle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Decycle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Decycle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Decycle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Decycle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Decycle>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Decycle/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item L<PadWalker>

You need this if you want to handle code references properly.  When
you don't have one this module simply does nothing when it encounters
them.

=item L<Devel::Cycle>

Good for inspection -- rather overkill.  Decycling features missing.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Dan Kogai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
