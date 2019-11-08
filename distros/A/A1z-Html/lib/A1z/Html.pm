use strict;
use warnings;
package A1z::Html;
use vars qw($NAME);

# ABSTRACT: Web Utilities

sub NAME { my $self = shift; $NAME = "Fast and Easy Web Apps"; return $NAME; }

our $VERSION = '0.003';

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub welcome {
	print qq{Content-Type: text/html;charset=utf-8\n\n};
	print qq{Welcome};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web Utilities - A1z::Html 

=head1 VERSION

version 0.003

=head1 SYNOPSIS

use A1z::HTML5::Template;
    my $h = A1z::HTML5::Template->new();

=head1 AUTHOR

Sudheer Murthy <pause@a1z.us>

=head1 COPYRIGHT

This software is copyright (c) 2019 by Sudheer Murthy.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
