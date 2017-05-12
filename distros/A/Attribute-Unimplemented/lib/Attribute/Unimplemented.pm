package Attribute::Unimplemented;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

use Attribute::Handlers;

my %done = ();

sub UNIVERSAL::Unimplemented : ATTR(CODE) {
    my($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $meth = *{$symbol}{NAME};
    no warnings 'redefine';
    *{$symbol} = sub {
	my($caller, $file, $line) = caller;
	unless ($done{"$file:$line"}++) {
	    require Carp;
	    Carp::carp "$package\::$meth() is not yet implemented.",
		    " just ignored this time.";
	}
	return 1;
    };
}

1;
__END__

=head1 NAME

Attribute::Unimplemented - mark unimplemented methods

=head1 SYNOPSIS

  package SomeClass;
  use Attribute::Unimplemented;

  sub wip : Unimpemented {
      # this block won't be executed
      my $self = shift;
      $self->foo;
      $self->bar;
  }

=head1 DESCRIPTION

Attribute::Unimplemented can be used to mark your methods as
unimplemented one.

With this attribute on, calls to those methods will generate warnings
and the real code inside the method won't be executed. That is the
only difference with Attribute::Deprecated.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Attribute::Handlers>, L<Attribute::Deprecated>

=cut
