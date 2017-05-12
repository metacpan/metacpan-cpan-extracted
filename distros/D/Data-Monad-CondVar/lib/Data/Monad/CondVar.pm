package Data::Monad::CondVar;
use strict;
use warnings;
use 5.012;
use AnyEvent;
use Scalar::Util;
use Exporter qw/import/;

our $VERSION = "0.06";
our @EXPORT = qw/as_cv cv_unit cv_zero cv_fail cv_flat_map_multi cv_map_multi
                 cv_sequence call_cc/;

sub _assert_cv($) {
    $_[0]->ready and die "[BUG]It already has been ready";
    $_[0];
}

sub as_cv(&) {
    my $code = shift;
    $code->(my $cv = AE::cv);
    $cv;
}

sub cv_unit { AnyEvent::CondVar->unit(@_) }
sub cv_zero { AnyEvent::CondVar->zero(@_) }
sub cv_fail { AnyEvent::CondVar->fail(@_) }
sub cv_flat_map_multi(&@) { AnyEvent::CondVar->flat_map_multi(@_) }
sub cv_map_multi(&@) { AnyEvent::CondVar->map_multi(@_) }
sub cv_sequence { AnyEvent::CondVar->sequence(@_) }

sub call_cc(&) {
    my $f = shift;
    my $ret_cv = AE::cv;

    my $skip = sub {
        my @v = @_;
        _assert_cv $ret_cv;
        $ret_cv->send(@v);

        return AE::cv; # nop
    };

    my $branch_cv = $f->($skip)->map(sub {
        _assert_cv $ret_cv;
        $ret_cv->send(@_);
    })->catch(sub {
        _assert_cv $ret_cv;
        $ret_cv->croak(@_);
        cv_unit; # void
    })->catch(sub { warn @_ });
    $ret_cv->canceler(sub { $branch_cv->cancel });

    return $ret_cv;
}


package Data::Monad::CondVar::Mixin;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();
use AnyEvent ();

# extends AE::cv directly
require Data::Monad::Base::MonadZero;
for my $mixin (__PACKAGE__, 'Data::Monad::Base::MonadZero') {
    next if grep { $_ eq $mixin } @AnyEvent::CondVar::ISA;
    push @AnyEvent::CondVar::ISA, $mixin;
}

our $ZERO = "[ZERO of ${\ __PACKAGE__}]";

*_assert_cv = \&Data::Monad::CondVar::_assert_cv;

sub _cv_or_die($) {
    Scalar::Util::blessed $_[0] && $_[0]->isa('AnyEvent::CondVar')
        or Carp::croak "You must use CondVar object here.";
}

sub unit {
    my $class = shift;
    (my $cv = AE::cv)->send(@_);
    return $cv;
}

sub fail {
    my $class = shift;

    # XXX cv's croak doesn't throw the error if the message is empty.
    my $msg = $_[0] || $ZERO;
    (my $cv = AE::cv)->croak($msg);

    return $cv;
}

sub zero { $_[0]->fail($ZERO) }

sub any {
    my ($class, @cvs) = @_;

    my $result_cv = AE::cv;
    my @any_cv;
    for (@cvs) {
        push @any_cv, $_->map(sub {
            return unless $result_cv;
            _assert_cv $result_cv;
            $result_cv->send(@_);
            $result_cv->cancel;
        })->catch(sub {
            return unless $result_cv;
            _assert_cv $result_cv;
            $result_cv->croak(@_);
            $result_cv->cancel;
            return $class->unit;
        })->catch(sub { warn @_ });
    }
    $result_cv->canceler(sub { $_->cancel for @any_cv });

    $result_cv;
}

sub all {
    my ($class, @cvs) = @_;

    my @result;
    (my $result_cv = AE::cv)->begin(sub {
        my ($cv) = @_;
        _assert_cv $cv;
        $cv->send(@result);
    });
    for my $i (0 .. $#cvs) {
        $result_cv->begin;

        $cvs[$i]->map(sub {
            $result[$i] = [@_];
            $result_cv->end;
        })->catch(sub {
            _assert_cv $result_cv;
            $result_cv->croak(@_);
            $result_cv->cancel;
            return $class->unit;
        })->catch(sub { warn @_ });
    }
    $result_cv->end;

    $result_cv->canceler(sub { $_->cancel for @cvs });

    $result_cv;
}

sub cancel { (delete $_[0]->{_monad_canceler} || sub {})->() }

sub canceler {
    my $cv = shift;
    @_ and $cv->{_monad_canceler} = shift;
    $cv->{_monad_canceler};
}

sub _add_cb {
    my ($self, $cb) = @_;
    if(my $old_cb = $self->cb) {
        $self->cb(sub {
            $old_cb->(@_);
            $cb->(@_);
        });
    } else {
        $self->cb($cb);
    }
}

sub flat_map {
    my ($self, $f) = @_;

    my $cv_bound = AE::cv;
    my $cv_current = $self;
    $self->_add_cb(sub {
        my $cv = $cv_current = eval {
            my ($cv) = $f->($_[0]->recv);
            _cv_or_die $cv;
            $cv;
        };

        if ($@) {
            _assert_cv $cv_bound;
            return $cv_bound->croak($@);
        }
        $cv->_add_cb(sub {
            my @v = eval { $_[0]->recv };
            _assert_cv $cv_bound;
            $@ ? $cv_bound->croak($@) : $cv_bound->send(@v);
        });
    });
    $cv_bound->canceler(sub {
        $cv_current->cancel;
        $cv_current->cb(undef); # release the callback function
    });

    return $cv_bound;
}

sub or {
    my ($self, $alter) = @_;

    my $cv_mixed = AE::cv;
    $self->_add_cb(sub {
        my @v = eval { $_[0]->recv };
        unless ($@) {
            $cv_mixed->(@v);
        } elsif ($@ =~ /\Q$ZERO\E/) {
            $alter->_add_cb(sub {
                my @v = eval { $_[0]->recv };
                _assert_cv $cv_mixed;
                $@ ? $cv_mixed->croak($@) : $cv_mixed->(@v);
            });
        } else {
            _assert_cv $cv_mixed;
            $cv_mixed->croak($@);
        }
    });
    $cv_mixed->canceler(sub { $_->cancel for $self, $alter });

    $cv_mixed;
}

sub catch {
    my ($self, $f) = @_;

    my $result_cv = AE::cv;
    my $active_cv = $self;
    $self->_add_cb(sub {
        my @v = eval { $_[0]->recv };
        my $exception = $@ or return $result_cv->(@v);

        my $cv = $active_cv = eval {
            my $cv = $f->($exception);
            _cv_or_die $cv;
            $cv;
        };
        $@ and return (_assert_cv $result_cv)->croak($@);

        $cv->_add_cb(sub {
            my @v = eval { $_[0]->recv };
            _assert_cv $result_cv;
            $@ ? $result_cv->croak($@) : $result_cv->send(@v);
        });
    });
    $result_cv->canceler(sub {
        $active_cv->cancel;
        $active_cv->cb(undef); # release the callback function
    });

    return $result_cv;
}

sub sleep {
    my ($self, $sec) = @_;
    $self->flat_map(sub {
        my @v = @_;
        my $cv = AE::cv;
        my $t; $t = AE::timer $sec, 0, sub { $cv->(@v); undef $cv };
        $cv->canceler(sub { undef $t });
        return $cv;
    });
}

sub timeout {
    my ($self, $sec) = @_;
    my $class = ref $self;

    $class->any($class->unit->sleep($sec), $self);
}

sub retry {
    my $self = shift;
    my $f = pop;
    my ($retry, $pace) = @_;
    $retry ||= 1;
    $pace ||= 0;
    my $class = ref $self;

    $self->flat_map(sub {
        my @args = @_;

        $class->unit($retry, undef, undef)->while(
            sub {
                my ($retry, $ok, $fail) = @_;
                ! $ok and $retry > 0;
            }, sub {
                my ($retry, $ok, $fail) = @_;
                $f->(@args)->flat_map(sub {
                    $class->unit($retry - 1, [@_], undef);
                })->catch(sub {
                    $class->unit($retry - 1, undef, [@_])
                          ->sleep($pace);
                });
            }
        )->flat_map(sub {
            my ($retry, $ok, $fail) = @_;
            $fail ? $class->fail(@$fail) : $class->unit(@$ok);
        });
    });
}

1;

__END__

=head1 NAME

Data::Monad::CondVar - The CondVar monad.

=head1 SYNOPSIS

  use Data::Monad::CondVar;

  # The sleep sort
  my @list = (3, 5, 2, 4, 9, 1, 8);
  my @result;
  AnyEvent::CondVar->all(
      map {
          cv_unit($_)->sleep($_ / 1000)
                     ->map(sub { push @result, @_ });
      } @list
  )->recv;

=head1 DESCRIPTION

Data::Monad::CondVar adds monadic operations to AnyEvent::CondVar.

Since this module extends AnyEvent::CondVar directly, you can call monadic
methods anywhere there are CondVars.

This module is marked B<EXPERIMENTAL>. API could be changed without any notice.

=head1 METHODS

=over 4

=item $cv = as_cv($cb->($cv))

A helper for rewriting functions using callbacks to ones returning CVs.

  my $cv = as_cv { http_get "http://google.ne.jp", $_[0] };
  my ($data, $headers) = $cv->recv;

=item $cv = cv_unit(@vs)

=item $cv = cv_zero()

=item $cv = cv_fail($v)

=item $f = cv_flat_map_multi(\&f, $cv1, $cv2, ...)

=item $f = cv_map_multi(\&f, $cv1, $cv2, ...)

=item $cv = cv_sequence($cv1, $cv2, ...)

These are shorthand of methods which has the same name.

=item $cv = call_cc($f->($cont))

Calls C<$f> with current continuation, C<$cont>.
C<$f> must return a CondVar object.
If you call C<$cont> in C<$f>, results are sent to C<$cv> directly and
codes left in C<$f> will be skipped.

You can use C<call_cc> to escape a deeply nested call structure.

  sub myname {
      my $uc = shift;

      return call_cc {
          my $cont = shift;

          cv_unit("hiratara")->flat_map(sub {
              return $cont->(@_) unless $uc; # escape from an inner block
              cv_unit @_;
          })->map(sub { uc $_[0] });
      };
  }

  print myname(0)->recv, "\n"; # hiratara
  print myname(1)->recv, "\n"; # HIRATARA

=item unit

=item flat_map

Overrides methods of L<Data::Monad::Base::Monad>.

=item zero

Overrides methods of L<Data::Monad::Base::MonadZero>.
It uses C<fail> method internally.

=item $cv = AnyEvent::CondVar->fail($msg)

Creates the new CondVar object which represents a failed operation.
You can use C<catch> to handle failed operations.

=item $cv = AnyEvent::CondVar->any($cv1, $cv2, ...)

Takes the earliest value from C<$cv1>, C<$cv2>, ...

=item $cv = AnyEvent::CondVar->all($cv1, $cv2, ...)

Takes all values from C<$cv1>, C<$cv2>, ...

This method works completely like C<<Data::Monad::Base::Monad->sequence>>,
but you may want use this method for better cancellation.

=item $cv->cancel

Cancels computations for this CV. This method just calls the call back
which is set in the C<canceler> field.

C<<$cv->recv>> may never return from blocking after you call C<cancel>.

=item $cv->canceler($cb->())

=item $code = $cv->canceler

The accessor of the method to cancel. You should set this field appropriately
when you create the new CondVar object.

  my $cv = AE::cv;
  my $t = AE::timer $sec, 0, sub {
      $cv->send(@any_results);
      $cv->canceler(undef); # Destroy cyclic refs
  };
  $cv->canceler(sub { undef $t });

=item $cv = $cv1->or($cv2)

If C<$cv1> croaks, C<or> returns the CondVar object which contains values of
C<$cv2>. Otherwise it returns C<$cv1>'s values.

C<or> would be C<mplus> on Haskell.

=item $cv = $cv1->catch($cb->($@))

If C<$cv1> croaks, C<$cb> is called and it returns the new CondVar object
containing its result. Otherwise C<catch> does nothing. C<$cb> must return
a CondVar object.

You can use this method to handle errors.

  cv_unit(1, 0)
  ->map(sub { $_[0] / $_[1] })
  ->catch(sub {
      my $exception = shift;
      $exception =~ /Illegal division/
          ? cv_unit(0)           # recover from errors
          : cv_fail($exception); # rethrow
  });

=item $cv = $cv1->sleep($sec)

Sleeps C<$sec> seconds, and just sends values of C<$cv1> to C<$cv>.

=item $cv = $cv1->timeout($sec)

If C<$cv1> doesn't compute any values within C<$sec> seconds,
C<$cv> will be received C<undef> and C<$cv1> will be canceled.

Otherwise C<$cv> will be received C<$cv1>'s results.

=item $cv = $cv1->retry($max, [$pace, ], $f->(@v))

Continue to call C<flat_map($f)> until C<$f> returns a normal value which
doesn't croak.

C<$max> is maximum number of retries, C<$pace> is how long it sleeps between
each retry. The default value of C<$pace> is C<0>.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

L<AnyEvent>

L<Promises>

L<Future>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

