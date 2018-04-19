package Class::Usul::Config;

use namespace::autoclean;

use Class::Usul::Constants   qw( CONFIG_EXTN DEFAULT_CONFHOME
                                 DEFAULT_ENCODING DEFAULT_L10N_DOMAIN
                                 FALSE LANG NUL PERL_EXTNS PHASE TRUE );
use Class::Usul::File;
use Class::Usul::Functions   qw( app_prefix canonicalise class2appdir
                                 home2appldir is_arrayref split_on__
                                 split_on_dash untaint_cmdline
                                 untaint_identifier untaint_path );
use Class::Usul::Types       qw( ArrayRef DataEncoding HashRef NonEmptySimpleStr
                                 NonZeroPositiveInt PositiveInt Str );
use Config;
use English                  qw( -no_match_vars );
use File::Basename           qw( basename dirname );
use File::DataClass::Types   qw( Directory File Path );
use File::Gettext::Constants qw( LOCALE_DIRS );
use File::Spec::Functions    qw( canonpath catdir catfile
                                 rel2abs rootdir tmpdir );
use File::Which              qw( which );
use Scalar::Util             qw( blessed );
use Moo;

# Attribute constructors
my $_build_l10n_attributes = sub {
   return { %{ $_[ 0 ]->_l10n_attributes }, domains => $_[ 0 ]->l10n_domains, };
};

# Public attributes
has 'appclass'  => is => 'ro',   isa => NonEmptySimpleStr, required => TRUE;

has 'appldir'   => is => 'lazy', isa => Directory, coerce => TRUE;

has 'binsdir'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'cfgfiles'  => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder      => sub { [] };

has 'ctlfile'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'ctrldir'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'datadir'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'encoding'  => is => 'ro',   isa => DataEncoding, coerce => TRUE,
   default      => DEFAULT_ENCODING;

has 'extension' => is => 'lazy', isa => NonEmptySimpleStr,
   default      => CONFIG_EXTN;

has 'home'      => is => 'lazy', isa => Directory, coerce => TRUE,
   default      => DEFAULT_CONFHOME;

has 'locale'    => is => 'ro',   isa => NonEmptySimpleStr, default => LANG;

has 'localedir' => is => 'lazy', isa => Directory, coerce => TRUE;

has 'locales'   => is => 'ro',   isa => ArrayRef[NonEmptySimpleStr],
   builder      => sub { [ LANG ] };

has 'logfile'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'logsdir'   => is => 'lazy', isa => Directory, coerce => TRUE;

has 'name'      => is => 'lazy', isa => NonEmptySimpleStr;

has 'no_thrash' => is => 'ro',   isa => NonZeroPositiveInt, default => 3;

has 'phase'     => is => 'lazy', isa => PositiveInt;

has 'prefix'    => is => 'lazy', isa => NonEmptySimpleStr,
   coerce       => sub { untaint_cmdline $_[ 0 ] };

has 'pathname'  => is => 'lazy', isa => File, coerce => TRUE;

has 'root'      => is => 'lazy', isa => Path, coerce => TRUE;

has 'rundir'    => is => 'lazy', isa => Path, coerce => TRUE;

has 'salt'      => is => 'lazy', isa => NonEmptySimpleStr;

has 'sessdir'   => is => 'lazy', isa => Path, coerce => TRUE;

has 'sharedir'  => is => 'lazy', isa => Path, coerce => TRUE;

has 'shell'     => is => 'lazy', isa => File, coerce => TRUE;

has 'suid'      => is => 'lazy', isa => Path, coerce => TRUE;

has 'tempdir'   => is => 'lazy', isa => Directory, coerce => TRUE;

has 'vardir'    => is => 'lazy', isa => Path, coerce => TRUE;

has 'l10n_attributes'  => is => 'lazy', isa => HashRef,
   builder             => $_build_l10n_attributes, init_arg => undef;

has 'l10n_domains'     => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder             => sub { [ DEFAULT_L10N_DOMAIN, $_[ 0 ]->name ] };

has '_l10n_attributes' => is => 'lazy', isa => HashRef,
   builder             => sub { {} }, init_arg => 'l10n_attributes';

has 'lock_attributes'  => is => 'ro',   isa => HashRef, builder => sub { {} };

has 'log_attributes'   => is => 'ro',   isa => HashRef, builder => sub { {} };

# Private functions
my $_is_inflated = sub {
   my ($attr, $attr_name) = @_;

   return exists $attr->{ $attr_name } && defined $attr->{ $attr_name }
       && $attr->{ $attr_name } !~ m{ \A __ }mx ? TRUE : FALSE;
};

my $_unpack = sub {
   my ($self, $attr) = @_; $attr //= {};

   blessed $self and return ($self, $self->{appclass}, $self->{home});

   return ($self, $attr->{appclass}, $attr->{home});
};

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_; my $attr = $orig->( $self, @args );

   my $paths; if ($paths = $attr->{cfgfiles} and $paths->[ 0 ]) {
      my $loaded = Class::Usul::File->data_load( paths => $paths ) || {};

      $attr = { %{ $loaded }, %{ $attr } }; # Yes this way round. Leave it alone
   }

   for my $name (keys %{ $attr }) {
      defined $attr->{ $name }
          and $attr->{ $name } =~ m{ \A __([^\(]+?)__ \z }mx
          and $attr->{ $name } = $self->inflate_symbol( $attr, $1 );
   }

   $self->inflate_paths( $attr );

   return $attr;
};

sub _build_appldir {
   my ($self, $appclass, $home) = $_unpack->( @_ ); my $dir;

   $dir = home2appldir $home
      and $dir = rel2abs( untaint_path $dir )
      and -d catdir( $dir, 'lib' ) and return $dir;

   $dir = catdir( NUL, 'var', class2appdir $appclass )
      and $dir = rel2abs( untaint_path $dir )
      and -d $dir and return $dir;

   $dir = rel2abs( untaint_path $home ) and -d $dir and return $dir;

   return rel2abs( untaint_path rootdir );
}

sub _build_binsdir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'appldir', 'bin' );

   return -d $dir ? $dir : untaint_path $Config{installsitescript};
}

sub _build_ctlfile {
   my $name      = $_[ 0 ]->inflate_symbol( $_[ 1 ], 'name'      );
   my $extension = $_[ 0 ]->inflate_symbol( $_[ 1 ], 'extension' );

   return $_[ 0 ]->inflate_path( $_[ 1 ], 'ctrldir', $name.$extension );
}

sub _build_ctrldir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'etc' );

   -d $dir and return $dir;

   $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'appldir', 'etc' );

   return -d $dir ? $dir : [ NUL, qw( usr local etc ) ];
}

sub _build_datadir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'data' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_localedir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'locale' );

   -d $dir and return $dir;

   for (map { catdir( @{ $_ } ) } @{ LOCALE_DIRS() } ) { -d $_ and return $_ }

   return $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_logfile {
   my $name = $_[ 0 ]->inflate_symbol( $_[ 1 ], 'name' );

   return $_[ 0 ]->inflate_path( $_[ 1 ], 'logsdir', "${name}.log" );
}

sub _build_logsdir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'logs' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_name {
   my $name = basename
      ( $_[ 0 ]->inflate_path( $_[ 1 ], 'pathname' ), PERL_EXTNS );

   return (split_on__ $name, 1) || (split_on_dash $name, 1) || $name;
}

sub _build_pathname {
   my $name = ('-' eq substr $PROGRAM_NAME, 0, 1) ? $EXECUTABLE_NAME
                                                  : $PROGRAM_NAME;

   return rel2abs( (split m{ [ ][\-][ ] }mx, $name)[ 0 ] );
}

sub _build_phase {
   my $verdir  = basename( $_[ 0 ]->inflate_path( $_[ 1 ], 'appldir' ) );
   my ($phase) = $verdir =~ m{ \A v \d+ \. \d+ p (\d+) \z }msx;

   return defined $phase ? $phase : PHASE;
}

sub _build_prefix {
   my $appclass = $_[ 0 ]->inflate_symbol( $_[ 1 ], 'appclass' );

   return (split m{ :: }mx, lc $appclass)[ -1 ];
}

sub _build_root {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'root' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_rundir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'run' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_sessdir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'session' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_sharedir {
   my $dir =  $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'share' );

   return -d $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'tempdir' );
}

sub _build_shell {
   my $file = $ENV{SHELL};         $file and -e $file and return $file;
      $file = catfile( NUL, 'bin', 'ksh'  ); -e $file and return $file;
      $file = catfile( NUL, 'bin', 'bash' ); -e $file and return $file;
      $file = which  ( 'sh' );     $file and -e $file and return $file;
   return     catfile( NUL, 'bin', 'sh'   );
}

sub _build_salt {
   return untaint_cmdline $_[ 0 ]->inflate_symbol( $_[ 1 ], 'prefix' );
}

sub _build_suid {
   my $prefix = $_[ 0 ]->inflate_symbol( $_[ 1 ], 'prefix' );

   return $_[ 0 ]->inflate_path( $_[ 1 ], 'binsdir', "${prefix}-admin" );
}

sub _build_tempdir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'vardir', 'tmp' );

   return -d $dir ? $dir : untaint_path tmpdir;
}

sub _build_vardir {
   my $dir = $_[ 0 ]->inflate_path( $_[ 1 ], 'appldir', 'var' );

   return -e $dir ? $dir : $_[ 0 ]->inflate_path( $_[ 1 ], 'appldir' );
}

# Public methods
sub inflate_path {
   return canonicalise $_[ 0 ]->inflate_symbol( $_[ 1 ], $_[ 2 ] ), $_[ 3 ];
}

sub inflate_paths {
   my ($self, $attr) = @_; defined $attr or return;

   for my $name (keys %{ $attr }) {
      defined $attr->{ $name }
          and $attr->{ $name } =~ m{ \A __(.+?)\((.+?)\)__ \z }mx
          and $attr->{ $name } = $self->inflate_path( $attr, $1, $2 );
   }

   return;
}

sub inflate_symbol {
   my ($self, $attr, $symbol) = @_; $attr //= {}; defined $symbol or return;

   my $attr_name = lc $symbol; my $method = "_build_${attr_name}";

   return blessed $self                        ? $self->$attr_name()
        : $_is_inflated->( $attr, $attr_name ) ? $attr->{ $attr_name }
                                               : $self->$method( $attr );
}

1;

__END__

=pod

=head1 Name

Class::Usul::Config - Configuration class with sensible attribute defaults

=head1 Synopsis

   use Class::Usul::Constants qw( TRUE );
   use Class::Usul::Types     qw( ConfigType HashRef LoadableClass );
   use Moo;

   has 'config'       => is => 'lazy', isa => ConfigType, builder => sub {
      $_[ 0 ]->config_class->new( $_[ 0 ]->_config_attr ) },
      init_arg        => undef;

   has '_config_attr' => is => 'ro',   isa => HashRef, builder => sub { {} },
      init_arg        => 'config';

   has 'config_class' => is => 'ro',   isa => LoadableClass, coerce => TRUE,
      default         => 'Class::Usul::Config';

=head1 Description

Defines the configuration object. Attributes have sensible defaults that
can be overridden by values in configuration files which are loaded on
request

Pathnames passed in the L</cfgfiles> attribute are loaded and their contents
merged with the values passed to the configuration class constructor

=head1 Configuration and Environment

Defines the following list of attributes;

=over 3

=item C<appclass>

Required string. The classname of the application for which this is the
configuration class

=item C<appldir>

Directory. Defaults to the application's install directory

=item C<binsdir>

Directory. Defaults to the application's F<bin> directory. Prefers
L</appldir>F</bin> but defaults to L<Config>s C<installsitebin> attribute

=item C<cfgfiles>

An array reference of non empty simple strings. The list of configuration
files to load when instantiating an instance of the configuration class.
Defaults to an empty list

=item C<ctlfile>

File in the F<ctrldir> directory that contains this programs control data
The default filename is comprised of L</name> and L</extension>

=item C<ctrldir>

Directory containing the per program configuration files. Prefers F<var/etc>,
then L</appldir>F</etc> defaulting to F</usr/local/etc>

=item C<datadir>

Directory containing data files used by the application. Prefers F<var/data>
but defaults to L</tempdir>

=item C<encoding>

String default to the constant C<DEFAULT_ENCODING>

=item C<extension>

String defaults to the constant C<CONFIG_EXTN>

=item C<home>

Directory containing the config file. Defaults to the constant
C<DEFAULT_CONFHOME>

=item C<l10n_attributes>

Hash reference of attributes used to construct a L<Class::Usul::L10N>
object. By default contains one key, C<domains>. The filename(s) used to
translate messages into different languages

=item C<l10n_domains>

An array reference which defaults to the constant C<DEFAULT_L10N_DOMAIN> and
the applications configuration name. Merged into L<l10n_attributes> as the
C<domains> attribute

=item C<locale>

The locale for language translation of text. Defaults to the constant
C<LANG>

=item C<localedir>

Directory containing the GNU Gettext portable object files used to translate
messages into different languages. Prefers F<var/locale> but defaults to
either the first existing directory in the list provided by the C<LOCALE_DIRS>
constant or failing that L</tempdir>

=item C<locales>

Array reference containing the list of supported locales. The default list
contains only the constant C<LANG>

=item C<lock_attributes>

Hash reference of attributes used to construct an L<IPC::SRLock> object

=item C<log_attributes>

Hash reference of attributes used to construct a L<Class::Usul::Log> object

=item C<logfile>

File in the C<logsdir> to which this program will log. Defaults to
L</name>.log

=item C<logsdir>

Directory containing the application log files. Prefers F<var/logs> but
defaults to L</tempdir>

=item C<name>

String. Derived from the L</pathname>. It is either; the last component of the
program name when split on underscores or dashes, or the program name itself
if it contains no underscores or dashes

=item C<no_thrash>

Integer default to 3. Number of seconds to sleep in a polling loop to
avoid processor thrash

=item C<pathname>

File defaults to the absolute path to the C<PROGRAM_NAME> system constant

=item C<phase>

Integer. Phase number indicates the type of install, e.g. 1 live, 2 test,
3 development

=item C<prefix>

String. Program prefix. Defaults to the last component of the L</appclass>
lower cased

=item C<root>

Directory. Path to the web applications document root. Prefers F<var/root>
but defaults to L</tempdir>

=item C<rundir>

Directory. Contains a running programs PID file. Prefers F<var/run> but defaults
to L</tempdir>

=item C<salt>

String. This applications salt for passwords as set by the administrators . It
is used to perturb the encryption methods. Defaults to the L</prefix>
attribute value

=item C<sessdir>

Directory. The session directory. Prefers F<var/session> but defaults to
L</tempdir>

=item C<sharedir>

Directory containing assets used by the application. Prefers F<var/share>
but defaults to L</tempdir>

=item C<shell>

File. The default shell used to create new OS users. Defaults to the
environment variable C<SHELL>. If that is not set tries (in order);
F</bin/ksh>, F</bin/bash>. L<which|File::Which/which> 'sh', and finally
defaults to F</bin/sh>. If the selected file does not exist then the
type constraint on the attribute will throw

=item C<suid>

File. Name of the setuid root program in the L</binsdir> directory. Defaults to
L</prefix>-admin

=item C<tempdir>

Directory. It is the location of any temporary files created by the
application. Prefers F<var/tmp> but defaults to the L<File::Spec> C<tempdir>

=item C<vardir>

Directory. Contains all of the non program code directories. Prefers F<var>
but defaults to L</appldir>

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Loads the configuration files if specified in the C<cfgfiles> attribute. Calls
L</inflate_symbol> and L</inflate_path> as required

=head2 inflate_path

Inflates the C<__symbol( relative_path )__> values to their actual runtime
values

=head2 inflate_paths

Calls L</inflate_path> for each of the matching values in the hash that
was passed as argument

=head2 inflate_symbol

Inflates the C<__SYMBOL__> values to their actual runtime values

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::File>

=item L<Moo>

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
