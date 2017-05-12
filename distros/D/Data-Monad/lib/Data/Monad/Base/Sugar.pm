package Data::Monad::Base::Sugar;
use strict;
use warnings;
use Scalar::Util qw/blessed weaken/;
use Exporter qw/import/;

our @EXPORT = qw/pick satisfy yield let/;

our $_PICK = our $_SATISFY = 
    our $_YIELD = our $_LET = sub { die "called outside for()." };
sub pick($;$)  { $_PICK->(@_)    }
sub satisfy(&) { $_SATISFY->(@_) }
sub yield(&)   { $_YIELD->(@_)   }
sub let($$)    { $_LET->(@_)     }

sub _capture {
    my $ref = pop;

    return $ref->capture(@_) if blessed $ref && $ref->can('capture');

    ref $ref eq 'ARRAY' ? (@$ref = @_) : ($$ref = $_[0]);
}

sub _tuple { bless [@_], 'Data::Monad::Base::Sugar::Tuple' }
sub Data::Monad::Base::Sugar::Tuple::capture {
    my ($self, $result) = @_;
    blessed $result && $result->isa(ref $self)
                                            or die "[BUG]result is not tuple";

    _capture @{$result->[$_]} => $self->[$_] for 0 .. $#$self;
}

sub for(&) {
    my $code = shift;

    my @blocks;
    {
        local $_PICK = sub {
            my ($ref, $block) = @_;
            $block = $ref, $ref = undef unless defined $block;

            push @blocks, {ref => $ref, block => $block};
        };

        local $_YIELD = sub {
            my $block = shift;

            $blocks[$#blocks]->{yield} = $block;
        };

        local $_SATISFY = sub {
            my $predicate = shift;
            die "satisfy() should be called after pick()."
                                                          unless @blocks;

            my $slot = $#blocks;
            my $orig_block = $blocks[$slot]->{block};
            my $orig_ref   = $blocks[$slot]->{ref};

            $blocks[$slot]->{block} = sub {
                $orig_block->()->filter(sub {
                    _capture @_ => $orig_ref;
                    delete $blocks[$slot]; # destroy the cyclic ref
                    $predicate->(@_);
                });
            };
        };

        local $_LET = sub {
            my ($ref, $block) = @_;

            unless (@blocks) {
                # eval immediately because we aren't in any lambdas.
                _capture $block->() => $ref;
                return;
            }

            my $slot = $#blocks;
            my $orig_block = $blocks[$slot]->{block};
            my $orig_ref   = $blocks[$slot]->{ref};

            # Capture multiple values.
            # A tupple is used in "p <- e; p' = e'" pattern.
            # See: http://www.scala-lang.org/docu/files/ScalaReference.pdf
            $blocks[$slot]->{ref} = _tuple $orig_ref, $ref;
            $blocks[$slot]->{block} = sub {
                $orig_block->()->map(sub {
                    _capture @_ => $orig_ref;
                    delete $blocks[$slot]; # destroy the cyclic ref
                    return _tuple [@_], [$block->()];
                });
            };
        };
        $code->();
    }

    my $weak_loop;
    my $loop = sub {
        my @blocks = @_;

        my $info = shift @blocks;
        my $m = $info->{block}->();
        my $ref = $info->{ref};

        if ($info->{yield}) {
            return $m->map(sub {
                _capture @_ => $ref;
                $info->{yield}->();
            });
        } elsif (@blocks) {
            my $retained_loop = $weak_loop;
            return $m->flat_map(sub {
                _capture @_ => $ref;
                $retained_loop->(@blocks);
            });
        } else {
            return $m;
        }
    };
    weaken($weak_loop = $loop);

    return $loop->(@blocks);
}

1;

__END__

=head1 NAME

Data::Monad::Base::Sugar - Syntax sugars for Data::Monad.

=head1 SYNOPSIS

  use Data::Monad::Base::Sugar;
  use Data::Monad::List;

  my $result = Data::Monad::Base::Sugar::for {
      pick \my $x => sub { scalar_list 1 .. 100 };
      pick \my $y => sub { scalar_list $x .. 100 };
      pick \my $z => sub { scalar_list $y .. ($x + $y > 100 ? 100 : $x + $y) };
      satisfy { $x**2 + $y**2 == $z**2 };
      yield { $x, $y, $z }
  };

=head1 DESCRIPTION

Data::Monad::Base::Sugar provides syntax sugars for Data::Monad.

The for method is known as "do" expression in Haskell.

=head1 METHODS

=over 4

=item $monad = Data::Monad::Base::Sugar::for { ... }

DSL to create a monad value. You can use following functions in the block,
and shouldn't write sentences other than following functions in the block.

All sentences are connected by C<flat_map> automatically.

=over 4

=item pick \$value, \&f

=item pick \@values, \&f

=item pick \&f

Retrieves values from the monad, and puts it in C<$value>. C<\&f> should return
any Monad objects.

You should handle C<$value> as read-only and should use C<$value> only in
code-refs of other DSL functions.

=item let \$value, \&f

=item let \@values, \&f

Captures the value into C<$value>. C<\&f> can return any values, and the result
is put in C<$value> directly.

=item satisfy { ... }

Filters values by using C<filter>.

=item yield { ... }

Wraps values in a Monad object by using C<unit> and returns the monad object.
This sentence should be the last line of DSL.

=back

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

