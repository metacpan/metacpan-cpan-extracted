package Dancer2::Logger::LogAny;
our $AUTHORITY = 'cpan:TONKIN';
# ABSTRACT: Use Log::Any to log from your Dancer2 app
our $VERSION = '0.9907';

use strict; use warnings;
use Dancer2 qw/ :syntax !log !debug !info !notice !warning !error /;
use Dancer2::Core::Types qw/ Str ArrayRef /;

use Log::Any::Adapter;

use Moo;
with 'Dancer2::Core::Role::Logger';

has category    => ( is => 'ro', isa => Str );
has logger      => ( is => 'ro', isa => ArrayRef, required => 1 );
has _logger_obj => ( is => 'lazy' );

sub _build__logger_obj {
    my $self = shift;

    my %category = $self->category ?
        ( category => $self->category ) : ();

    Log::Any::Adapter->set( @{ $self->logger } );
    return Log::Any->get_logger( %category ); 
}


sub log {
    my ( $self, $level, $message ) = @_;

    $level = 'debug' if $level eq 'core';

    $self->_logger_obj->$level( $message );
}

1; # return true

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Logger::LogAny - Use Log::Any to log from your Dancer2 app

=head1 VERSION

version 0.9907

=head1 DESCRIPTION

This module implements a Dancer2 logging engine using C<Log::Any>.
You can then use any C<Log::Any::Adapter>-based output class on the backend.

=head1 METHODS

=head2 log( @args )

This is the function required by C<Dancer2::Core::Role::Logger>

=head1 CONFIGURATION

In your Dancer2 config:

  logger: LogAny
 
  engines:
      logger:
          LogAny:
              category: Important Messages
              logger:
                  - Stderr
                  - newline
                  - 1

If you omit the category setting, C<Log::Any::Adapter> will use the name of
this class as the category.

=head1 SEE ALSO

C<Log::Any>, C<Log::Any::Adapter>, C<Dancer2::Core::Role::Logger>

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
