package Class::Usul::Exception;

use namespace::autoclean;

use Unexpected::Functions qw( has_exception );
use Unexpected::Types     qw( Int Str );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

my $class = __PACKAGE__;

$class->ignore_class( 'Class::Usul::IPC', 'Sub::Quote' );

has_exception $class;

has_exception 'DateTimeCoercion' => parents => [ $class ],
   error   => 'String [_1] will not coerce to a Unix time value';

has_exception 'Tainted' => parents => [ $class ],
   error   => 'String [_1] contains possible taint';

has_exception 'TimeOut' => parents => [ $class ],
   error   => 'Command [_1] timed out after [_2] seconds';

has '+class' => default => $class;

has 'out'    => is => 'ro', isa => Str, default => q();

has 'rv'     => is => 'ro', isa => Int, default => 1;

has 'time'   => is => 'ro', isa => Int, default => CORE::time(),
   init_arg  => undef;

1;

__END__

=pod

=encoding utf8

=head1 Name

Class::Usul::Exception - Exception handling

=head1 Synopsis

   use Class::Usul::Functions qw(throw);
   use Try::Tiny;

   sub some_method {
      my $self = shift;

      try   { this_will_fail }
      catch { throw $_ };
   }

   # OR
   use Class::Usul::Exception;

   sub some_method {
      my $self = shift;

      eval { this_will_fail };
      Class::Usul::Exception->throw_on_error;
   }

   # THEN
   try   { $self->some_method() }
   catch { warn $_."\n\n".$_->stacktrace."\n" };

=head1 Description

An exception class that supports error messages with placeholders, a
L</throw> method with automatic re-throw upon detection of self,
conditional throw if an exception was caught and a simplified
stacktrace

Error objects are overloaded to stringify to the full error message plus a
leader

=head1 Configuration and Environment

The C<< __PACKAGE__->ignore_class >> class method contains a classes
whose presence should be ignored by the error message leader

Defines the following list of read only attributes;

=over 3

=item C<args>

An array ref of parameters substituted in for the placeholders in the
error message when the error is localised

=item C<class>

Defaults to C<__PACKAGE__>. Can be used to differentiate different classes of
error

=item C<error>

The actually error message which defaults to C<Unknown error>. Can contain
placeholders of the form C<< [_<n>] >> where C<< <n> >> is an integer
starting at one

=item C<leader>

Set to the package and line number where the error should be reported

=item C<level>

A positive integer which defaults to one. How many additional stack frames
to pop before calculating the C<leader> attribute

=item C<out>

Defaults to null. May contain the output from whatever just threw the
exception

=item C<rv>

Return value which defaults to one

=item C<time>

A positive integer which defaults to the C<CORE::time> the exception was
thrown

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

Doesn't modify the C<BUILDARGS> method. This is here to workaround a
bug in L<Moo> and / or L<Test::Pod::Coverage>

=head2 C<as_string>

   $error_text = $self->as_string;

This is what the object stringifies to, including the C<leader> attribute

=head2 C<caught>

   $self = $class->caught( [ @args ] );

Catches and returns a thrown exception or generates a new exception if
C<$EVAL_ERROR> has been set. Returns either an exception object or undef

=head2 C<clone>

   $cloned_exception_object_ref = $self->clone( $args );

Returns a clone of the invocant. The optional C<$args> hash reference mutates
the returned clone

=head2 C<stacktrace>

   $lines = $self->stacktrace( $num_lines_to_skip );

Return the stack trace. Defaults to skipping zero lines of output

=head2 C<throw>

   $class->throw 'Path [_1] not found', [ 'pathname' ];

Create (or re-throw) an exception. If the passed parameter is a
blessed reference it is re-thrown. If a single scalar is passed it is
taken to be an error message, a new exception is created with all
other parameters taking their default values. If more than one
parameter is passed the it is treated as a list and used to
instantiate the new exception. The 'error' parameter must be provided
in this case

=head2 C<throw_on_error>

   $class->throw_on_error( [ @args ] );

Calls L</caught> passing in the options C<@args> and if there was an
exception L</throw>s it

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
