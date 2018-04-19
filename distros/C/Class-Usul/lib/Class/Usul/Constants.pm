package Class::Usul::Constants;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use Class::Usul::Exception;
use File::DataClass::Constants ( );
use File::Spec::Functions    qw( tmpdir );
use IPC::SRLock::Constants     ( );

my $Assert          = sub {};
my $Config_Extn     = '.json';
my $Exception_Class = 'Class::Usul::Exception';
my $Log_Levels      = [ qw( alert debug error fatal info warn ) ];

__PACKAGE__->Exception_Class( $Exception_Class ); # Trigger redispatch

our @EXPORT = qw( ARRAY AS_PARA AS_PASSWORD ASSERT BRK CODE COMMA CONFIG_EXTN
                  DEFAULT_CONFHOME DEFAULT_ENVDIR DEFAULT_ENCODING
                  DEFAULT_L10N_DOMAIN DIGEST_ALGORITHMS ENCODINGS
                  EXCEPTION_CLASS FAILED FALSE HASH LANG LBRACE
                  LOCALIZE LOG_LEVELS NO NUL OK PERL_EXTNS PHASE
                  PREFIX QUIT QUOTED_RE SEP SPC TRUE UMASK UNDEFINED_RV
                  UNTAINT_CMDLINE UNTAINT_IDENTIFIER UNTAINT_PATH
                  UUID_PATH WIDTH YES );

sub ARRAY    () { 'ARRAY' }
sub BRK      () { ': '    }
sub CODE     () { 'CODE'  }
sub COMMA    () { ','     }
sub FAILED   () { 1       }
sub FALSE    () { 0       }
sub HASH     () { 'HASH'  }
sub LANG     () { 'en'    }
sub LBRACE   () { '{'     }
sub LOCALIZE () { '[_'    }
sub NO       () { 'n'     }
sub NUL      () { q()     }
sub OK       () { 0       }
sub PHASE    () { 2       }
sub QUIT     () { 'q'     }
sub SEP      () { '/'     }
sub SPC      () { ' '     }
sub TRUE     () { 1       }
sub UMASK    () { '027'   }
sub WIDTH    () { 80      }
sub YES      () { 'y'     }

sub AS_PARA             () { { cl => 1, fill => 1, nl => 1 } }
sub AS_PASSWORD         () { ( q(), 1, 0, 0, 1 ) }
sub ASSERT              () { __PACKAGE__->Assert }
sub CONFIG_EXTN         () { __PACKAGE__->Config_Extn }
sub DEFAULT_CONFHOME    () { tmpdir }
sub DEFAULT_ENCODING    () { 'UTF-8' }
sub DEFAULT_ENVDIR      () { [ q(), qw( etc default ) ] }
sub DEFAULT_L10N_DOMAIN () { 'default' }
sub DIGEST_ALGORITHMS   () { ( qw( SHA-512 SHA-256 SHA-1 MD5 ) ) }
sub ENCODINGS           () { ( qw( ascii iso-8859-1 UTF-8 guess ) ) }
sub EXCEPTION_CLASS     () { __PACKAGE__->Exception_Class }
sub LOG_LEVELS          () { @{ __PACKAGE__->Log_Levels } }
sub PERL_EXTNS          () { ( qw( .pl .pm .t ) ) }
sub PREFIX              () { [ q(), 'opt' ] }
sub QUOTED_RE           () { qr{ (?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\")|(?:\')(?:[^\\\']*(?:\\.[^\\\']*)*)(?:\')|(?:\`)(?:[^\\\`]*(?:\\.[^\\\`]*)*)(?:\`)) }mx }
sub UNDEFINED_RV        () { -1 }
sub UNTAINT_CMDLINE     () { qr{ \A ([^\$&;<>\`|]+)    \z }mx }
sub UNTAINT_IDENTIFIER  () { qr{ \A ([a-zA-Z0-9_]+)    \z }mx }
sub UNTAINT_PATH        () { qr{ \A ([^\$%&\*;<>\`|]+) \z }mx }
sub UUID_PATH           () { [ q(), qw( proc sys kernel random uuid ) ] }

sub Assert {
   my ($self, $subr) = @_; defined $subr or return $Assert;

   ref $subr eq 'CODE' or EXCEPTION_CLASS->throw
      ( "Assert subroutine ${subr} is not a code reference" );

   return $Assert = $subr;
}

sub Config_Extn {
   my ($self, $extn) = @_; defined $extn or return $Config_Extn;

   (length $extn < 255 and $extn !~ m{ \n }mx) or EXCEPTION_CLASS->throw
      ( "Config extension ${extn} is not a simple string" );

   return $Config_Extn = $extn;
}

sub Exception_Class {
   my ($self, $class) = @_; defined $class or return $Exception_Class;

   $class->can( 'throw' ) or $Exception_Class->throw
      ( "Exception class ${class} is not loaded or has no throw method" );

   File::DataClass::Constants->Exception_Class( $class );
   IPC::SRLock::Constants->Exception_Class( $class );

   return $Exception_Class = $class;
}

sub Log_Levels {
   my ($self, $levels) = @_; defined $levels or return $Log_Levels;

   ref $levels eq 'ARRAY' and defined $levels->[ 0 ] or EXCEPTION_CLASS->throw
      ( "Log levels must be an array reference with one defined value" );

   return $Log_Levels = $levels;
}

1;

__END__

=pod

=head1 Name

Class::Usul::Constants - Definitions of constant values

=head1 Synopsis

   use Class::Usul::Constants qw( FALSE SEP TRUE );

   my $bool = TRUE; my $slash = SEP;

=head1 Description

Exports a list of subroutines each of which returns a constants value

=head1 Configuration and Environment

Defines the following class attributes;

=over 3

=item C<Assert>

=item C<Config_Extn>

=item C<Config_Key>

=item C<Exception_Class>

=item C<Log_Levels>

=back

These are accessor / mutators for class attributes of the same name. The
constants with uppercase names return these values. At compile time they
can be used to set values the are then constant at runtime

=head1 Subroutines/Methods

=head2 ARRAY

String C<ARRAY>

=head2 AS_PARA

Returns a hash reference containing the keys and values that causes the auto
formatting L<output|Class::Usul::Programs/output> subroutine to clear left,
fill paragraphs, and append an extra newline

=head2 AS_PASSWORD

Returns a list of arguments for
L<get_line|Class::Usul::TraitFor::Prompting/get_line> which causes it to prompt
for a password

=head2 ASSERT

Return a code reference which is imported by L<Class::Usul::Functions> into
the callers namespace as the C<assert> function. By default this will
be the empty subroutine, C<sub {}>. Change this by setting the C<Assert>
class attribute

=head2 BRK

Separate leader from message with the characters colon space

=head2 CODE

String C<CODE>

=head2 COMMA

The comma character

=head2 CONFIG_EXTN

The default configuration file extension, F<.json>. Change this by
setting the C<Config_Extn> class attribute

=head2 DEFAULT_CONFHOME

Default directory for the config file. The function C<find_apphome>
defaults to returning this value if it cannot find a more suitable one.
Returns the L<temporary directory|File::Spec::Functions/tmpdir>

=head2 DEFAULT_ENCODING

String C<UTF-8>

=head2 DEFAULT_ENVDIR

An array reference which if passed to L<catdir|File::Spec/catdir> is the
directory which will contain the applications installation information.
Directory defaults to F</etc/default>

=head2 DEFAULT_L10N_DOMAIN

String C<default>. The name of the default message catalogue

=head2 DIGEST_ALGORITHMS

List of algorithms to try as args to L<Digest>

=head2 ENCODINGS

List of supported IO encodings

=head2 EXCEPTION_CLASS

The name of the class used to throw exceptions. Defaults to
L<Class::Usul::Exception> but can be changed by setting the
C<Exception_Class> class attribute

=head2 FAILED

Non zero exit code indicating program failure

=head2 FALSE

Digit C<0>

=head2 HASH

String C<HASH>

=head2 LANG

Default language code, C<en>

=head2 LBRACE

The left brace character, C<{>

=head2 LOCALIZE

The character sequence that introduces a localisation substitution
parameter, C<[_>

=head2 LOG_LEVELS

List of methods the log object is expected to support

=head2 NO

The letter C<n>

=head2 NUL

Empty (zero length) string

=head2 OK

Returns good program exit code, zero

=head2 PERL_EXTNS

List of possible file suffixes used on Perl scripts

=head2 PHASE

The default phase number used to select installation specific config, 2

=head2 PREFIX

Array reference representing the default parent path for a normal install.
Defaults to F</opt>

=head2 QUIT

The character q

=head2 QUOTED_RE

The regular expression to match a quoted string. Lifted from L<Regexp::Common>
which now has installation and indexing issues

=head2 SEP

Slash C</> character

=head2 SPC

Space character

=head2 TRUE

Digit C<1>

=head2 UMASK

Default file creation mask, 027 octal, that's C<rw-r----->

=head2 UNDEFINED_RV

Digit C<-1>. Indicates that a method wrapped in a try/catch block failed
to return a defined value

=head2 UNTAINT_CMDLINE

Regular expression used to untaint command line strings

=head2 UNTAINT_IDENTIFIER

Regular expression used to untaint identifier strings

=head2 UNTAINT_PATH

Regular expression used to untaint path strings

=head2 USUL_CONFIG_KEY

Default configuration hash key, C<Plugin::Usul>. Change this by setting
the C<Config_Key> class attribute

=head2 UUID_PATH

An array reference which if passed to L<catdir|File::Spec/catdir> is the path
which will return a unique identifier if opened and read

=head2 WIDTH

Default terminal screen width in characters

=head2 YES

The character y

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter>

=item L<Class::Usul::Exception>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

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
