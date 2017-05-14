package App::OverWatch::Event;
# ABSTRACT: Event object

use strict;
use warnings;
use utf8;

use Moo;
use namespace::clean;

has system    => ( is => 'ro' );
has subsystem => ( is => 'ro' );
has worker    => ( is => 'ro' );
has eventtype => ( is => 'ro' );
has ctime     => ( is => 'ro' );
has data      => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::Event - Event object

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 system

=head2 subsystem

=head2 worker

=head2 eventtype

=head2 ctime

=head2 data

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
