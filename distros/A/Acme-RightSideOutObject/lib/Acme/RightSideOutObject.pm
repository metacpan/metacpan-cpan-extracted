package Acme::RightSideOutObject;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.01';

# todo:
# o. recognize different inside-out object systems and handle them appropriately (eg, C::IO uses id($self) for a hash subscript)
# o. weaken?

use strict; no strict 'refs';
use warnings;

use Data::Alias;
use PadWalker;
use B;
use Scalar::Util;

sub import {
    *{caller().'::guts'} = sub {
        my $their_self = shift;
        my $weaken = grep $_ eq 'weaken', @_;
        my $debug = grep $_ eq 'debug', @_;
        my $id = Class::InsideOut::id($their_self) or die;
        my $class = ref $their_self;
        my %as_a_hash;
        my $self = bless \%as_a_hash, $class;
        my $our_id = Class::InsideOut::id($self) or die; # sooo bad
        for my $sym (keys %{$class.'::'}) {
            $debug and warn "$class\::$sym\n";
            my $code = *{$class.'::'.$sym}{CODE} or next;
            my $op = B::svref_2object($code) or next;
            my $rootop = $op->ROOT or next;
            $$rootop or next; # not XS
            $op->STASH->NAME eq $class or next; # not imported
            my $vars = PadWalker::peek_sub($code) or next; # don't know why this would fail but when it does, I think it dies
            for my $var (keys %$vars) {
                next unless $var =~ m/^\%/;
                next unless exists $vars->{$var};
                next unless exists $vars->{$var}->{$id};
                $debug and warn "  ... $var is $vars->{$var}->{$id}\n";
                (my $var_without_sigil) = $var =~ m/^.(.*)/;
                alias $as_a_hash{$var_without_sigil} = $vars->{$var}->{$id};
                alias $vars->{$var}->{$our_id} = $vars->{$var}->{$id}; # so $self->func works as well as $their_self->func
                if($weaken) {
                    Scalar::Util::weaken($as_a_hash{$var_without_sigil});
                    Scalar::Util::weaken($vars->{$var}->{$our_id});
                }
            }
        }
        $self;
    };
}

1;

__END__

=head1 NAME

Acme::RightSideOutObject - Turn Class::InsideOut objects back right side out

=head1 SYNOPSIS

  use Acme::RightSideOutObject;

  use My::Class;
  # My::Class comes from the L<Class::InsideOut> SYNOPSIS

  my $inside_out = My::Class->new or die; 
  $inside_out->name("Fred");
  print $inside_out->greeting(), "\n"; # prints Hello, my name is Fred

  my $rightside_out = guts($inside_out);
  print '$rightside_out->{name} = ', $rightside_out->{name}, "\n"; # direct hash read
  $rightside_out->{name} = 'Dork Face';        # direct hash write
  print $inside_out->greeting(), "\n";         # prints Hello, my name is Dork Face
  print $rightside_out->greeting(), "\n";      # prints Hello, my name is Dork Face

=head1 DESCRIPTION

Exports C<guts()> which takes a L<Class::InsideOut> object and returns a normal
blessed hashref object.

One of the most serious flaws of Class::InsideOut is that it encapsulates data,
making it difficult to directly minipulate the object's internal state.
Attempting to inspect the reference to an inside out object with
L<Data::Dumper>, you'll find this:

    $VAR1 = bless( do{\(my $o = undef)}, 'My::Class' );

Fear not!  Acme::RightSideOutObject to the rescue!

Acme::RightSideOutObject work exactly like the inside out object it replaces
except that it is also a hashref full of the object's instance data.
Methods may be called on it.

Options are available, mix and match style:

  use Acme::RightSideOutObject 'weaken';

Attempt not to leak so much memory. 

  use Acme::RightSideOutObject 'debug';

Print information to STDERR about instance data found while righting objects.

=head2 EXPORT

C<< guts() >>

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -A -C -X -b 5.8.0 -c -n Acme::RightSideOutObject

=back


=head1 BUGS

Leaks memory.

Can't subclass inside out objects with right side out code (but obviously has-a style delegation works).

Should support other flavors of inside out objects than just Class::InsideOut.

Doesn't use the exporter.

The inside out object and the per-attribute hashes continue to exist; this only creates a fascade.
With some L<B> hackery, we could actually rewrite the code of inside out objects to be right side out
and utter destroy the previous inside out-edness.

=head1 SEE ALSO

=over 8

=item L<Class::InsideOut>

=item L<autobox::Closure::Attributes>

=item L<Data::Alias>

=back


=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>, at the suggestion of Jonathan Rockway, E<lt>jrockway@cpan.orgE<gt>.
The real magic is done by L<Data::Alias>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
