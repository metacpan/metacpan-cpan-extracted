package App::Presto::ShellUI;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::ShellUI::VERSION = '0.010';
# ABSTRACT: Term::ShellUI sub-class

use strict;
use warnings;
use Regexp::Common 2013030901 qw(balanced);
use Moo;
use App::Presto::ArgProcessor;
extends 'Term::ShellUI';

foreach my $m(qw(readline GetHistory)){
	no strict 'refs';
	*$m = sub { my $self = $_[0]; my $target = $self->{term}->can($m); $_[0] = $self->{term}; goto $target };
}

has arg_processor => (
	is       => 'lazy',
);

sub _build_arg_processor {
	my $self = shift;
	return App::Presto::ArgProcessor->new;
}

sub call_command {
	my $self = shift;
	my($cmd) = @_;
	my $args = $cmd->{args};
	eval {
		$self->arg_processor->process($args);
		1;
	} or do {
		warn "Error preparsing args @$args: $@";
	};
	return $self->SUPER::call_command(@_);
}

sub ornaments {
	shift->{term}->ornaments(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::ShellUI - Term::ShellUI sub-class

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
