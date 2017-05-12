package Aspect::Library::Breakpoint;

use strict;
use Aspect::Library        ();
use Aspect::Advice::Before ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Library';

sub get_advice {
	my $self = shift;
	Aspect::Advice::Before->new(
		lexical  => $self->lexical,
		pointcut => $_[0],
		code     => sub {
			no warnings;
			$DB::single = 1;
		},
	);
}

1;

__END__

=pod

=head1 NAME

Aspect::Library::Breakpoint - A breakpoint aspect

=head1 SYNOPSIS

  use Aspect;
  
  aspect Breakpoint => call qr/^Foo::refresh/;
  
  my $f1 = Foo->refresh_foo;
  my $f2 = Foo->refresh_bar;
  
  # The debugger will go into single statement mode for both methods

=head1 DESCRIPTION

C<Aspect::Library::Breakpoint> is a reusable aspect for implementing
breakpoints in the debugger in patterns that are more complex than
the native debugger supports.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
