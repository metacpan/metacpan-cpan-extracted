package Class::Usul::TraitFor::RunningMethods;

use namespace::autoclean;

use Class::Usul::Constants qw( FAILED NUL OK TRUE UNDEFINED_RV );
use Class::Usul::Functions qw( dash2under elapsed emit_to exception is_hashref
                               is_member logname throw untaint_identifier );
use Class::Usul::Types     qw( ArrayRef HashRef Int SimpleStr );
use English                qw( -no_match_vars );
use File::DataClass::Types qw( OctalNum );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo::Role;
use Class::Usul::Options;

requires qw( app_version can_call debug error exit_usage
             extra_argv file next_argv output quiet );

# Public attributes
option 'method'  => is => 'rwp',  isa => SimpleStr, format => 's',
   documentation => 'Name of the method to call',
   default       => NUL, order => 1, short => 'c';

option 'options' => is => 'ro',   isa => HashRef,   format => 's%',
   documentation =>
      'Zero, one or more key=value pairs available to the method call',
   builder       => sub { {} }, short => 'o';

option 'umask'   => is => 'rw',   isa => OctalNum,  format => 's',
   documentation => 'Set the umask to this octal number',
   builder       => sub { $_[ 0 ]->config->umask }, coerce => TRUE,
   lazy          => TRUE;

option 'verbose' => is => 'ro',   isa => Int,
   documentation => 'Increase the verbosity of the output',
   default       => 0, repeatable => TRUE, short => 'v';

has 'params'     => is => 'lazy', isa => HashRef[ArrayRef],
   builder       => sub { {} };

# Private functions
my $_output_stacktrace = sub {
   my ($e, $verbose) = @_; ($e and blessed $e) or return; $verbose //= 0;

   $verbose > 0 and $e->can( 'trace' )
      and return emit_to \*STDERR, $e->trace.NUL;

   $e->can( 'stacktrace' ) and emit_to \*STDERR, $e->stacktrace.NUL;
   return;
};

# Private methods
my $handle_result = sub {
   my ($self, $method, $rv) = @_;

   my $params      = $self->params->{ $method };
   my $args        = (defined $params ) ? $params->[ 0 ] : undef;
   my $expected_rv = (is_hashref $args) ? $args->{expected_rv} // OK : OK;

   if (defined $rv and $rv <= $expected_rv) {
      $self->quiet or $self->output
         ( 'Finished in [_1] seconds', { args => [ elapsed ] } );
   }
   elsif (defined $rv and $rv > OK) {
      $self->error( 'Terminated code [_1]', {
         args => [ $rv ], no_quote_bind_values => TRUE } );
   }
   else {
      if ($rv == UNDEFINED_RV) { $self->error( 'Terminated with undefined rv' )}
      else {
         if (defined $rv) {
            $self->error
               ( 'Method [_1] unknown rv [_2]', { args => [ $method, $rv ] } );
         }
         else {
            $self->error( 'Method [_1] error uncaught or rv undefined',
                          { args => [ $method ] } );
            $rv = UNDEFINED_RV;
         }
      }
   }

   return $rv;
};

my $_handle_run_exception = sub {
   my ($self, $method, $error) = @_; my $e;

   unless ($e = exception $error) {
      $self->error
         ( 'Method [_1] exception without error', { args => [ $method ] } );
      return UNDEFINED_RV;
   }

   $e->can( 'out' ) and $e->out and $self->output( $e->out );
   $self->error( $e->error, { args => $e->args } );
   $self->debug and $_output_stacktrace->( $error, $self->verbose );

   return $e->can( 'rv' )
        ? ($e->rv || (defined $e->rv ? FAILED : UNDEFINED_RV)) : UNDEFINED_RV;
};

# Public methods
sub run {
   my $self   = shift;
   my $method = $self->select_method;
   my $text   = 'Started by [_1] Version [_2] Pid [_3]';
   my $args   = { args => [ logname, $self->app_version, abs $PID ] };

  (is_member $method, 'help', 'run_chain') and $self->quiet( TRUE );

   $self->quiet or $self->output( $text, $args ); umask $self->umask; my $rv;

   if ($method eq 'run_chain' or $self->can_call( $method )) {
      my $params = exists $self->params->{ $method }
                 ? $self->params->{ $method } : [];

      try {
         defined ($rv = $self->$method( @{ $params } ))
            or throw 'Method [_1] return value undefined',
                     args  => [ $method ], rv => UNDEFINED_RV;
      }
      catch { $rv = $self->$_handle_run_exception( $method, $_ ) };
   }
   else {
      $self->error( 'Class [_1] method [_2] not found',
                    { args => [ blessed $self, $method ] } );
      $rv = UNDEFINED_RV;
   }

   $rv = $self->$handle_result( $method, $rv );
   $self->file->delete_tmp_files;
   return $rv;
}

sub run_chain {
   my $self = shift; my $args = { args => [ $self->method ] };

   $self->method ? $self->error( 'Method [_1] unknown', $args )
                 : $self->error( 'Method not specified' );
   $self->exit_usage( 0 );
   return; # Not reached
}

sub select_method {
   my $self = shift; my $method = untaint_identifier dash2under $self->method;

   unless ($self->can_call( $method )) {
      $method = untaint_identifier dash2under $self->extra_argv( 0 );
      $method and $self->_set_method( $method );
     ($method and $self->can_call( $method ) and $self->next_argv)
        or $method = undef;
   }

   return $method ? $method : 'run_chain';
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::TraitFor::RunningMethods - Try and run a method catch and handle any exceptions

=head1 Synopsis

   use Moo;

   extends 'Class::Usul';
   with    'Class::Usul::TraitFor::RunningMethods';

=head1 Description

Implements the L</run> method which calls the target method in a try / catch
block. Handles any resulting exceptions

=head1 Configuration and Environment

Defines the following command line options;

=over 3

=item C<c method>

The method in the subclass to dispatch to

=item C<o options key=value>

The method that is dispatched to can access the key/value pairs
from the C<< $self->options >> hash ref

=item C<umask>

An octal number which is used to set the umask by the L</run> method

=item C<v verbose>

Repeatable boolean that increases the verbosity of the output

=back

Defines the following attributes;

=over 3

=item C<params>

A hash reference keyed by method name. The values are array references which
are flattened and passed to the method call by L</run>

=back

=head1 Subroutines/Methods

=head2 run

   $exit_code = $self->run;

Call the method specified by the C<-c> option on the command
line. Returns the exit code

=head2 run_chain

   $exit_code = $self->run_chain( $method );

Called by L</run> when L</select_method> cannot determine which method to
call. Outputs usage if C<method> is undefined. Logs an error if
C<method> is defined but not (by definition a callable method).
Returns exit code C<FAILED>

=head2 select_method

   $method = $self->select_method;

Called by L</run> it examines the L</method> attribute and if necessary the
extra command line arguments to determine the method to call

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Options>

=item L<File::DataClass>

=item L<Moo::Role>

=item L<Try::Tiny>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Usul.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

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
# vim: expandtab shiftwidth=3:
