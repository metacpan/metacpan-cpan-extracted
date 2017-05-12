package Attribute::Generator;

use strict;
use warnings;
our $VERSION = '0.02';

use Attribute::Handlers;
use Coro::State 4.91;

use base qw(Exporter);

our @EXPORT = qw(yield);

sub UNIVERSAL::Generator : ATTR(CODE) {
    my($package, $symbol, $refent) = @_;
    no warnings 'redefine';
    *{$symbol} = sub { new Attribute::Generator::State $refent, @_ };
}

our @stack = (Coro::State->new()); # Generator stack;

sub yield {
    $stack[-1]{_sent} = \@_;
    pop(@stack)->transfer($stack[-1]);
    my $sent = delete $stack[-1]{_sent} or return; # from send()
    wantarray ? @$sent : $sent->[0];
}

{
    package Attribute::Generator::State;
    use base qw(Coro::State);

    use overload (
        '@{}' => '__list__',
        '<>'  => 'next',
    );

    sub _run_generator {
        eval {
            &{+shift}; #execute the code
        };

        $stack[-2]->throw($@) if $@;
        while() {
            pop(@stack)->transfer($stack[-1]);
            delete $stack[-1]{_sent}; # clear send()ed.
        }
    }

    sub new {
        shift->SUPER::new(\&_run_generator, @_)
    }

    sub next {
        my($self) = @_;
        push @stack, $self;
        $stack[-2]->transfer($self); # resume
        my $ret = delete $self->{_sent} or return;
        wantarray ? @$ret : $ret->[0];
    }

    sub send {
        shift->{_sent} = \@_;
    }

    sub __list__ {
        my($self) = @_;
        my @ret;
        while(my @tmp = $self->next) {
            push @ret, @tmp;
        }
        \@ret;
    }
}

1;
__END__

=head1 NAME

Attribute::Generator - Python like generator powered by Coro

=head1 SYNOPSIS

  use Attribute::Generator;
  
  sub fizzbuzz :Generator {
    my($i, $end) = @_;
    do {
      yield (($i % 3 ? '':'Fizz').($i % 5 ? '':'Buzz') || $i)
    } while $i++ < $end;
  }
  
  my $generator = fizzbuzz(1, 100);
  
  while(defined (my $val = $generator->next())) {
    print "$val\n";
  }

  while(<$generator>) {
    print "$_\n";
  }

=head1 DESCRIPTION

Attribute::Generator realizes Python like generators using the power of L<Coro>
module. This module provides C<:Generator> CODE attribute which declares
generator subroutines, and exports C<yield> function which is like C<yield> in
Python.

=head1 FUNCTIONS

=over 4

=item :Generator attribute

This CODE attribute declares generator. When generator subroutines are called,
it returns an iterator object that has next() method.

=item $generator->next()

Advances generator until next yield called.

=item $generator->send(EXPR)

Send a value to the generator. In generator subroutine, sent value can be
received as return value of yield(): e.g.

  sub foo:Generator {
    my $i = 0;
    while() {
      if(defined yield $i++) {
        $i=0;
      }
    }
  }

This generator, yields 0, 1, 2, 3.. , can be reset by calling $gen->send(1).

Returns the generator itself.

Note: Unlike Python, send() does *NOT* advances iterator. 

=item yield EXPR

When you call yield in generator, current status of the generator are frozen
and EXPR is returned to the caller of $generator->next().

Note that calling yield() outside of :Generator subroutines are strictly
prohibited.

=back

=head1 AUTHOR

Rintaro Ishizaki E<lt>rintaro@cpan.orgE<gt>

=head1 SEE ALSO

L<Coro::State>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
