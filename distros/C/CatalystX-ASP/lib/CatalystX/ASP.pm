package CatalystX::ASP;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Tiny qw(Path Paths);
use Scalar::Util qw(blessed);
use Path::Tiny;
use Module::Runtime qw(require_module);
use Digest::MD5 qw(md5_hex);
use Carp;

with 'CatalystX::ASP::Compiler', 'CatalystX::ASP::Parser';

our $VERSION = '1.15';

=head1 NAME

CatalystX::ASP - PerlScript/ASP on Catalyst

=head1 VERSION

version 1.15

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  use Catalyst;
  extends 'Catalyst';

  with 'CatalystX::ASP::Role';

  1;

=head1 DESCRIPTION

CatalystX::ASP is a plugin for Catalyst to support ASP (PerlScript). This is
largely based off of Joshua Chamas's L<Apache::ASP>, as the application I've been
working with was written for L<Apache::ASP>. Thus, this was designed to be
almost a drop-in replacement. However, there were many features that I chose not
to implement.

This plugin basically creates a Catalyst View which can process ASP scripts. As
an added bonus, a simple L<CatalystX::ASP::Role> can be included to allow for
automatical processing of files with I<.asp> extension in the application
I<root> directory.

Just to be clear, the L<Parser|CatalystX::ASP::Parser> is almost totally ripped
off of Joshua Chamas's parser in L<Apache::ASP>. Similarly with the
L<Compiler|CatalystX::ASP::Compiler> and L<GlobalASA|CatalystX::ASP::GlobalASA>.
However, the other components are reimplementations.

=cut

our @CompileChecksumKeys = qw(Global GlobalPackage IncludesDir XMLSubsMatch);
our @Objects             = qw(Server Request Response Application Session);

has 'c' => (
    is      => 'rw',
    clearer => 'clear_c'
);

has '_setup_finished' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

=head1 CONFIGURATION

You can configure CatalystX::ASP in Catalyst under the C<CatalystX::ASP> section
of the configuration

  __PACKAGE__->config('CatalystX::ASP' => {
    Global        => 'lib',
    GlobalPackage => 'MyApp',
    IncludesDir   => 'templates',
    MailHost      => 'localhost',
    MailFrom      => 'myapp@localhost',
    XMLSubsMatch  => '(?:myapp):\w+',
    Debug         => 0,
  }):

The following documentation is also plagiarized from Joshua Chamas.

=over

=item Global

Global is the nerve center of an Apache::ASP application, in which the
global.asa may reside defining the web application's event handlers.

Includes, specified with C<< <!--#include file=somefile.inc--> >> or
C<< $Response->Include() >> syntax, may also be in this directory, please see
section on includes for more information.

=cut

has 'Global' => (
    is      => 'rw',
    isa     => Path,
    coerce  => 1,
    default => sub { path( '/tmp' ) },
);

=item GlobalPackage

Perl package namespace that all scripts, includes, & global.asa events are
compiled into.  By default, GlobalPackage is some obscure name that is uniquely
generated from the file path of the Global directory, and global.asa file. The
use of explicitly naming the GlobalPackage is to allow scripts access to globals
and subs defined in a perl module that is included with commands like:

  __PACKAGE__->config('CatalystX::ASP' => {
    GlobalPackage => 'MyApp' });

=cut

has 'GlobalPackage' => (
    is  => 'ro',
    isa => 'Str',
);

=item IncludesDir

No default. If set, this directory will also be used to look for includes when
compiling scripts. By default the directory the script is in, and the Global
directory are checked for includes.

This extension was added so that includes could be easily shared between ASP
applications, whereas placing includes in the Global directory only allows
sharing between scripts in an application.

  __PACKAGE__->config('CatalystX::ASP' => {
    IncludeDirs => '.' });

Also, multiple includes directories may be set:

  __PACKAGE__->config('CatalystX::ASP' => {
    IncludeDirs => ['../shared', '/usr/local/asp/shared'] });

Using IncludesDir in this way creates an includes search path that would look
like C<.>, C<Global>, C<../shared>, C</usr/local/asp/shared>. The current
directory of the executing script is checked first whenever an include is
specified, then the C<Global> directory in which the F<global.asa> resides, and
finally the C<IncludesDir> setting.

=cut

has 'IncludesDir' => (
    is      => 'rw',
    isa     => Paths,
    coerce  => 1,
    lazy    => 1,
    default => sub { [ shift->Global() ] },
);

=item MailHost

The mail host is the SMTP server that the below Mail* config directives will
use when sending their emails. By default L<Net::SMTP> uses SMTP mail hosts
configured in L<Net::Config>, which is set up at install time, but this setting
can be used to override this config.

The mail hosts specified in the Net::Config file will be used as backup SMTP
servers to the C<MailHost> specified here, should this primary server not be
working.

  __PACKAGE__->config('CatalystX::ASP' => {
    MailHost => 'smtp.yourdomain.com.foobar' });

=cut

has 'MailHost' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'localhost',
);

=item MailFrom

No default. Set this to specify the default mail address placed in the C<From:>
mail header for the C<< $Server->Mail() >> API extension

  __PACKAGE__->config('CatalystX::ASP' => {
    MailFrom => 'youremail@yourdomain.com.foobar' });

=cut

has 'MailFrom' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

=item XMLSubsMatch

Default is not defined. Set to some regexp pattern that will match all XML and
HTML tags that you want to have perl subroutines handle. The is
L<Apache::ASP/XMLSubs>'s custom tag technology ported to CatalystX::ASP, and can
 be used to create powerful extensions to your XML and HTML rendering.

Please see XML/XSLT section for instructions on its use.

  __PACKAGE__->config('CatalystX::ASP' => {
    XMLSubsMatch => 'my:[\w\-]+' });

=cut

subtype 'XMLSubsRegexp' => as 'Regexp';

coerce 'XMLSubsRegexp'
    => from 'Str'
    => via {
    $_ =~ s/\(\?\:([^\)]*)\)/($1)/isg;
    $_ =~ s/\(([^\)]*)\)/(?:$1)/isg;
    qr/$_/;
    };

has 'XMLSubsMatch' => (
    is     => 'ro',
    isa    => 'XMLSubsRegexp',
    coerce => 1,
);

=item Debug

Currently only a placeholder. Only effect is to turn on stacktrace on C<__DIE__>
signal.

=back

=cut

has 'Debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has '_include_file_cache' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw(Hash)],
    handles => {
        _include_file_from_cache => 'get',
        _cache_include_file      => 'set',
        _include_file_is_cached  => 'exists',
    },
);

has '_compile_checksum' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        my $self = shift;
        md5_hex(
            join( '&-+',
                $VERSION,
                map { $self->$_ || '' } @CompileChecksumKeys
                )
        );
    },
);

=head1 OBJECTS

The beauty of the ASP Object Model is that it takes the burden of CGI and
Session Management off the developer, and puts them in objects accessible from
any ASP script and include. For the perl programmer, treat these objects as
globals accessible from anywhere in your ASP application.

The CatalystX::ASP object model supports the following:

  Object        Function
  ------        --------
  $Session      - user session state
  $Response     - output to browser
  $Request      - input from browser
  $Application  - application state
  $Server       - general methods

These objects, and their methods are further defined in their respective
pod.

=over

=item L<CatalystX::ASP::Session>

=item L<CatalystX::ASP::Response>

=item L<CatalystX::ASP::Request>

=item L<CatalystX::ASP::Application>

=item L<CatalystX::ASP::Server>

=back

If you would like to define your own global objects for use in your scripts and
includes, you can initialize them in the F<global.asa> C<Script_OnStart> like:

  use vars qw( $Form $App ); # declare globals
  sub Script_OnStart {
    $App  = MyApp->new;     # init $App object
    $Form = $Request->Form; # alias form data
  }

In this way you can create site wide application objects and simple aliases for
common functions.

=cut

for ( qw(Server Request Response GlobalASA Application) ) {
    my $class = join( '::', __PACKAGE__, $_ );
    require_module $class;
    has "$_" => (
        is      => 'ro',
        isa     => $class,
        clearer => "clear_$_",
        lazy    => 1,
        default => sub { $class->new( asp => shift ) }
    );
}

my $session_class = join( '::', __PACKAGE__, 'Session' );
require_module $session_class;
has 'Session' => (
    is      => 'ro',
    isa     => $session_class,
    clearer => "clear_Session",
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        my %session = ( asp => $self, _is_new => 0 );

        # Create a Session object
        my $session_object = $session_class->new( %session );

        # If application has session support through pluging, pass into TIEHASH
        # to sync values from $Session to $c->session
        if ( $self->_setup_finished && $self->c->can( 'session' ) ) {
            tie %session, $session_class, $session_object;

            # Copy over every key from Session object to tied hash
            $session{$_} = $session_object->{$_} for ( keys %$session_object );
            return bless \%session, $session_class;
        } else {

            # Just return a $Session object, however it will not persist across
            # requests.
            return $session_object;
        }
    },
);

sub BUILD {
    my ( $self ) = @_;
    my $c = $self->c;

    # Prepend $c->config->{home} if Global is relative and not found
    if ( !$self->Global->exists && $self->Global->is_relative ) {
        $self->Global( path( $c->config->{home}, $self->Global ) );
    }

    # Go through each IncludeDir and check paths
    my @includes_dir;
    for ( @{ $self->IncludesDir } ) {
        if ( $_->is_relative ) {
            push @includes_dir, path( $c->config->{home}, $_ );
        }
        else {
            push @includes_dir, $_;
        }
    }
    $self->IncludesDir( \@includes_dir );

    # Trigger Application creation now
    $self->Application;

    # Trigger GlobalASA compilation now
    $self->GlobalASA->Application_OnStart;

    # Setup new Session
    $self->GlobalASA->Session_OnStart && $self->Session->_unset_is_new
        if $self->Session->_is_new;
}

=head1 METHODS

These are methods available for the C<CatalystX::ASP> object

=over

=item $self->search_includes_dir($include)

Returns the full path to the include if found in IncludesDir

=cut

sub search_includes_dir {
    my ( $self, $include ) = @_;

    # Check cache first, and just return path if cached
    return $self->_include_file_from_cache( $include )
        if $self->_include_file_is_cached( $include );

    # Look through each IncludesDir
    for my $dir ( @{ $self->IncludesDir } ) {
        my $file = $dir->child( $include );
        if ( $file->exists ) {

            # Don't forget to cache the results
            return $self->_cache_include_file( $include => $file );
        }
    }

    # For includes of absolute filesystem path
    my $file = path( $include );
    if ( path( $self->c->config->{home} )->subsumes( $file ) && $file->exists ) {
        return $self->_cache_include_file( $include => $file );
    }

    # Returning undef means file not found. Let calling method handle error
    return;
}

=item $self->file_id($file)

Returns a file id that can be used a subroutine name when compiled

=cut

sub file_id {
    my ( $self, $file, $without_checksum ) = @_;

    my $checksum = $without_checksum ? $self->_compile_checksum : '';
    my @id;

    $file =~ s|/+|/|sg;
    $file =~ s/[\Wx]/_/sg;
    if ( length( $file ) >= 35 ) {
        push @id, substr( $file, length( $file ) - 35, 36 );

        # only do the hex of the original file to create a unique identifier for the long id
        push @id, 'x', md5_hex( $file . $checksum );
    } else {
        push @id, $file, 'x', $checksum;
    }

    return join( '', '__ASP_', @id );
}

=item $self->execute($c, $code)

Eval the given C<$code>. Requies the Catalyst C<$context> object to be passed in
first. The C<$code> can be a ref to CODE or a SCALAR, ie. a string of code to
execute. Alternatively, C<$code> can be the absolute name of a subroutine.

=cut

sub execute {

    # shifting @_ because passing through arguments (from $Response->Include)
    my $self = shift;
    my $c    = shift;
    my $code = shift;

    no strict qw(refs);    ## no critic
    no warnings;

    # This is to set up "global" ASP objects available directly in script or
    # in the "main" namespace
    for my $object ( @Objects ) {
        for my $namespace ( 'main', $self->GlobalASA->package ) {
            my $var = join( '::', $namespace, $object );
            $$var = $self->$object;
        }
    }

    # This will cause STDOUT to be captured and handled by Tie::Handle in the
    # Response class
    tie local *STDOUT, 'CatalystX::ASP::Response';

    local $SIG{__WARN__} = \&Carp::cluck   if $self->Debug;
    local $SIG{__DIE__}  = \&Carp::confess if $self->Debug;
    my @rv;
    if ( my $reftype = ref $code ) {
        if ( $reftype eq 'CODE' ) {

            # The most common case
            @rv = eval { &$code; };
        } elsif ( $reftype eq 'SCALAR' ) {

            # If $code is just a ref to a string, just send it to client
            $self->Response->WriteRef( $code );
        } else {
            $c->error( "Could not execute because \$code is a ref, but not CODE or SCALAR!" );
        }
    } else {

        # Alternatively, execute a function in the ASP context given a string of
        # the subroutine name
        # If absolute package already, then no need to set to package namespace
        my $subid = ( $code =~ /::/ ) ? $code : $self->GlobalASA->package . '::' . $code;
        @rv = eval { &$subid; };
    }
    if ( $@ ) {

        # Record errors if not $c->detach and $Response->End
        $c->error( "Error executing code: $@" ) unless (
            blessed( $@ )
            && ( $@->isa( 'Catalyst::Exception::Detach' ) || $@->isa( 'CatalystX::ASP::Exception::End' ) )
        );

        # Passthrough $c->detach
        $@->rethrow if $@->isa( 'Catalyst::Exception::Detach' )
    }

    return @rv;
}

=item $self->cleanup()

Cleans up objects that are transient. Get ready for the next request

=cut

sub cleanup {
    my ( $self ) = @_;

    # Since cleanup happens at the end of script processing, trigger
    # Script_OnEnd
    $self->GlobalASA->Script_OnEnd if $self->_setup_finished;

    # Clean up abandoned $Session, which marks the end of the $Session and so
    # trigger Session_OnEnd. Additionally, need to remove session from store.
    if ( $self->Session->IsAbandoned ) {
        $self->GlobalASA->Session_OnEnd;

        my $c = $self->c;

        # By default, assume using Catalyst::Plugin::Session
        if ( $c->can( 'delete_session' ) ) {
            $c->delete_session( 'CatalystX::ASP::Sesssion::Abandon() called' )

                # Else assume using Catalyst::Plugin::iParadigms::Session
        } elsif ( $c->can( 'session_cache' ) ) {
            $c->clear_tii_session;
            $c->clear_session;
            $c->session_cache->delete( $c->sessionid );
        }
    }

    # Remove more references in order to get things destroyed
    untie ${ \$self->Session };
    undef &CatalystX::ASP::Response::TIEHANDLE;

    # Remove references to global ASP objects
    no strict qw(refs);    ## no critic
    for my $object ( reverse @Objects ) {
        for my $namespace ( 'main', $self->GlobalASA->package ) {
            my $var = join( '::', $namespace, $object );
            undef $$var;
        }
    }

    # Clear transient global objects from ASP object
    $self->clear_Session;
    $self->clear_Response;
    $self->clear_Request;
    $self->clear_c;
}

# Clear remaining global objects in order
sub DEMOLISH {
    my ( $self ) = @_;

    $self->clear_Application;
    $self->clear_Server;
    $self->clear_GlobalASA;
}

__PACKAGE__->meta->make_immutable;

=back

=head1 BUGS/CAVEATS

Obviously there are no bugs ;-) As of now, every known bug has been addressed.
However, a caveat is that not everything from Apache::ASP is implemented here.
Though the module touts itself to be a drop-in replacement, don't believe the
author and try it out for yourself first. You've been warned :-)

=head1 AUTHOR

Steven Leung E<lt> sleung@cpan.org E<gt>

Joshua Chamas E<lt> asp-dev@chamas.com E<gt>

=head1 SEE ALSO

=over

=item * L<Catalyst>

=item * L<Apache::ASP>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Steven Leung

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
