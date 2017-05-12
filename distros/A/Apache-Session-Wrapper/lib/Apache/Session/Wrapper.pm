package Apache::Session::Wrapper;

use strict;

use vars qw($VERSION);

$VERSION = '0.34';
$VERSION = eval $VERSION;

use base qw(Class::Container);

use Apache::Session 1.81;

use Exception::Class ( 'Apache::Session::Wrapper::Exception::NonExistentSessionID' =>
		       { description => 'A non-existent session id was used',
			 fields => [ 'session_id' ] },
                       'Apache::Session::Wrapper::Exception::Params' =>
		       { description => 'An invalid parameter or set of parameters was given',
                         alias => 'param_error' },
		     );

use Params::Validate 0.70;
use Params::Validate qw( validate SCALAR UNDEF BOOLEAN ARRAYREF OBJECT );
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

use Scalar::Util ();


my $MOD_PERL = _find_mp_version();
sub _find_mp_version
{
    return 0 unless $ENV{MOD_PERL};

    return
        ( $ENV{MOD_PERL} =~ /(?:1\.9|2\.\d)/
          ? 2
          : 1
        );
}

my @HeaderMethods = qw( err_headers_out headers_out );

my %params =
    ( always_write =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Whether or not to force a write before the session goes out of scope' },

      allow_invalid_id =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Whether or not to allow a failure to find an existing session id' },

      param_name =>
      { type => SCALAR,
        optional => 1,
        depends => 'param_object',
	descr => 'Name of the parameter to use for session tracking' },

      param_object =>
      { type => OBJECT,
        optional => 1,
        can  => 'param',
	descr => 'Object which has a "param" method, to be used for getting the session id from a query string or POST argument' },

      use_cookie =>
      { type => BOOLEAN,
	default => 0,
	descr => 'Whether or not to use a cookie to track the session' },

      cookie_name =>
      { type => SCALAR,
	default => 'Apache-Session-Wrapper-cookie',
	descr => 'Name of cookie used by this module' },

      cookie_expires =>
      { type => UNDEF | SCALAR,
	default => '+1d',
	descr => 'Expiration time for cookies' },

      cookie_domain =>
      { type => UNDEF | SCALAR,
        optional => 1,
	descr => 'Domain parameter for cookies' },

      cookie_path =>
      { type => SCALAR,
	default => '/',
	descr => 'Path for cookies' },

      cookie_secure =>
      { type => BOOLEAN,
	default => 0,
	descr => 'Are cookies sent only for SSL connections?' },

      cookie_resend =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Resend the cookie on each request?' },

      header_object =>
      { type => OBJECT,
        callbacks =>
        { 'has a method to set headers' =>
          sub { grep { $_[0]->can($_) } @HeaderMethods } },
        optional => 1,
        descr => 'An object that can be used to send cookies with' },

      class =>
      { type => SCALAR,
	descr => 'An Apache::Session class to use for sessions' },

      data_source =>
      { type => SCALAR,
	optional => 1,
	descr => 'The data source when using MySQL or PostgreSQL' },

      user_name =>
      { type => UNDEF | SCALAR,
        optional => 1,
	descr => 'The user name to be used when connecting to a database' },

      password =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'The password to be used when connecting to a database' },

      table_name =>
      { type => UNDEF | SCALAR,
        optional => 1,
        descr => 'The table in which sessions are saved' },

      lock_data_source =>
      { type => SCALAR,
	optional => 1,
	descr => 'The data source when using MySQL or PostgreSQL' },

      lock_user_name =>
      { type => UNDEF | SCALAR,
        optional => 1,
	descr => 'The user name to be used when connecting to a database' },

      lock_password =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'The password to be used when connecting to a database' },

      handle =>
      { type => OBJECT,
        optional => 1,
	descr => 'An existing database handle to use' },

      lock_handle =>
      { type => OBJECT,
        optional => 1,
	descr => 'An existing database handle to use' },

      commit =>
      { type => BOOLEAN,
        default => 1,
	descr => 'Whether or not to auto-commit changes to the database' },

      transaction =>
      { type => BOOLEAN,
	default => 0,
	descr => 'The Transaction flag for Apache::Session' },

      directory =>
      { type => SCALAR,
	optional => 1,
	descr => 'A directory to use when storing sessions' },

      lock_directory =>
      { type => SCALAR,
	optional => 1,
	descr => 'A directory to use for locking when storing sessions' },

      file_name =>
      { type => SCALAR,
	optional => 1,
	descr => 'A DB_File to use' },

      store =>
      { type => SCALAR,
	optional => 1,
	descr => 'A storage class to use with the Flex module' },

      lock =>
      { type => SCALAR,
	optional => 1,
	descr => 'A locking class to use with the Flex module' },

      generate =>
      { type => SCALAR,
	default => 'MD5',
	descr => 'A session generator class to use with the Flex module' },

      serialize =>
      { type => SCALAR,
	optional => 1,
	descr => 'A serialization class to use with the Flex module' },

      textsize =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Sybase storage module' },

      long_read_len =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Oracle storage module' },

      n_sems =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Semaphore locking module' },

      semaphore_key =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Semaphore locking module' },

      mod_usertrack_cookie_name =>
      { type => SCALAR,
	optional => 1,
	descr => 'The cookie name used by mod_usertrack' },

      save_path =>
      { type => SCALAR,
	optional => 1,
	descr => 'Path used by Apache::Session::PHP' },

      session_id =>
      { type => SCALAR,
	optional => 1,
	descr => 'Try this session id first when making a session' },
    );

# What set of parameters are required for each session class.
# Multiple array refs represent multiple possible sets of parameters
my %ApacheSessionParams =
    ( Flex     => [ [ qw( store lock generate serialize ) ] ],
      MySQL    => [ [ qw( data_source user_name
                          lock_data_source lock_user_name ) ],
		    [ qw( handle lock_handle ) ] ],
      Postgres => [ [ qw( data_source user_name commit ) ],
		    [ qw( handle commit ) ] ],
      File     => [ [ qw( directory lock_directory ) ] ],
      DB_File  => [ [ qw( file_name lock_directory ) ] ],

      PHP      => [ [ qw( save_path ) ] ],
    );

@ApacheSessionParams{ qw( Informix Oracle Sybase ) } =
    ( $ApacheSessionParams{Postgres} ) x 3;

my %OptionalApacheSessionParams =
    ( MySQL    => [ [ qw( table_name password lock_password ) ] ],
      Postgres => [ [ qw( table_name password ) ] ],
      Informix => [ [ qw( table_name password ) ] ],
      Oracle   => [ [ qw( long_read_len table_name password ) ] ],
      Sybase   => [ [ qw( textsize table_name password ) ] ],
    );

my %ApacheSessionFlexParams =
    ( store =>
      { MySQL    => [ [ qw( data_source user_name ) ],
		      [ qw( handle ) ] ],
	Postgres => $ApacheSessionParams{Postgres},
	File     => [ [ qw( directory ) ] ],
	DB_File  => [ [ qw( file_name ) ] ],
	PHP      => $ApacheSessionParams{PHP},
      },
      lock =>
      { MySQL     => [ [ qw( lock_data_source lock_user_name ) ],
		       [ qw( lock_handle ) ] ],
	File      => [ [ ] ],
	Null      => [ [ ] ],
	Semaphore => [ [ ] ],
      },
      generate =>
      { MD5          => [ [ ] ],
	ModUniqueId  => [ [ ] ],
	ModUsertrack => [ [ qw( mod_usertrack_cookie_name )  ] ],
      },
      serialize =>
      { Storable => [ [ ] ],
	Base64   => [ [ ] ],
	Sybase   => [ [ ] ],
	UUEncode => [ [ ] ],
	PHP      => [ [ ] ],
      },
    );

@{ $ApacheSessionFlexParams{store} }{ qw( Informix Oracle Sybase ) } =
    ( $ApacheSessionFlexParams{store}{Postgres} ) x 3;

my %OptionalApacheSessionFlexParams =
    ( store => { map { $_ => $OptionalApacheSessionParams{$_} }
                 qw( MySQL Postgres Informix Oracle Sybase ) },
    );

sub _SetValidParams {
    my $class = shift;

    my %extra;
    for my $hash ( \%ApacheSessionParams,
                   \%OptionalApacheSessionParams,
                   @ApacheSessionFlexParams{ qw( store lock generate serialize ) },
                   @OptionalApacheSessionFlexParams{ qw( store lock generate serialize ) },
                 )
    {
        for my $p ( map { @$_ } map { @$_ } values %$hash )
        {
            my $h;
            if ( ref $p ) {
                # we assume its a hash of names/parameter specifications
                $h = $p;
            } elsif (!$params{$p}) {
                # its a new parameter defined by a scalar, default to SCALAR value
                $h = { $p => { optional => 1, type => SCALAR } };
            } else {
                # its a scalar option we already know.
                next;
            }
            # now expand the options
            foreach my $name (keys %$h) {
                next if $params{$name};
                $extra{$p} = $h->{$name};
            }
        }
    }

    $class->valid_params( %extra, %params );
    $class->SetStudlyForms();
}
__PACKAGE__->_SetValidParams();

my %StudlyForm;
sub SetStudlyForms
{
    %StudlyForm =
        ( map { $_ => _studly_form($_) }
          map { ref $_ ? @$_ :$_ }
          map { @$_ }
          ( values %ApacheSessionParams ),
          ( values %OptionalApacheSessionParams ),
          ( map { values %{ $ApacheSessionFlexParams{$_} } }
            keys %ApacheSessionFlexParams ),
          ( map { values %{ $OptionalApacheSessionFlexParams{$_} } }
            keys %OptionalApacheSessionFlexParams ),
        );

    # why Apache::Session does this I do not know
    $StudlyForm{textsize} = 'textsize';
}

sub _studly_form
{
    my $string = shift;
    $string =~ s/(?:^|_)(\w)/\U$1/g;
    return $string;
}

sub RegisterClass {
    my $class = shift;
    my %p = validate( @_, { name => { type => SCALAR },
                            required => { type => SCALAR | ARRAYREF, default => [ [ ] ] },
                            optional => { type => SCALAR | ARRAYREF, default => [ ] },
                          },
                    );

    $p{name} =~ s/^Apache::Session:://;

    $ApacheSessionParams{ $p{name} } =
        ( ref $p{required}
          ? $p{required}
          : $ApacheSessionParams{ $p{required} }
        );

    $OptionalApacheSessionParams{ $p{name} } =
        ( ref $p{optional}
          ? [ $p{optional} ]
          : $OptionalApacheSessionParams{ $p{optional} }
        );

    $class->_SetValidParams();
}

sub RegisterFlexClass {
    my $class = shift;
    my %p = validate( @_, { type => { type => SCALAR,
                                      regex => qr/^(?:store|lock|generate|serialize)/,
                                    },
                            name => { type => SCALAR },
                            required => { type => SCALAR | ARRAYREF, default => [ [ ] ] },
                            optional => { type => SCALAR | ARRAYREF, default => [ ]  },
                          },
                    );

    $p{name} =~ s/^Apache::Session:://;
    $p{name} =~ s/^\Q$p{type}\E:://i;

    $ApacheSessionFlexParams{ $p{type} }{ $p{name} } =
        ( ref $p{required}
          ? $p{required}
          : $ApacheSessionFlexParams{ $p{type} }{ $p{required} }
        );

    $OptionalApacheSessionFlexParams{ $p{type} }{ $p{name} } =
        ( ref $p{optional}
          ? [ $p{optional} ]
          : $OptionalApacheSessionFlexParams{ $p{type} }{ $p{optional} }
        );

    $class->_SetValidParams();
}

sub new
{
    my $class = shift;
    my %p = @_;

    my $self = $class->SUPER::new(%p);

    $self->_check_session_params;
    $self->_set_session_params;

    if ( $self->{use_cookie} && ! ( $ENV{MOD_PERL} || $self->{header_object} ) )
    {
        param_error
            "The header_object parameter is required in order to use cookies outside of mod_perl";
    }

    my $session_class = "Apache::Session::$self->{session_class_piece}";
    unless ( $session_class->can('TIEHASH') )
    {
        eval "require $session_class";
        die $@ if $@;
    }

    $self->_make_session( $p{session_id} );

    $self->_bake_cookie
        if $self->{use_cookie} && ! $self->{cookie_is_baked};

    return $self;
}

sub _check_session_params
{
    my $self = shift;

    $self->{session_class_piece} = $self->{class};
    $self->{session_class_piece} =~ s/^Apache::Session:://;

    my $sets = $ApacheSessionParams{ $self->{session_class_piece} }
	or param_error "Invalid session class: $self->{class}";

    $self->_check_sets( $sets, 'session', $self->{class} )
        if grep { @$_ } @$sets;

    if ( $self->{session_class_piece} eq 'Flex' )
    {
	foreach my $key ( keys %ApacheSessionFlexParams )
	{
	    my $subclass = $self->{$key};
	    my $sets = $ApacheSessionFlexParams{$key}{$subclass}
		or param_error "Invalid class for $key: $self->{$key}";

            $self->_check_sets( $sets, $key, $subclass )
                if grep { @$_ } @$sets;
	}
    }
}

sub _check_sets
{
    my $self = shift;
    my $sets = shift;
    my $type = shift;
    my $class = shift;

    my @missing;
    foreach my $set (@$sets)
    {
        my @matched = grep { exists $self->{$_} } @$set;

        return if @matched == @$set;

        @missing = grep { ! exists $self->{$_} } @$set;
    }

    param_error "Some or all of the required parameters for your chosen $type class ($class) were provided."
                . "  The following parameters were missing: @missing\n";
}

sub _set_session_params
{
    my $self = shift;

    my %params;

    $self->_sets_to_params
	( $ApacheSessionParams{ $self->{session_class_piece} },
	  \%params );

    $self->_sets_to_params
	( $OptionalApacheSessionParams{ $self->{session_class_piece} },
	  \%params );


    if ( $self->{session_class_piece} eq 'Flex' )
    {
	foreach my $key ( keys %ApacheSessionFlexParams )
	{
	    my $subclass = $self->{$key};
	    $params{ $StudlyForm{$key} } = $subclass;

	    $self->_sets_to_params
		( $ApacheSessionFlexParams{$key}{$subclass},
		  \%params );

	    $self->_sets_to_params
		( $OptionalApacheSessionFlexParams{$key}{$subclass},
		  \%params );
	}
    }

    $self->{params} = \%params;

    $self->_set_cookie_fields
        if $self->{use_cookie};
}

sub _set_cookie_fields
{
    my $self = shift;

    my $cookie_class;
    if ($MOD_PERL)
    {
        $cookie_class =
            $MOD_PERL == 2 ? 'Apache2::Cookie' : 'Apache::Cookie';

        eval "require $cookie_class"
            unless $cookie_class->can('new');
    }

    unless ( $cookie_class && $cookie_class->can('new' ) )
    {
        require CGI::Cookie;
        $cookie_class = 'CGI::Cookie';
    }

    $self->{cookie_class} = $cookie_class;

    if ( $self->{cookie_class} eq 'CGI::Cookie' )
    {
        $self->{new_cookie_args} = [];
        $self->{fetch_cookie_args} = [];
    }
    else
    {
        $self->{new_cookie_args} =
            [ $MOD_PERL == 2
              ? Apache2::RequestUtil->request
              : Apache->request
            ];

        $self->{fetch_cookie_args} =
            ( $MOD_PERL == 2
              ? $self->{new_cookie_args}
              : []
            );
        $self->{bake_cookie_args} =
            ( $MOD_PERL == 2
              ? $self->{new_cookie_args}
              : []
            );
    }
}

sub _sets_to_params
{
    my $self = shift;
    my $sets = shift;
    my $params = shift;

    foreach my $set (@$sets)
    {
	foreach my $key (@$set)
	{
	    if ( exists $self->{$key} )
	    {
		$params->{ $StudlyForm{$key} } =
		    $self->{$key};
	    }
	}
    }
}

sub _make_session
{
    my $self = shift;
    my $session_id = shift;

    return if
        defined $session_id && $self->_try_session_id( $session_id );

    my $id = $self->_get_session_id;
    return if defined $id && $self->_try_session_id($id);

    if ( defined $self->{param_name} )
    {
        my $id = $self->_get_session_id_from_args;

        return if defined $id && $self->_try_session_id($id);
    }

    if ( $self->{use_cookie} )
    {
        my $id = $self->_get_session_id_from_cookie;

        if ( defined $id && $self->_try_session_id($id) )
        {
            $self->{cookie_is_baked} = 1
                unless $self->{cookie_resend};

            return;
        }
    }

    # make a new session id
    $self->_try_session_id(undef);
}

# for subclasses
sub _get_session_id { return }

sub _get_session_id_from_args
{
    my $self = shift;

    return $self->{param_object}->param( $self->{param_name} );
}

sub _get_session_id_from_cookie
{
    my $self = shift;

    if ( $MOD_PERL == 2 )
    {
        my $jar = Apache2::Cookie::Jar->new( @{ $self->{fetch_cookie_args} } );
        my $c   = $jar->cookies( $self->{cookie_name} );
        return $c->value if $c;
    }
    else
    {
        my %c = $self->{cookie_class}->fetch( @{ $self->{fetch_cookie_args} } );

        return $c{ $self->{cookie_name} }->value
            if exists $c{ $self->{cookie_name} };
    }
    return undef;
}

sub _try_session_id
{
    my $self = shift;
    my $session_id = shift;

    return 1 if ( $self->{session} &&
                  defined $session_id &&
                  $self->{session_id} eq $session_id );

    my %s;
    {
	local $SIG{__DIE__};
	eval
	{
	    tie %s, "Apache::Session::$self->{session_class_piece}",
                $session_id, $self->{params};
	};

        if ( $@ || ! tied %s || ! $s{_session_id} )
        {
            $self->_handle_tie_error( $@, $session_id );
            return;
        }
    }

    untie %{ $self->{session} } if $self->{session};

    $self->{session} = \%s;
    $self->{session_id} = $s{_session_id};

    $self->{cookie_is_baked} = 0;

    return 1;
}

sub _handle_tie_error
{
    my $self = shift;
    my $err = shift;
    my $session_id = shift;

    if ( $err =~ /Object does not exist/ && defined $session_id )
    {
        return if $self->{allow_invalid_id};

        Apache::Session::Wrapper::Exception::NonExistentSessionID->throw
            ( error => "Invalid session id: $session_id",
              session_id => $session_id );
    }
    else
    {
        my $error =
            $err ? $err : "Tying to Apache::Session::$self->{session_class_piece} failed but did not throw an exception";
        die $error;
    }
}

sub _bake_cookie
{
    my $self = shift;

    my $expires = shift || $self->{cookie_expires};
    $expires = undef if defined $expires && $expires =~ /^session$/i;

    my $domain = $self->{cookie_domain};

    my $cookie =
        $self->{cookie_class}->new
            ( @{ $self->{new_cookie_args} },
              -name    => $self->{cookie_name},
              # Apache2::Cookie will return undef if we pass undef for
              # -value.
              -value   => ( $self->{session_id} || '' ),
              ( defined $expires
                ? ( -expires => $expires )
                : ()
              ),
              ( defined $domain
                ? ( -domain  => $domain )
                : ()
              ),
              -path    => $self->{cookie_path},
              -secure  => $self->{cookie_secure},
            );

    # If not running under mod_perl, CGI::Cookie->bake() will call
    # print() to send a cookie header right now, which may not be what
    # the user wants.
    if ( $cookie->can('bake') && ! $cookie->isa('CGI::Cookie') )
    {
        $cookie->bake( @{ $self->{bake_cookie_args} } );
    }
    else
    {
        my $header_object = $self->{header_object};
        for my $meth (@HeaderMethods)
        {
            if ( $header_object->can($meth) )
            {
                $header_object->$meth->add( 'Set-Cookie' => $cookie );
                last;
            }
        }
    }

    # always set this even if we skipped actually setting the cookie
    # to avoid resending it.  this keeps us from entering this method
    # over and over
    $self->{cookie_is_baked} = 1
        unless $self->{cookie_resend};
}

sub session
{
    my $self = shift;
    my %p = validate( @_,
		      { session_id =>
			{ type => SCALAR,
                          optional => 1,
			},
		      } );

    if ( ! $self->{session} || %p )
    {
        $self->_make_session( $p{session_id} );

        $self->_bake_cookie
            if $self->{use_cookie} && ! $self->{cookie_is_baked};
    }

    return $self->{session};
}

sub delete_session
{
    my $self = shift;

    return unless $self->{session};

    my $session = delete $self->{session};

    (tied %$session)->delete;

    delete $self->{session_id};

    $self->_bake_cookie('-1d') if $self->{use_cookie};
}

sub cleanup_session
{
    my $self = shift;

    if ( $self->{always_write} )
    {
	if ( $self->{session}->{___force_a_write___} )
	{
	    $self->{session}{___force_a_write___} = 0;
	}
	else
	{
	    $self->{session}{___force_a_write___} = 1;
	}
    }

    undef $self->{session};
}

sub DESTROY { $_[0]->cleanup_session }


1;

__END__

=head1 NAME

Apache::Session::Wrapper - A simple wrapper around Apache::Session

=head1 SYNOPSIS

 my $wrapper =
     Apache::Session::Wrapper->new( class  => 'MySQL',
                                    handle => $dbh,
                                    cookie_name => 'example-dot-com-cookie',
                                  );

 # will get an existing session from a cookie, or create a new session
 # and cookie if needed
 $wrapper->session->{foo} = 1;

=head1 DESCRIPTION

This module is a simple wrapper around Apache::Session which provides
some methods to simplify getting and setting the session id.

It can uses cookies to store the session id, or it can look in a
provided object for a specific parameter.  Alternately, you can simply
provide the session id yourself in the call to the C<session()>
method.

If you're using Mason, you should probably take a look at
C<MasonX::Request::WithApacheSession> first, which integrates this
module directly into Mason.

=head1 METHODS

This class provides the following public methods:

=over 4

=item * new

This method creates a new C<Apache::Session::Wrapper> object.

If the parameters you provide are not correct (wrong type, missing
parameters, etc.), this method throws an
C<Apache::Session::Wrapper::Exception::Params> exception.  You can
treat this exception as a string if you want.

=item * session

This method returns a hash tied to the C<Apache::Session> class.

This method accepts an optional "session_id" parameter.

=item * delete_session

This method deletes the existing session from persistent storage.  If
you are using the built-in cookie handling, it also deletes the cookie
in the browser.

=back

=head1 CONFIGURATION

This module accepts quite a number of parameters, most of which are
simply passed through to C<Apache::Session>.  For this reason, you are
advised to familiarize yourself with the C<Apache::Session>
documentation before attempting to configure this module.

You can also register C<Apache::Session> classes, or the classes used
for doing the work in C<Apache::Session::Flex>. See L<REGISTERING
CLASSES> for details.

=head2 Supported Classes

The following classes are already supported and do not require
registration:

=over 4

=item * Apache::Session::MySQL

=item * Apache::Session::Postgres

=item * Apache::Session::Oracle

=item * Apache::Session::Informix

=item * Apache::Session::Sybase

=item * Apache::Session::File

=item * Apache::Session::DB_File

=item * Apache::Session::PHP

=item * Apache::Session::Flex

=back

The following classes can be used with C<Apache::Session::Flex>:

=over 4

=item * Apache::Session::Store::MySQL

=item * Apache::Session::Store::Postgres

=item * Apache::Session::Store::Informix

=item * Apache::Session::Store::Oracle

=item * Apache::Session::Store::Sybase

=item * Apache::Session::Store::File

=item * Apache::Session::Store::DB_File

=item * Apache::Session::Store::PHP

=item * Apache::Session::Lock::MySQL

=item * Apache::Session::Lock::File

=item * Apache::Session::Lock::Null

=item * Apache::Session::Lock::Semaphore

=item * Apache::Session::Generate::MD5

=item * Apache::Session::Generate::ModUsertrack

=item * Apache::Session::Serialize::Storable

=item * Apache::Session::Serialize::Base64

=item * Apache::Session::Serialize::Sybase

=item * Apache::Session::Serialize::UUEncode

=item * Apache::Session::Serialize::PHP

=back

=head2 Generic Parameters

=over 4

=item * class  =>  class name

The name of the C<Apache::Session> subclass you would like to use.

This module will load this class for you if necessary.

This parameter is required.

=item * always_write  =>  boolean

If this is true, then this module will ensure that C<Apache::Session>
writes the session.  If it is false, the default C<Apache::Session>
behavior is used instead.

This defaults to true.

=item * allow_invalid_id  =>  boolean

If this is true, an attempt to create a session with a session id that
does not exist in the session storage will be ignored, and a new
session will be created instead.  If it is false, a
C<Apache::Session::Wrapper::Exception::NonExistentSessionID> exception
will be thrown instead.

This defaults to true.

=item * session_id  =>  string

Try this session id first and use it if it exist. If the session does
not exist, it will ignore this parameter and make a new session.

=back

=head2 Cookie-Related Parameters

=over 4

=item * use_cookie  =>  boolean

If true, then this module will use one of C<Apache::Cookie>,
C<Apache2::Cookie> or C<CGI::Cookie> (as appropriate) to set and read
cookies that contain the session id.

=item * cookie_name  =>  name

This is the name of the cookie that this module will set.  This
defaults to "Apache-Session-Wrapper-cookie".
Corresponds to the C<Apache::Cookie> "-name" constructor parameter.

=item * cookie_expires  =>  expiration

How long before the cookie expires.  This defaults to 1 day, "+1d".
Corresponds to the "-expires" parameter.

As a special case, you can set this value to "session" to have the
"-expires" parameter set to undef, which gives you a cookie that
expires at the end of the session.

=item * cookie_domain  =>  domain

This corresponds to the "-domain" parameter.  If not given this will
not be set as part of the cookie.

If it is undefined, then no "-domain" parameter will be given.

=item * cookie_path  =>  path

Corresponds to the "-path" parameter.  It defaults to "/".

=item * cookie_secure  =>  boolean

Corresponds to the "-secure" parameter.  It defaults to false.

=item * cookie_resend  =>  boolean

By default, this parameter is true, and the cookie will be sent for
I<every request>.  If it is false, then the cookie will only be sent
when the session is I<created>.  This is important as resending the
cookie has the effect of updating the expiration time.

=item * header_object => object

When running outside of mod_perl, you must provide an object to which
the cookie header can be added.  This object must provide an
C<err_headers_out()> or C<headers_out()> method.

Under mod_perl 1, this will default to the object returned by C<<
Apache->request() >>. Under mod_perl 2 we call C<<
Apache2::RequestUtil->request() >>

=back

=head2 Query/POST-Related Parameters

=over 4

=item * param_name  =>  name

If set, then this module will first look for the session id in the
object specified via "param_object".  This parameter determines the
name of the parameter that is checked.

If you are also using cookies, then the module checks the param object
I<first>, and then it checks for a cookie.

=item * param_object  =>  object

This should be an object that provides a C<param()> method.  This
object will be checked to see if it contains the parameter named in
"params_name".  This object will probably be a C<CGI.pm> or
C<Apache::Request> object, but it doesn't have to be.

=back

=head2 Apache::Session-related Parameters

These parameters are simply passed through to C<Apache::Session>.

=over 4

=item * data_source  =>  DSN

Corresponds to the C<DataSource> parameter passed to the DBI-related
session modules.

=item * user_name  =>  user name

Corresponds to the C<UserName> parameter passed to the DBI-related
session modules.

=item * password  =>  password

Corresponds to the C<Password> parameter passed to the DBI-related
session modules.  Defaults to undef.

=item * handle =>  DBI handle

Corresponds to the C<Handle> parameter passed to the DBI-related
session modules.  This cannot be set via the F<httpd.conf> file,
because it needs to be an I<actual Perl variable>, not the I<name> of
that variable.

=item * table_name  =>  table name

Corresponds to the C<TableName> paramaeter passed to DBI-related
modules.

=item * lock_data_source  =>  DSN

Corresponds to the C<LockDataSource> parameter passed to
C<Apache::Session::MySQL>.

=item * lock_user_name  =>  user name

Corresponds to the C<LockUserName> parameter passed to
C<Apache::Session::MySQL>.

=item * lock_password  =>  password

Corresponds to the C<LockPassword> parameter passed to
C<Apache::Session::MySQL>.  Defaults to undef.

=item * lock_handle  =>  DBI handle

Corresponds to the C<LockHandle> parameter passed to the DBI-related
session modules.  As with the C<handle> parameter, this cannot
be set via the F<httpd.conf> file.

=item * commit =>  boolean

Corresponds to the C<Commit> parameter passed to the DBI-related
session modules.

=item * transaction  =>  boolean

Corresponds to the C<Transaction> parameter.

=item * directory  =>  directory

Corresponds to the C<Directory> parameter passed to
C<Apache::Session::File>.

=item * lock_directory  =>  directory

Corresponds to the C<LockDirectory> parameter passed to
C<Apache::Session::File>.

=item * file_name  =>  file name

Corresponds to the C<FileName> parameter passed to
C<Apache::Session::DB_File>.

=item * store  =>  class

Corresponds to the C<Store> parameter passed to
C<Apache::Session::Flex>.

=item * lock  =>  class

Corresponds to the C<Lock> parameter passed to
C<Apache::Session::Flex>.

=item * generate  =>  class

Corresponds to the C<Generate> parameter passed to
C<Apache::Session::Flex>.

=item * serialize  =>  class

Corresponds to the C<Serialize> parameter passed to
C<Apache::Session::Flex>.

=item * textsize  =>  size

Corresponds to the C<textsize> parameter passed to
C<Apache::Session::Sybase>.

=item * long_read_len  =>  size

Corresponds to the C<LongReadLen> parameter passed to
C<Apache::Session::MySQL>.

=item * n_sems  =>  number

Corresponds to the C<NSems> parameter passed to
C<Apache::Session::Lock::Semaphore>.

=item * semaphore_key  =>  key

Corresponds to the C<SemaphoreKey> parameter passed to
C<Apache::Session::Lock::Semaphore>.

=item * mod_usertrack_cookie_name  =>  name

Corresponds to the C<ModUsertrackCookieName> parameter passed to
C<Apache::Session::Generate::ModUsertrack>.

=item * save_path  =>  path

Corresponds to the C<SavePath> parameter passed to
C<Apache::Session::PHP>.

=back

=head1 HOW COOKIES ARE HANDLED

When run under mod_perl, this module attempts to first use
C<Apache::Cookie> for cookie-handling.  Otherwise it uses
C<CGI::Cookie> as a fallback.

If it ends up using C<CGI::Cookie> then you must provide a
"header_object" parameter. This object must have an
C<err_headers_out()> or C<headers_out()> method. It looks for these
methods in that order. The method is expected to return an object with
an API like C<Apache::Table>. It calls C<add()> on the returned method
to add a "Set-Cookie" header.

=head1 REGISTERING CLASSES

In order to support any C<Apache::Session> subclasses, this module
provides a simple registration mechanism.

You can register an C<Apache::Session> subclass, or a class intended
to provide a class that implements something required by
C<Apache::Session::Flex>.

=head2 Registering a Complete Subclass

This is done by calling C<< Apache::Session::Wrapper->RegisterClass() >>:

  Apache::Session::Wrapper->RegisterClass
      ( name     => 'MyClass',
        required => [ [ qw( param1 param2 ) ],
                      [ qw( param3 param4 ) ] ],
        optional => [ 'optional_p' ],
      );

  Apache::Session::Wrapper->RegisterClass
      ( name     => 'Apache::Session::MyFile',
        required => 'File',
        optional => 'File',
      );

The C<RegisterClass()> method takes the following options:

=over 4

=item * name

This should be the name of the class you are registering. The actual
class must start with "Apache::Session::", but this part does not need
to be included when registering the class (it's optional).

=item * required

These are the required parameters for this class.

The value of this parameter can either be a string or a reference to
an array of array references.

If it is a string, then it identifies an existing C<Apache::Session>
subclass which is already registered or built-in, like "File" or
"Postgres".

If it an array reference, then I<that reference> should in turn
contain one or more array references. Each of those contained
references represents one set of required parameters. When an
C<Apache::Session::Wrapper> object is constructed, only one of these
sets must be passed in. For example:

  required => [ [ qw( p1 p2 ) ],
                [ qw( p2 p3 p4 ) ] ]

This says that either "p1" and "p2" must be provided, I<or> "p2",
"p3", and "p4".

If there are no required parameters for this class, then the
"required" parameter can be omitted.

=item * optional

This specifies optional parameters, and should just be a simple array
reference.

=back

=head2 Registering a Subclass for Flex

Registering a subclass that can be used with C<Apache::Session::Flex>
is very similar to registering a complete class:

  Apache::Session::Wrapper->RegisterFlexClass
      ( name     => 'MyClass',
        type     => 'Store',
        required => [ [ qw( param1 param2 ) ],
                      [ qw( param3 param4 ) ] ],
        optional => [ 'optional_p' ],
      );

  Apache::Session::Wrapper->RegisterFlexClass
      ( name     => 'Apache::Session::Store::MyFile',
        type     => 'store',
        required => 'File',
        optional => 'File',
      );

The C<RegisterFlexClass()> method has the same parameters as
C<RegisterClass()>, but it also requires a "type" parameter. This must
be one of "store", "lock", "generate", or "serialize".

=head1 SUBCLASSING

This class provides a simple hook for subclasses.  Before trying to
get a session id from the URL or cookie, it calls a method named
C<_get_session_id()>.  In this class, that method is a no-op, but you
can override this in a subclass.

This class is a C<Class::Container> subclass, so if you accept
additional constructor parameters, you should declare them via the
C<valid_params()> method.

=head1 SUPPORT

As can be seen by the number of parameters above, C<Apache::Session>
has B<way> too many possibilities for me to test all of them.  This
means there are almost certainly bugs.

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache%3A%3ASession%3A%3AWrapper
or via email at bug-apache-session-wrapper@rt.cpan.org.

Support questions can be sent to me at my email address, shown below.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2003-2006 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
