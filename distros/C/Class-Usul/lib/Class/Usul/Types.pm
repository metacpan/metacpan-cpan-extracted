package Class::Usul::Types;

use strict;
use warnings;

use Class::Usul::Constants qw( DEFAULT_ENCODING FALSE LOG_LEVELS NUL TRUE );
use Class::Usul::Functions qw( ensure_class_loaded exception untaint_cmdline );
use Encode                 qw( find_encoding );
use Scalar::Util           qw( blessed tainted );
use Try::Tiny;
use Type::Library             -base, -declare =>
                           qw( ConfigProvider DataEncoding DataLumper
                               DateTimeRef Localiser Locker Logger
                               NullLoadingClass Plinth ProcCommer );
use Type::Utils            qw( as class_type coerce extends
                               from message subtype via where );
use Unexpected::Functions  qw( inflate_message is_class_loaded );

use namespace::clean -except => 'meta';

BEGIN { extends q(Unexpected::Types) };

# Private functions
my $_exception_message_for_object_reference = sub {
   return inflate_message 'String [_1] is not an object reference', $_[ 0 ];
};

my $_exception_message_for_configprovider = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing some configuration attributes', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_datetime = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is not of class DateTime', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_datalumper = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing the "data_load" method', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_localiser = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing the localize method', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_locker = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing set / reset methods', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_logger = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing a log level method', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_plinth = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing some builder attributes', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_exception_message_for_proccommer = sub {
   $_[ 0 ] and blessed $_[ 0 ] and return inflate_message
      'Object [_1] is missing the "run_cmd" method', blessed $_[ 0 ];

   return $_exception_message_for_object_reference->( $_[ 0 ] );
};

my $_has_builder_attributes = sub {
   my $obj = shift;

   $obj->can( $_ ) or return FALSE for (qw( config debug l10n lock log ));

   return TRUE;
};

my $_has_log_level_methods = sub {
   my $obj = shift;

   $obj->can( $_ ) or return FALSE for (LOG_LEVELS);

   return TRUE;
};

my $_has_min_config_attributes = sub {
   my $obj = shift; my @config_attr = ( qw(appldir home root tempdir vardir) );

   $obj->can( $_ ) or return FALSE for (@config_attr);

   return TRUE;
};

my $_isa_untainted_encoding = sub {
   my $enc = shift; my $res;

   try   { $res = !tainted( $enc ) && find_encoding( $enc ) ? TRUE : FALSE }
   catch { $res = FALSE };

   return $res
};

my $_load_if_exists = sub {
   if (my $class = shift) {
      eval { ensure_class_loaded( $class ) }; exception or return $class;
   }

   ensure_class_loaded 'Class::Null'; return 'Class::Null';
};

my $_str2date_time = sub {
   my $str = shift; ensure_class_loaded 'Class::Usul::Time';

   return Class::Usul::Time::str2date_time( $str );
};

# Type definitions
subtype ConfigProvider, as Object,
   where   { $_has_min_config_attributes->( $_ ) },
   message { $_exception_message_for_configprovider->( $_ ) };

subtype DataEncoding, as Str,
   where   { $_isa_untainted_encoding->( $_ ) },
   message { inflate_message 'String [_1] is not a valid encoding', $_ };

coerce DataEncoding,
   from Str,   via { untaint_cmdline $_ },
   from Undef, via { DEFAULT_ENCODING };

subtype DataLumper, as Object,
   where   { $_->can( 'data_load' ) and $_->can( 'data_dump' ) },
   message { $_exception_message_for_datalumper->( $_ ) };

subtype DateTimeRef, as Object,
   where   { blessed $_ && $_->isa( 'DateTime' ) },
   message { $_exception_message_for_datetime->( $_ ) };

coerce DateTimeRef, from Str, via { $_str2date_time->( $_ ) };

subtype Localiser, as Object,
   where   { $_->can( 'localize' ) },
   message { $_exception_message_for_localiser->( $_ ) };

subtype Locker, as Object,
   where   { $_->can( 'set' ) and $_->can( 'reset' ) },
   message { $_exception_message_for_locker->( $_ ) };

subtype Logger, as Object,
   where   { $_->isa( 'Class::Null' ) or $_has_log_level_methods->( $_ ) },
   message { $_exception_message_for_logger->( $_ ) };

subtype NullLoadingClass, as ClassName,
   where   { is_class_loaded( $_ ) };

coerce NullLoadingClass,
   from Str,   via { $_load_if_exists->( $_  ) },
   from Undef, via { $_load_if_exists->( NUL ) };

subtype Plinth, as Object,
   where   { $_has_builder_attributes->( $_ ) },
   message { $_exception_message_for_plinth->( $_ ) };

subtype ProcCommer, as Object,
   where   { $_->can( 'run_cmd' ) },
   message { $_exception_message_for_proccommer->( $_ ) };

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::Types - Defines type constraints

=head1 Synopsis

   use Class::Usul::Types q(:all);

=head1 Description

Defines the following type constraints;

=over 3

=item C<ConfigProvider>

Subtype of I<Object> can be coerced from a hash reference

=item C<DataEncoding>

Subtype of I<Str> which has to be one of the list of encodings in the
L<ENCODINGS|Class::Usul::Constants/ENCODINGS> constant

=item C<DataLumper>

Duck type that can; C<data_load> and C<data_dump>. Load and dump, lump

=item C<DateTimeRef>

Coerces a L<DateTime> object from a string

=item C<Localiser>

Duck type that can; C<localize>

=item C<Locker>

Duck type that can; C<reset> and C<set>

=item C<Logger>

Subtype of I<Object> which has to implement all of the methods in the
L<LOG_LEVELS|Class::Usul::Constants/LOG_LEVELS> constant

=item C<NullLoadingClass>

Loads the given class if possible. If loading fails, load L<Class::Null>
and return that instead

=item C<Plinth>

Duck type that can; C<config>, C<debug>, C<l10n>, C<lock>, and C<log>

=item C<ProcCommer>

Duck type that can; C<run_cmd>

=back

=head1 Subroutines/Methods

None

=head1 Configuration and Environment

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Constants>

=item L<Class::Usul::Functions>

=item L<Type::Tiny>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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

