# ABSTRACT: adds a logger to a class

use strict;
use warnings;



package App::Rssfilter::Logger;
{
  $App::Rssfilter::Logger::VERSION = '0.07';
}

use Moo::Role;
use Log::Any;


has 'logger' => (
    is => 'lazy',
    default => sub { Log::Any->get_logger() },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Logger - adds a logger to a class

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    package Foo;
    use Moo; # or Role::Tiny::With;
    with 'App::Rssfilter::Logger';

    package main;

    my $foo = Foo->new;
    $foo->logger->debug( 'logging to my fresh new foo' );

=head1 DESCRIPTION

C<App::Rssfilter::Logger> is a role that can be composed into any class, and adds a C<logger> attribute which can be used to log to a L<Log::Any::Adapter>.

=head1 ATTRIBUTES

=head2 logger

This is a L<Log::Any> object.

=head1 SEE ALSO

=over 4

=item *

L<Log::Any>

=item *

L<Log::Any::Adapter>

=back

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
