package Log::Dispatch::Handle;

use strict;
use warnings;

our $VERSION = '2.70';

use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );

use base qw( Log::Dispatch::Output );

{
    my $validator = validation_for(
        params => { handle => { type => t('CanPrint') } },
        slurpy => 1,
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless { handle => delete $p{handle} }, $class;
        $self->_basic_init(%p);

        return $self;
    }
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    $self->{handle}->print( $p{message} )
        or die "Cannot write to handle: $!";
}

1;

# ABSTRACT: Object for logging to IO::Handle classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Handle - Object for logging to IO::Handle classes

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Handle',
              min_level => 'emerg',
              handle    => $io_socket_object,
          ],
      ]
  );

  $log->emerg('I am the Lizard King!');

=head1 DESCRIPTION

This module supplies a very simple object for logging to some sort of
handle object. Basically, anything that implements a C<print()>
method can be passed the object constructor and it should work.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * handle ($)

The handle object. This object must implement a C<print()> method.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
