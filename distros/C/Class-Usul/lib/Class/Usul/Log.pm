package Class::Usul::Log;

use namespace::autoclean;

use Class::Usul::Constants qw( FALSE LOG_LEVELS NUL SPC TRUE );
use Class::Usul::Functions qw( is_hashref is_member merge_attributes
                               untaint_identifier );
use Class::Usul::Types     qw( Bool DataEncoding HashRef
                               LoadableClass Logger SimpleStr Undef );
use Encode                 qw( encode );
use File::Basename         qw( dirname );
use File::DataClass::Types qw( Path );
use Scalar::Util           qw( blessed );
use Sub::Install           qw( install_sub );
use Moo;

# Attribute constructors
my $_build__log = sub {
   return $_[ 0 ]->_log_class->new( %{ $_[ 0 ]->_log_attributes } );
};

my $_build__log_class = sub {
   return $_[ 0 ]->_logfile ? 'Log::Handler' : 'Class::Null';
};

# Private attributes
has '_debug_flag'     => is => 'ro',   isa => Bool, default => FALSE,
   init_arg           => 'debug';

has '_encoding'       => is => 'ro',   isa => DataEncoding | Undef,
   init_arg           => 'encoding';

has '_log'            => is => 'lazy', isa => Logger,
   builder            => $_build__log, init_arg => 'log';

has '_log_attributes' => is => 'lazy', isa => HashRef,
   builder            => sub { {} },   init_arg => 'log_attributes';

has '_log_class'      => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   builder            => $_build__log_class, init_arg => 'log_class';

has '_logfile'        => is => 'ro',   isa => Path | Undef, coerce => TRUE,
   init_arg           => 'logfile';

# Private class attributes
my $loggers = {};

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $class, @args) = @_; my $attr = $orig->( $class, @args );

   my $builder = $attr->{builder} or return $attr;
   my $config  = $builder->can( 'config' ) ? $builder->config : {};
   my $keys    = [ qw( appclass encoding log_attributes log_class logfile ) ];

   merge_attributes $attr, $builder, [ 'debug' ];
   merge_attributes $attr, $config,  $keys;

   return $attr;
};

sub BUILD {
   my ($self, $attr) = @_;

   exists $attr->{appclass}  and $loggers->{ $attr->{appclass} } = $self;
   exists $loggers->{default} or $loggers->{default} = $self;

   return;
}

sub import {
   my $class  = shift;
   my $params = { (is_hashref $_[ 0 ]) ? %{+ shift } : () };
   my @wanted = @_;
   my $target = caller;

   for my $wanted (grep { defined $_ } @wanted) {
      if ($wanted eq 'get_logger') {
         my $subr = $params->{as} // 'get_logger';

         install_sub { into => $target, as => $subr, code => sub ($) {
            return $loggers->{ $_[ 0 ] };
         } };
      }
      else {
         my $subr = $params->{as} // 'log';

         install_sub { into => $target, as => $subr, code => sub (;@) {
            return $loggers->{ $wanted }->log( @_ );
         } };
      }
   }

   return;
}

around '_log_attributes' => sub {
   my ($orig, $self) = @_; my $attr = $orig->( $self );

   $self->_log_class ne 'Log::Handler' and return $attr;

   my $fattr   = $attr->{file} //= {};
   my $logfile = $self->_logfile // $fattr->{filename};

   ($logfile and -d dirname( "${logfile}" )) or return $attr;

   $fattr->{alias} = 'file-out';
   $fattr->{filename} = "${logfile}";
   $fattr->{maxlevel} = $self->_debug_flag ? 'debug'
                      : untaint_identifier $fattr->{maxlevel} // 'info';
   $fattr->{mode    } = untaint_identifier $fattr->{mode    } // 'append';

   return $attr;
};

# Private functions
my $add_methods = sub {
   my ($class, @methods) = @_;

   for my $method (@methods) {
      $class->can( $method ) or
         install_sub { into => $class, as => $method, code => sub {
            my ($self, $text, $opts) = @_; $text or return FALSE;

            $text = ucfirst "${text}"; chomp $text; $text .= "\n";

            if (defined $opts) {
               my $lead = ucfirst $opts->{leader} // NUL;
               my $tag  = $opts->{tag}
                      // ($opts->{user} ? $opts->{user}->username : NUL);

               $tag  = $tag ? "[${tag}] " : $lead ? SPC : NUL;
               $text = "${lead}${tag}${text}";
            }

            $self->_encoding and $text = encode( $self->_encoding, $text );
            $self->_log->$method( $text );
            return TRUE;
         } };
   }

   return;
};

$add_methods->( __PACKAGE__, LOG_LEVELS );

my @arg_names = qw( level message options );

my $inline_args = sub {
   my $n = shift; return (map { $arg_names[ $_ ] => $_[ $_ ] } 0 .. $n - 1);
};

# Public methods
sub filehandle {
   my $self = shift; $self->_log_class ne 'Log::Handler' and return;

   return $self->_log->output( 'file-out' )->{fh};
}

sub log {
   my ($self, @args) = @_; my $n = 0; $n++ while (defined $args[ $n ]);

   my $args  = ($n == 0              ) ? {}
             : (is_hashref $args[ 0 ]) ? $args[ 0 ]
             : ($n == 1              ) ? { $inline_args->( 2, 'info', @args ) }
             : ($n == 2              ) ? { $inline_args->( 2, @args ) }
             : ($n == 3              ) ? { $inline_args->( 3, @args ) }
             :                           { @args };

   my $level = $args->{level}; $level and is_member $level, LOG_LEVELS
      and return $self->$level( $args->{message}, $args->{options} );

   return FALSE;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::Log - A simple flexible logging class

=head1 Synopsis

   use Class::Usul::Log;

   my $file = [ 't', 'test.log' ];
   my $log  = Class::Usul::Log->new( encoding => 'UTF-8', logfile => $file );
   my $text = 'Your error message goes here';

   # Can now call the following. The text will be encoded UTF-8
   $log->debug( $text ); # Does not log as debug was not true in the constructor
   $log->info ( $text );
   $log->warn ( $text );
   $log->error( $text );
   $log->alert( $text );
   $log->fatal( $text );

=head1 Description

A simple flexible logging class that supports both OO and functional interfaces

Creates methods for each logging level that encode their output. The logging
levels are defined by the L<log levels|Class::Usul::Constants/LOG_LEVELS>
constant

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<appclass>

Not an actual attribute. This value, if passed to the constructor, will be used
as a key to class attribute that caches instances of this class for use by
the functional interface

=item C<debug>

Debug flag defaults to false. If set to true calls to log at the debug level
will succeed rather than being ignored

=item C<encoding>

Optional output encoding. If present output to the logfile is encoded

=item C<log>

Optional log object. Will instantiate an instance of L<Log::Handler> if this
is not provided and the L</logfile> attribute is provided

=item C<log_attributes>

Attributes used to create the log object. Defaults to an empty hash reference

=item C<log_class>

The classname of the log object. This is loaded on demand and defaults to
L<Log::Handler> if the L</logfile> attribute is provided. If the L</logfile>
attribute is not provided L<Class::Null> is used instead

=item C<logfile>

Path to the logfile

=back

=head1 Subroutines/Methods

=head2 C<BUILDARGS>

   $usul_object_ref = Class::Usul->new;
   $log_object_ref  = Class::Usul::Log->new( builder => $usul_object_ref );

Passing an instance of L<Class::Usul> to the constructor allows it leech
attribute values from the C<Usul> configuration object

=head2 C<BUILD>

Store the new object reference in a class attribute for later importation.
The class attribute is a hash reference keyed by the C<appclass> attribute
passed to the constructor. The first logger instance created is also stored
keyed by C<default>

=head2 C<import>

   use Class::Usul::Log { as => ... }, 'get_logger';

Imports the C<get_logger> function which is called as

   my $log_object_ref = get_logger $instance_name;

where the C<$instance_name> is either the C<appclass> attribute value passed to
the OO constructor or the string C<default>. The function returns an instance
of this class. The optional parameters allow the function to imported as a
different name

   use Class::Usul::Log { as => ... }, 'default';

Imports the L</log> method from the C<default> log instance as a
function. Specify the C<appclass> value instead of C<default> to import from
that instance instead.  The optional parameters allow the function to imported
as a different name

=head2 C<filehandle>

Return the loggers file handle. This was added for L<IO::Async>, so that we
can tell it not to close the log file handle when it forks a child process
and only works if the C<log_class> is L<Log::Handler>

=head2 C<log>

   $self->log( $message );
   $self->log( $level, $message );
   $self->log( $level, $message, { ... } );
   $self->log( level => $level, message => $message, options => { ... } );
   $self->log( { level => $level, message => $message, options => { ... } } );

Logs the message at the given level. Accepts multiple signatures

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Null>

=item L<Moo>

=item L<Encode>

=item L<File::DataClass>

=item L<Log::Handler>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

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
