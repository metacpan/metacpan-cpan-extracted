package Data::Lock;
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

use Attribute::Handlers;
use Scalar::Util ();

use base 'Exporter';
our @EXPORT_OK = qw/dlock dunlock/;

#my @builtin_types = 
#    qw/SCALAR ARRAY HASH CODE REF GLOB LVALUE FORMAT IO VSTRING Regexp/;

for my $locked ( 0, 1 ) {
    my $subname = $locked ? 'dlock' : 'dunlock';
    no strict 'refs';
    *{$subname} = sub {
        no warnings "uninitialized";
        return if $_[1] and Internals::SvREADONLY( $_[0]) == $locked;
        Internals::SvREADONLY( $_[0], $locked );
        return unless my $type = Scalar::Util::reftype( $_[0] );
        for (
              $type eq 'ARRAY' ? @{ $_[0] }
            : $type eq 'HASH'  ? values %{ $_[0] }
            : $type ne 'CODE'  ? ${ $_[0] }
            :                    ()
          )
        {
            &$subname($_, 1) if ref $_;
            Internals::SvREADONLY( $_, $locked );
        }
            $type eq 'ARRAY' ? Internals::SvREADONLY( @{ $_[0] }, $locked )
          : $type eq 'HASH'  ? Internals::SvREADONLY( %{ $_[0] }, $locked )
          : $type ne 'CODE'  ? Internals::SvREADONLY( ${ $_[0] }, $locked )
          :                    undef;
    };
}

1;
__END__

=head1 NAME

Data::Lock - makes variables (im)?mutable

=head1 VERSION

$Id: Lock.pm,v 1.3 2014/03/07 18:24:43 dankogai Exp dankogai $

=head1 SYNOPSIS

   use Data::Lock qw/dlock dunlock/;

   dlock my $sv = $initial_value;
   dlock my $ar = [@values];
   dlock my $hr = { key => value, key => value, ... };
   dunlock $sv;
   dunlock $ar; dunlock \@av;
   dunlock $hr; dunlock \%hv;

=head1 DESCRIPTION

C<dlock> makes the specified variable immutable like L<Readonly>.
Unlike L<Readonly> which implements immutability via C<tie>, C<dlock>
makes use of the internal flag of perl SV so it imposes almost no
penalty.

Like L<Readonly>, C<dlock> locks not only the variable itself but also
elements therein.

As of verion 0.03, you can C<dlock> objects as well.  Below is an
example constructor that returns an immutable object:

  sub new {
      my $pkg = shift;
      my $self = { @_ };
      bless $self, $pkg;
      dlock($self);
      $self;
  }

Or consider using L<Moose>.

=head1 EXPORT

Like L<List::Util> and L<Scalar::Util>, functions are exported only
explicitly. This module comes with C<dlock> and C<dunlock>.

  use Data::Lock;                   # nothing imported;
  use Data::Lock qw/dlock dunlock/; # imports dlock() and dunlock()

=head1 FUNCTIONS

=head2 dlock

  dlock($scalar);

Locks $scalar and if $scalar is a reference, recursively locks referents.

=head2 dunlock

Does the opposite of C<dlock>.

=head1 BENCHMARK

Here I have benchmarked like this.

  1.  Create an immutable variable.
  2.  try to change it and see if it raises exception
  3.  make sure the value stored remains unchanged.

See F<t/benchmark.pl> for details.

=over 2

=item Simple scalar

                Rate  Readonly Attribute      glob     dlock
  Readonly   11987/s        --      -98%      -98%      -98%
  Attribute 484562/s     3943%        --       -1%       -4%
  glob      487239/s     3965%        1%        --       -3%
  dlock     504247/s     4107%        4%        3%        --

=item Array with 1000 entries

                Rate  Readonly     dlock Attribute
  Readonly   12396/s        --      -97%      -97%
  dlock     444703/s     3488%        --       -6%
  Attribute 475557/s     3736%        7%        --

=item Hash with 1000 key/value pairs

                Rate  Readonly     dlock Attribute
  Readonly   10855/s        --      -97%      -97%
  dlock     358867/s     3206%        --       -5%
  Attribute 377087/s     3374%        5%        --

=back

=head1 SEE ALSO

L<Readonly>, L<perlguts>, L<perlapi>

=head1 AUTHOR

Dan Kogai, C<< <dankogai+gmail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-lock at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Lock>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Lock

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Lock>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Lock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Lock>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Lock>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
