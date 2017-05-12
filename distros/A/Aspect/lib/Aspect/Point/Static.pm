package Aspect::Point::Static;

use strict;
use Carp          ();
use Aspect::Point ();

our $VERSION = '1.04';
our @ISA     = 'Aspect::Point';





######################################################################
# Error on anything this doesn't support

sub return_value {
	Carp::croak("Cannot call return_value on static part of a join point");
}

sub AUTOLOAD {
	my $self = shift;
	my $key  = our $AUTOLOAD;
	$key =~ s/^.*:://;
	Carp::croak("Cannot call $key on static part of join point");
}

1;

__END__

=pod

=head1 NAME

Aspect::Point::Static - The Join Point context for join point static parts

=head1 DESCRIPTION

This class implements the "static part" join point object, normally
encounted during (and stored by) the C<cflow> pointcut declarator.

It implements the subset of L<Aspect::Point> methods relating to the join
point in general and not relating to the specific call to the join point.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2013 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
