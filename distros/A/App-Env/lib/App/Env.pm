# --8<--8<--8<--8<--
#
# Copyright (C) 2007-2015 Smithsonian Astrophysical Observatory
#
# This file is part of App::Env
#
# App::Env is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package App::Env;

use 5.00800;

use strict;
use warnings;

use Scalar::Util qw[ blessed ];
use Storable qw[ dclone ];

use Carp;
use Params::Validate qw(:all);


# need to distinguish between a non-existent module
# and one which has compile errors.
use Module::Find qw( );


our $VERSION = '0.33';

use overload
  '%{}' => '_envhash',
  '""'  => 'str',
  fallback => 1;


#-------------------------------------------------------


my %existsModule;

sub _loadModuleList
{
    %existsModule = ();

    for my $path ( Module::Find::findallmod( 'App::Env' ) )
    {
        # greedy match picks up full part of path
        my ( $base, $app ) = $path =~ /^(.*)::(.*)/;

        # store lowercased module
        $existsModule{$base . '::' . lc $app} = $path;
    }

    return;
}


sub _existsModule
{
    my ( $path ) = @_;

    # reconstruct path with lowercased application name.
    # greedy match picks up full part of path
    my ( $base, $app ) = $path =~ /^(.*)::(.*)/;
    $path = $base . '::' . lc $app;

    # (re)load cache if we can't find the module in the list
    _loadModuleList
      unless $existsModule{$path};

    # really check
    return $existsModule{$path};
}

#-------------------------------------------------------

# allow site specific site definition
BEGIN {

    if ( ! exists $ENV{APP_ENV_SITE} && _existsModule('App::Env::Site') )
    {
        eval { require App::Env::Site };
        croak( ref $@ ? $@ : "Error loading App::Env::Site: $@\n" ) if $@;
    }
}

#-------------------------------------------------------

# Options
my %SharedOptions =
  (  Force    => { default => 0     },
     Cache    => { default => 1     },
     Site     => { default => undef },
     CacheID  => { default => undef },
     Temp     => { default => 0     },
     SysFatal => { default => 0, type => BOOLEAN },
  );

my %ApplicationOptions =
  (
     AppOpts  => { default => {} , type => HASHREF   },
     %SharedOptions,
  );

my %CloneOptions = %{ dclone({ map { $_ => $SharedOptions{$_} } qw[ CacheID Cache SysFatal ]} ) };
$CloneOptions{Cache}{default} = 0;

my %TempOptions = %{ dclone({ map { $_ => $SharedOptions{$_} } qw[ SysFatal Temp ]} ) };

# options for whom defaults may be changed.  The values
# in %OptionDefaults are references to the same hashes as in
# ApplicationOptions & SharedOptions, so modifying them will
# modify the others.
my @OptionDefaults = qw( Force Cache Site SysFatal );
my %OptionDefaults;
@OptionDefaults{@OptionDefaults} = @ApplicationOptions{@OptionDefaults};

# environment cache
our %EnvCache;

#-------------------------------------------------------
#-------------------------------------------------------


# import one or more environments.  this may be called in the following
# contexts:
#
#    * as a class method, i.e.
#	use App:Env qw( application )
#	App:Env->import( $application )
#
#    * as a class function (just so as not to confuse folks
#       App::Env::import( $application )
#
#    * as an object method
#       $env->import

sub import {

    my $this = $_[0];

    # object method?
    if ( blessed $this && $this->isa(__PACKAGE__) )
    {
	my $self = shift;
	die( __PACKAGE__, "->import: too many arguments\n" )
	  if @_;

	while( my ( $key, $value ) = each %{$self} )
	{
	    $ENV{$key} = $value;
	}
    }

    else
    {

	# if class method, get rid of class in argument list
	shift if ! ref $this && $this eq __PACKAGE__;

	# if no arguments, nothing to do.  "use App::Env;" will cause this.
	return unless @_;

        # if the only argument is a hash, it sets defaults
        if ( @_ == 1 && 'HASH' eq ref $_[0] )
        {
            config( @_ );
            return;
        }

	App::Env->new( @_ )->import;
    }
}


# class method
# retrieve a cached environment.
sub retrieve {

    my ( $cacheid ) = @_;

    my $self;

    if ( defined $EnvCache{ $cacheid } )
    {
	$self = __PACKAGE__->new();

	$self->_var( app => $EnvCache{ $cacheid } );
    }


    return $self;
}

#-------------------------------------------------------

sub config {

    my %default = validate( @_, \%OptionDefaults );

    $OptionDefaults{$_}{default} = $default{$_} for keys %default;

    return;
}

#-------------------------------------------------------

sub new
{
    my $class = shift;

    my $opts = 'HASH' eq ref $_[-1] ? pop : {};

    # %{} is overloaded, so an extra reference is required to avoid
    # an infinite loop when doing things like $self->{}.  instead,
    # use $$self->{}
    my $self = bless \ { }, $class;

    $self->_load_envs( @_, $opts ) if @_;

    return $self;
}

#-------------------------------------------------------

sub clone
{
    my $self = shift;

    my %nopt = validate( @_, \%CloneOptions );

    my $clone = dclone( $self );
    delete ${$clone}->{id};

    # create new cache id
    $clone->_app->mk_cacheid( CacheID => defined $nopt{CacheID} ? $nopt{CacheID} : $self->lobject_id );

    my %opt = ( %{$clone->_opt}, %nopt );
    $clone->_opt( \%opt );

    $clone->cache( $opt{Cache} );

    return $clone;
}

#-------------------------------------------------------

sub _load_envs
{
    my $self = shift;
    my @opts  = ( pop );
    my @apps = @_;

    # most of the following logic is for the case where multiple applications
    # are being loaded in one call.  Checking caching requires that we generate
    # a cacheid from the applications' cacheids.

    # if import is called as import( [$app, \%opts], \%shared_opts ),
    # this is equivalent to import( $app, { %shared_opts, %opts } ),
    # but we still validate %shared_opts as SharedOptions, just to be
    # precise.

    # if there's a single application passed as a scalar (rather than
    # an array containing the app name and options), treat @opts as
    # ApplicationOptions, else SharedOptions

    my %opts =  validate( @opts,
			  @apps == 1 && ! ref($apps[0])
			       ? \%ApplicationOptions
			       : \%SharedOptions );


    $opts{Cache} = 0 if $opts{Temp};

    # iterate through the applications to ensure that any application specific
    # options are valid and to form a basis for a multi-application
    # cacheid to check for cacheing.
    my @cacheids;
    my @Apps;
    for my $app ( @apps )
    {
	# initialize the application specific opts from the shared opts
	my %app_opt = %opts;

        # special filtering of options if this is part of a multi-app
        # merge
        if ( @apps > 1 )
        {
            # don't use the shared CacheID option
            delete $app_opt{CacheID};

            # don't cache individual apps in a merged environment,
            # as the cached environments will be polluted.
            delete $app_opt{Cache};

            # ignore a Force option.  This will be turned on later;
            # if set now it will prevent proper error checking
            delete $app_opt{Force};
        }

        # handle application specific options.
	if ( 'ARRAY' eq ref($app) )
	{
	    ( $app, my $opts ) = @$app;
	    croak( "$app: application options must be a hashref\n" )
	      unless 'HASH' eq ref $opts;

	    %app_opt = ( %app_opt, %$opts );

            if ( @apps > 1 )
            {
                for my $iopt ( qw( Cache Force ) )
                {
                  if ( exists $app_opt{$iopt})
                  {
                      croak( "$app: do not specify the $iopt option for individual applications in a merge\n" );
                      delete $app_opt{$iopt};
                  }
              }
            }
	}

        # set forced options for apps in multi-app merges, otherwise
        # the defaults will be set by the call to validate below.
        if ( @apps > 1 )
        {
            $app_opt{Force} = 1;
            $app_opt{Cache} = 0;
        }

	# validate possible application options and get default
	# values. Params::Validate wants a real array
	my ( @opts ) = %app_opt;

	# return an environment object, but don't load it. we need the
        # module name to create a cacheid for the merged environment.
        # don't load now to prevent unnecessary loading of uncached
        # environments if later it turns out this is a cached
        # multi-application environment
	%app_opt = ( validate( @opts, \%ApplicationOptions ));
	my $appo = App::Env::_app->new( pid => $self->lobject_id,
					app => $app,
					NoLoad => 1,
					opt => \%app_opt );
	push @cacheids, $appo->cacheid;
	push @Apps, $appo;
    }


    # create a cacheid for the multi-app environment
    my $cacheid = $opts{CacheId} || join( $;, @cacheids );
    my $App;

    # use cache if possible
    if ( ! $opts{Force} && exists $EnvCache{$cacheid} )
    {
	# if this is a temporary object and a cached version exists,
	# clone it and assign a new cache id.
	if ( $opts{Temp} )
	{
	    $App = dclone( $EnvCache{$cacheid} );

	    # should really call $self->cacheid here, but $self
	    # doesn't have an app attached to it yet so that'll fail.
	    $App->cacheid( $self->lobject_id );

	    # update Temp compatible options
	    $App->_opt( { %{$App->_opt}, map { $_ => $opts{$_} } keys %TempOptions } );
	}

	else
	{
	    $App = $EnvCache{$cacheid};
	}
    }

    # not cached; is this really just a single application?
    elsif ( @Apps == 1 )
    {
	$App = shift @Apps;
	$App->load;
    }

    # ok, create new environment by iteration through the apps
    else
    {
        # we don't want to merge environments, as apps may
        # modify a variable that we don't know how to merge.
        # PATH is easy, but we have no idea what might be in
        # others.  so, let the apps handle it.

        # apps get loaded in the current environment.
        local %ENV = %ENV;

	my @modules;
	foreach my $app ( @Apps )
	{
	    push @modules, $app->module;

            # embrace new merged environment
            %ENV = %{$app->load};
	}

	$App = App::Env::_app->new( ref => $self,
				    env => { %ENV },
				    module => join( $;, @modules),
				    cacheid => $cacheid,
				    opt => \%opts,
				  );

        if ( $opts{Cache} ) { $App->cache; }
    }

    # record the final things we need to know.
    $self->_var( app     => $App );
}


#-------------------------------------------------------

# simple accessors to reduce confusion because of double reference in $self

sub _var {
    my $self = shift;
    my $var  = shift;

    ${$self}->{$var} = shift  if @_;

    return ${$self}->{$var};
}

sub module   { $_[0]->_app->module }
sub cacheid  { $_[0]->_app->cacheid }
sub _cacheid { my $self = shift; $self->app->cacheid(@_) }
sub _opt     { my $self = shift; $self->_app->_opt(@_) }
sub _app     { $_[0]->_var('app') }
sub _envhash { $_[0]->_app->{ENV} }

# would rather use Object::ID but it uses Hash::FieldHash which
# (through no fault of its own:
# http://rt.cpan.org/Ticket/Display.html?id=58030 ) stringify's the
# passed reference on pre 5.10 perls, which causes problems.

# stolen as much as possible from Object::ID to keep the interface the same
{
    my $Last_ID = "a";

=pod

=begin Pod::Coverage

=item lobject_id

=end Pod::Coverage

=cut

    sub lobject_id {
        my $self = shift;

        return $self->_var('id') if defined $self->_var('id');
        return $self->_var('id', ++$Last_ID);
    }
}

#-------------------------------------------------------

sub cache
{
    my ( $self, $cache ) = @_;

    defined $cache or
      croak( "missing or undefined cache argument\n" );

    if ( $cache )
    {
	$self->_app->cache;
    }
    else
    {
	$self->_app->uncache;
    }
}

sub uncache
{
    my %opt = validate( @_, {
			     All     => { default => 0,     type => SCALAR },
			     App     => { default => undef, type => SCALAR },
			     Site    => { default => undef, type => SCALAR },
			     CacheID => { default => undef, type => SCALAR },
			    } );

    if ( $opt{All} )
    {
	delete $opt{All};
	croak( "can't specify All option with other options\n" )
	  if grep { defined $_ } values %opt;

	delete $EnvCache{$_} foreach keys %EnvCache;
    }

    elsif ( defined $opt{CacheID} )
    {
	my $cacheid = delete $opt{CacheID};
	croak( "can't specify CacheID option with other options\n" )
	  if grep { defined $_ } values %opt;

	delete $EnvCache{$opt{CacheID}};
    }
    else
    {
	croak( "must specify App or CacheID options\n" )
	  unless defined $opt{App};

        $opt{Site} ||= _App_Env_Site();

        # don't use normal rules for Site specification as we're trying
        # to delete a specific one.
	delete $EnvCache{ _modulename( $opt{Site}, $opt{App} )};
    }

    return;
}

#-------------------------------------------------------

sub _modulename
{
    return join( '::', 'App::Env', @_ );
}


#-------------------------------------------------------

# construct a module name based upon the current or requested site.
# requires the module if found.  returns the module name if module is
# found, false if not, die's if require fails

sub _require_module
{
    my ( $app, $usite, $loop, $app_opts ) = @_;

    $app_opts ||= {};

    $loop ||= 1;
    die( "too many alias loops for $app\n" )
      if $loop == 10;

    my @sites = _App_Env_Site();
    push @sites, $usite
      if defined $usite && $usite ne '';

    # check possible sites, in turn.
    my ( $module ) =
      grep { defined $_ }
        ( map { _existsModule( _modulename( $_, $app ) ) } @sites ),
          _existsModule( _modulename( $app ) );

    if ( defined $module )
    {
        ## no critic ( ProhibitStringyEval );
        eval "require $module"
          or die $@;

        # see if this is an alias
        if ( my $alias = $module->can('alias') )
        {
            ( $app, my $napp_opts ) = $alias->();
            @{$app_opts}{keys %$napp_opts} = @{$napp_opts}{keys %$napp_opts}
              if $napp_opts;
            return _require_module( $app, $usite, ++$loop, $app_opts );
        }
    }

    else
    {
        return;
    }

    return ( $module, $app_opts );
}

#-------------------------------------------------------

# consolidate handling of APP_ENV_SITE environment variable

sub _App_Env_Site {

    return $ENV{APP_ENV_SITE}
      if exists $ENV{APP_ENV_SITE} && $ENV{APP_ENV_SITE} ne '';

    return;
}

#-------------------------------------------------------


sub _exclude_param_check
{
         ! ref $_[0]
      || 'ARRAY'  eq ref $_[0]
      || 'Regexp' eq ref $_[0]
      || 'CODE'   eq ref $_[0];
}

#-------------------------------------------------------

sub env     {
    my $self = shift;
    my @opts = ( 'HASH' eq ref $_[-1] ? pop : {} );

    # mostly a duplicate of what's in str(). ick.
    my %opt =
      validate( @opts,
	      { Exclude => { callbacks => { 'type' => \&_exclude_param_check },
			     default => undef
			   },
              } );

    # Exclude is only allowed in scalar calling context where
    # @_ is empty, has more than one element, or the first element
    # is not a scalar.
    die( "Cannot use Exclude in this calling context\n" )
      if $opt{Exclude} && ( wantarray() || ( @_ == 1 && ! ref $_[0] ) );


    my $include =  [ @_ ? @_ : qr/.*/ ];
    my $env = $self->_envhash;

    my @vars = $self->_filter_env( $include, $opt{Exclude} );

    ## no critic ( ProhibitAccessOfPrivateData )
    if ( wantarray() )
    {
        return map { exists $env->{$_} ? $env->{$_} : undef } @vars;
    }
    elsif ( @_ == 1 && ! ref $_[0] )
    {
        return exists $env->{$vars[0]} ? $env->{$vars[0]} : undef;
    }
    else
    {
        my %env;
        @env{@vars} = map { exists $env->{$_} ? $env->{$_} : undef } @vars;
        return \%env;
    }
}

#-------------------------------------------------------

sub setenv {

    my $self = shift;
    my $var  = shift;

    defined $var or
      croak( "missing variable name argument\n" );

    if ( @_ )
    {
        $self->_envhash->{$var} = $_[0];
    }
    else
    {
        delete $self->_envhash->{$var};
    }

}

#-------------------------------------------------------

# return an env compatible string
sub str
{
    my $self = shift;
    my @opts = ( 'HASH' eq ref $_[-1] ? pop : {} );

    # validate type.  Params::Validate doesn't do Regexp, so
    # this is a bit messy.
    my %opt =
      validate( @opts,
	      { Exclude => { callbacks => { 'type' => \&_exclude_param_check },
			     optional => 1
			   },
              } );

    my $include =  [@_ ? @_ : qr/.*/];

    if ( ! grep { $_ eq 'TERMCAP' } @$include )
    {
        $opt{Exclude} ||= [];
        $opt{Exclude} = [ $opt{Exclude} ] unless 'ARRAY' eq ref $opt{Exclude};
        push @{$opt{Exclude}}, 'TERMCAP';
    }

    my $env = $self->_envhash;
    ## no critic ( ProhibitAccessOfPrivateData )
    my @vars = grep { exists $env->{$_} }
                    $self->_filter_env( $include, $opt{Exclude} );
    return join( ' ',
		 map { "$_=" . _shell_escape($env->{$_}) } @vars
	       );
}

#-------------------------------------------------------

# return a list of included variables, in the requested
# order, based upon a list of include and exclude specs.
# variable names  passed as plain strings are not checked
# for existance in the environment.
sub _filter_env
{
    my ( $self, $included, $excluded ) = @_;

    my @exclude = $self->_match_var( $excluded );

    my %exclude = map { $_ => 1 } @exclude;
    return grep { ! $exclude{$_} } $self->_match_var( $included );
}

#-------------------------------------------------------

# return a list of variables which matched the specifications.
# this takes a list of scalars, coderefs, or regular expressions.
# variable names  passed as plain strings are not checked
# for existance in the environment.
sub _match_var
{
    my ( $self, $match ) = @_;

    my $env = $self->_envhash;

    $match = [ $match ] unless 'ARRAY' eq ref $match;

    my @keys;
    for my $spec ( @$match )
    {
	next unless defined $spec;

        if ( ! ref $spec )
        {
            # always return a plain name.  this allows
            #   @values = $env->env( @names) to work.
            push @keys, $spec;
        }
        elsif ( 'Regexp' eq ref $spec )
        {
            push @keys, grep { /$spec/ } keys %$env;
        }
        elsif ( 'CODE' eq ref $spec )
        {
            ## no critic ( ProhibitAccessOfPrivateData )
            push @keys, grep { $spec->($_, $env->{$_}) } keys %$env;
        }
        else
        {
            die( "match specification is of unsupported type: ",
                 ref $spec, "\n" );
        }
    }

    return @keys;
}

#-------------------------------------------------------


sub _shell_escape
{
  my $str = shift;

  # empty string
  if ( $str eq '' )
  {
    $str = "''";
  }

  # otherwise, escape all but the "known" non-magic characters.
  else
  {
    $str =~  s{([^\w/.:=\-+%])}{\\$1}go;
  }

  $str;
}

#-------------------------------------------------------

sub system
{
    my $self = shift;

    {
	local %ENV = %{$self};
        if ( $self->_opt->{SysFatal} )
        {
            require IPC::System::Simple;
            return IPC::System::Simple::system( @_ );
        }
        else
        {
            return CORE::system( @_ );
        }
    }
}

#-------------------------------------------------------

sub qexec
{
    my $self = shift;
    local %ENV = %{$self};

    require IPC::System::Simple;

    my ( @res, $res );

    if ( wantarray ) {  @res = eval { IPC::System::Simple::capture( @_ ) } }
    else             {  $res = eval { IPC::System::Simple::capture( @_ ) } }

    if ( $@ ) {

	die($@) if $self->_opt->{SysFatal};
	return;
    }

    return wantarray ? @res : $res;
}

#-------------------------------------------------------

sub capture
{
    my $self = shift;
    my @args = @_;

    local %ENV = %{$self};

    require Capture::Tiny;
    require IPC::System::Simple;

    my $sub = $self->_opt->{SysFatal}
            ? sub { IPC::System::Simple::system( @args ) }
	    : sub { CORE::system( @args ) }
	    ;

    my ( $stdout, $stderr );

    if ( wantarray )
    {

	( $stdout, $stderr ) = eval { Capture::Tiny::capture( $sub ) };

    }
    else
    {
	$stdout = eval { Capture::Tiny::capture( $sub ) };
    }

    die( $@) if $@;

    return wantarray ? ($stdout, $stderr) : $stdout;
}

#-------------------------------------------------------

sub exec
{
    my $self = shift;

    {
	local %ENV = %{$self};
	exec( @_ );
    }
}




###############################################
###############################################

package App::Env::_app;

use Carp;
use Storable qw[ dclone freeze ];
use Digest;

use strict;
use warnings;

# new( pid => $pid, app => $app, opt => \%opt )
# new( pid => $pid, env => \%env, module => $module, cacheid => $cacheid )
sub new
{
    my ( $class, %opt ) = @_;

    # make copy of options
    my $self = bless dclone( \%opt ), $class;

    if ( exists $self->{env} )
    {
	$self->{opt} = {} unless defined $self->{opt};
	$self->{ENV} = delete $self->{env};
    }
    else
    {

	( $self->{module}, my $app_opts )
          = eval { App::Env::_require_module( $self->{app}, $self->{opt}{Site} ) };

        croak( ref $@ ? $@ : "error loading application environment module for $self->{app}:\n", $@ )
          if $@;

        die( "application environment module for $self->{app} does not exist\n" )
          unless defined $self->{module};

        # merge possible alias AppOpts
        $self->{opt}{AppOpts} ||= {};
        $self->{opt}{AppOpts} = { %$app_opts, %{$self->{opt}{AppOpts}} };

	$self->mk_cacheid;
    }

    # return cached entry if possible
    if ( exists $App::Env::EnvCache{$self->cacheid} && ! $opt{opt}{Force} )
    {
	$self = $App::Env::EnvCache{$self->cacheid};
    }

    else
    {
	$self->load unless $self->{NoLoad};
	delete $self->{NoLoad};
    }


    return $self;
}

#-------------------------------------------------------

sub mk_cacheid
{
    my ( $self, $cacheid ) = @_;

    $cacheid = $self->{opt}{CacheID} unless defined $cacheid;

    my @elements;

    if ( defined $cacheid )
    {
	push @elements, $cacheid eq 'AppID' ? $self->{module} : $cacheid;
    }
    else
    {
	# create a hash of unique stuff which will be folded
	# into the cacheid
	my %uniq;
	$uniq{AppOpts} = $self->{opt}{AppOpts}
	  if defined $self->{opt}{AppOpts} && keys %{$self->{opt}{AppOpts}};

	my $digest;

	if ( keys %uniq )
	{
	    local $Storable::canonical = 1;
	    $digest = freeze( \%uniq );

	    # use whatever digest aglorithm we can find.  if none is
	    # found, default to the frozen representation of the
	    # options
	    for my $alg ( qw[ SHA-256 SHA-1 MD5 ] )
	    {
		my $ctx = eval { Digest->new( $alg ) };

		if ( defined $ctx )
		{
		    $digest = $ctx->add( $digest )->digest;
		    last;
		}
	    }

	}

	push @elements, $self->{module}, $digest;
    }


    $self->cacheid( join( $;, grep { defined $_ } @elements ) );
}


#-------------------------------------------------------

sub load {
    my ( $self ) = @_;

    # only load if we haven't before
    return $self->{ENV} if exists $self->{ENV};

    my $module = $self->module;

    my $envs;
    my $fenvs = $module->can('envs' );

    croak( "$module does not have an 'envs' function\n" )
      unless $fenvs;

    $envs = eval { $fenvs->( $self->{opt}{AppOpts} ) };

    croak( ref $@ ? $@ : "error in ${module}::envs: $@\n" )
      if $@;

    # make copy of environment
    $self->{ENV} = {%{$envs}};

    # cache it
    $self->cache if $self->{opt}{Cache};

    return $self->{ENV};
}

#-------------------------------------------------------

sub cache {
    my ( $self ) = @_;

    $App::Env::EnvCache{$self->cacheid} = $self;
}

#-------------------------------------------------------

sub uncache {
    my ( $self ) = @_;

    my $cacheid = $self->cacheid;

    delete $App::Env::EnvCache{$cacheid}
      if exists $App::Env::EnvCache{$cacheid}
	&& $App::Env::EnvCache{$cacheid}{pid} eq $self->{pid};
}

#-------------------------------------------------------

sub _opt    { @_ > 1 ? $_[0]->{opt}     = $_[1] : $_[0]->{opt} };
sub cacheid { @_ > 1 ? $_[0]->{cacheid} = $_[1] : $_[0]->{cacheid} };
sub module  { $_[0]->{module} };


#-------------------------------------------------------

1;
__END__

=head1 NAME

App::Env - manage application specific environments

=head1 SYNOPSIS

  # import environment from application1 then application2 into current
  # environment
  use App::Env ( $application1, $application2, \%opts );

  # import an environment at your leisure
  use App::Env;
  App::Env::import( $application, \%opts );

  # set defaults
  use App::Env ( \%defaults )
  App::Env::config( %defaults );

  # retrieve an environment but don't import it
  $env = App::Env->new( $application, \%opts );

  # execute a command in that environment; just as a convenience
  $env->system( $command );

  # exec a command in that environment; just as a convenience
  $env->exec( $command );

  # oh bother, just import the environment
  $env->import;

  # cache this environment as the default for $application
  $env->cache( 1 );

  # uncache this environment if it is the default for $application
  $env->cache( 0 );

  # generate a string compatible with the *NIX env command
  $envstr = $env->str( \%opts );

  # or, stringify it for (mostly) the same result
  system( 'env -i $env command' );

  # pretend it's a hash; read only, though
  %ENV = %$env;


=head1 DESCRIPTION

B<App::Env> presents a uniform interface to initializing environments
for applications which require special environments.  B<App::Env> only
handles the loading, merging, and caching of environments; it does not
create them.  That is done within modules for each application suite
(e.g. B<App::Env::MyApp>).  B<App::Env> ships with two such modules,
B<App::Env::Null> which simply returns a snapshot of the current
environment, and B<App::Env::Example>, which provides example code for
creating an application specific environment.

B<App::Env> is probably most useful in situations where a Perl program
must invoke multiple applications each of which may require an
environment different and possibly incompatible from the others.  The
simplified interface it provides makes it useful even in less
complicated situations.

=head2 Initializing Application Environments

As mentioned above, B<App::Env> does not itself provide the
environments for applications; it relies upon application specific
Perl modules to do so.  Such modules must provide an B<envs()>
function which should return a hash reference containing the
environment.  Application specific options (e.g. version) may be
passed to the module.

See B<App::Env::Example> for information on how to write such modules.

=head2 Managing Environments

In the simplest usage, B<App::Env> can merge (C<import>) the
application's environment directly into the current environment.
For situations where multiple incompatible environments are required,
it can encapsulate those as objects with convenience methods to
easily run applications within those environments.

=head2 Environment Caching

Environments are (by default) cached to improve performance; the
default cache id is generated from the name of the Perl module
which creates the environment and the options passed to it.
signature.  When a environment is requested its signature is compared
against those stored in the cache and if matched, the associated
cached environment is returned.

The cache id is (by default) generated from the full module name
(beginning with C<App::Env> and including the optional site path --
see L</Site Specific Contexts>) and the contents of the B<AppOpts>
hash passed to the module.  If the B<AppOpts> hash is empty, the id is
just the module name.  The cache id may be explicitly specified with
the C<CacheID> option.

If C<CacheID> is set to the string C<AppID> the cache id is set to the
full module name, ignoring the contents of B<AppOpts>.  This is useful
if an application wishes to load an environment using special options
but make it available under the more generic cache id.

To prevent cacheing, use the C<Cache> option. It doesn't prevent
B<App::Env> from I<retrieving> an existing cached environment -- to do
that, use the C<Force> option, which will result in a freshly
generated environment.

To retrieve a cached environment using its cache id use the
B<retrieve()> function.

If multiple applications are loaded via a single call to B<import> or
B<new> the applications will be loaded incremently in the order
specified.  In order to ensure a properly merged environment the
applications will be loaded freshly (any caches will be ignored) and
the merged environment will be cached.  The cache id will by default
be generated from all of the names of the environment modules invoked;
again, this can be overridden using the B<CacheID> option.

=head2 Application Aliases

B<App::Env> performs a case-insensitive search for application
modules.  For example, if the application module is named
B<App::Env::CIAO>, a request for C<ciao> will resolve to it.

Explicit aliases are also possible. A module should be created for
each alias with the single class method B<alias> which should return
the name of the original application.  For example, to make C<App3> be
an alias for C<App1> create the following F<App3.pm> module:

  package App::Env::App3;
  sub alias { return 'App1' };
  1;

The aliased environment can provide presets for B<AppOpts> by returning
a hash as well as the application name:

  package App::Env::ciao34;
  sub alias { return 'CIAO', { Version => 3.4 } };
  1;

These will be merged with any C<AppOpts> passed in via B<import()>, with
the latter taking precedence.

=head2 Site Specific Contexts

In some situations an application's environment will depend upon which
host or network it is executed on.  In such instances B<App::Env>
provides a means for loading an alternate application module.  It does
this by loading the first existant module from the following set of
module names:

  App::Env::$SITE::$app
  App::Env::$app

The C<$SITE> variable is taken from the environment variable
B<APP_ENV_SITE> if it exists, or from the B<Site> option to the class
B<import()> function or the B<new()> object constructor.
Additionally, if the B<APP_ENV_SITE> environemnt variable does I<not
exist> (it is not merely empty), B<App::Env> will first attempt to
load the B<App::Env::Site> module, which can set the B<APP_ENV_SITE>
environment variable.

Take as an example the situation where an application's environment is
stored in F</usr/local/myapp/setup> on one host and
F</opt/local/myapp/setup> on another.  One could include logic in a
single C<App::Env::myapp> module which would recognize which file is
appropriate.  If there are multiple applications, this gets messy.  A
cleaner method is to have separate site-specific modules (e.g.
C<App::Env::LAN1::myapp> and C<App::Env::LAN2::myapp>), and switch
between them based upon the B<APP_ENV_SITE> environment variable.

The logic for setting that variable might be encoded in an
B<App::Env::Site> module to transparenlty automate things:

  package App::Env::Site;

  my %LAN1 = map { ( $_ => 1 ) } qw( sneezy breezy queasy );
  my %LAN2 = map { ( $_ => 1 ) } qw( dopey  mopey  ropey  );

  use Sys::Hostname;

  if ( $LAN1{hostname()} )
  {
    $ENV{APP_ENV_SITE} = 'LAN1';
  }
  elsif ( $LAN2{hostname()} )
  {
    $ENV{APP_ENV_SITE} = 'LAN2';
  }

  1;

=head2 The Null Environment

B<App::Env> provides the C<null> environment, which simply returns a
snapshot of the current environment.  This may be useful to provide
fallbacks in case an application specific environment was not found,
but the code should fallback to using the existing environment.

  $env = eval { App::Env->new( "MyApp" ) } \
     // App::Env->new( "null", { Force => 1, Cache => 0 } );

As the C<null> environment is a I<snapshot> of the current
environment, if future C<null> environments should reflect the
environment at the time they are constructed, C"null" environments
should not be cached (e.g. C<Cache =E<gt> 0>).  The C<Force =E<gt> 1>
option is specified to ensure that the environment is not being read
from cache, just in case a prior C<null> environment was inadvertently
cached.

=head1 INTERFACE

B<App::Env> may be used to directly import an application's
environment into the current environment, in which case the
non-object oriented interface will suffice.

For more complicated uses, the object oriented interface allows for
manipulating multiple separate environments.

=head2 Using B<App::Env> without objects

Application environments may be imported into the current environment
either when loading B<App::Env> or via the B<App::Env::import()>
function.

=over

=item import

  use App::Env ( $application, \%options );
  use App::Env ( @applications, \%shared_options );

  App::Env::import( $application, \%options );
  App::Env::import( @applications, \%shared_options );

Import the specified applications.

Options may be applied to specific applications by grouping
application names and option hashes in arrays:

  use App::Env ( [ 'app1', \%app1_options ],
                 [ 'app2', \%app2_options ],
                 \%shared_options );

  App::Env::import( [ 'app1', \%app1_options ],
                    [ 'app2', \%app2_options ],
                    \%shared_options );

Shared (or default) values for options may be specified in a hash passed as
the last argument.

The available options are listed below.  Not all options may be shared; these
are noted.

=over

=item AppOpts I<hashref>

This is a hash of options to pass to the
C<App::Env::E<lt>applicationE<gt>> module.  Their meanings are
application specific.

This option may not be shared.

=item Force I<boolean>

Don't use the cached environment for this application.

=item Site

Specify a site.  See L</Application Environments> for more information

=item Cache I<boolean>

Cache (or don't cache) the environment. By default it is cached.  If
multiple environments are loaded the I<combination> is also cached.

=item CacheID

A unique name for the environment. See L</Environment Caching> for more information.

When used as a shared option for multiple applications, this will be
used to identify the merged environment.  If set to the string
C<AppID>, the full module name will be used as the cache id (ignoring
the contents of the B<AppOpts> option hash).

=item SysFatal I<boolean>

If true, the B<system>, B<qexec>, and B<capture> object methods will throw
an exception if the passed command exits with a non-zero error.

=item Temp I<boolean>

If true, and the requested environment does not exist in the cache,
create it but do not cache it (this overrides the B<Cache> option).
If the requested environment does exist in the cache, return an
uncached clone of it.  The following options are updated in
the cloned environment:

  SysFatal

=back

=item retrieve

  $env = App::Env::retrieve( $cacheid );

Retrieve the environment with the given cache id, or undefined if it
doesn't exist.

=back

=head2 Managing Environments

=over

=item config

  App::Env::config( %Defaults );

Configure default options for environments.  See L<Changing Default
Option Values> for more information.

=item uncache

  App::Env::uncache( App => $app, [ Site => $site ] )
  App::Env::uncache( CacheID => $cacheid )


Delete the cache entry for the given application.  If C<Site> is not
specified, the site is determined as specified in L</Site Specific
Contexts>.

It is currently I<not> possible to use this interface to
explicitly uncache multi-application environments if they have not
been given a unique cache id.  It is possible using B<App::Env>
objects.

The available options are:

=over

=item App

The application name.  This may not be specified if B<CacheID> is
specified.

=item Site

If the B<Site> option was used when first loading the environment,
it must be specified here in order to delete the correct cache entry.
Do not specify this option if B<CacheID> is specified.

=item CacheID

If the B<CacheID> option was used to provide a cache key for the cache
entry, this must be specified here.  Do not specify this option if
B<App> or B<Site> are specified.

=item All

If true uncache all of the cached environments.


=back


=back

=head2 Using B<App::Env> objects

B<App::Env> objects give greater flexibility when dealing with
multiple applications with incompatible environments.


=head3 Constructors

=over

=item new

  $env = App::Env->new( ... )

B<new> takes the same arguments as B<App::Env::import> and returns
an B<App::Env> object.  It does not modify the environment.


=item clone

  $clone = $app->clone( \%opts );

Clone an existing environment.  The available options are C<CacheID>,
C<Cache>, C<SysFatal> (see the documentation for the B<import> function).

The cloned environment is by default not cached.  If caching is
requested and a cache id is not provided, a unique id is created --
it will I<not> be the same as that of the original environment.

This generated cache id is not based on a signature of the
environment, so this environment will effectively not be automatically
reused when a similar environment is requested via the B<new>
constructor (see L</Environment Caching>).


=back

=head3 Overloaded operators

B<App::Env> overloads the %{} and "" operators.  When
dereferenced as a hash an B<App::Env> object returns a hash of
the environmental variables:

  %ENV = %$env;

When interpolated in a string, it is replaced with a string suitable
for use with the *NIX B<env> command; see the B<str()> method below
for its format.

=head3 Methods

=over

=item cache

  $env->cache( $cache_state );

If C<$cache_state> is true, cache this environment using the object's
cache id.  If C<$cache_state> is false and this environment is being
cached, delete the cache.

Note that only the original B<App::Env> object which cached the
environment may delete it.  Objects which reuse existing, cached,
environments cannot.


=item cacheid

  $cacheid = $env->cacheid;

Returns the cache id for this environment.

=item env

  # return a hashref of the entire environment (similar to %{$env})
  $hashref = $env->env( );

  # return the value of a given variable in the environment
  $value = $env->env( $variable_name )

  # return an array of values of particular variables.
  # names should be strings
  @values = $env->env( @variable_names );

  # match variable names and return a hashref
  $hashref = $env->env( @match_specifications );

  # exclude specific variables
  $hashref = $env->env( { Exclude => $match_spec   } );
  $hashref = $env->env( { Exclude => \@match_specs } );
  $hashref = $env->env( @match_specs, { Exclude => $match_spec   } );
  $hashref = $env->env( @match_specs, { Exclude => \@match_specs } );

Return all or parts of the environment.  What is returned
depends upon the type of argument and which of the
following contexts matches:

=over

=item 1

If called with no arguments (or just an B<Exclude> option,
as discussed below) return a hashref containing the environment.

=item 2

If called in a scalar context and passed a single variable name
(which must be a string) return the value for that variable,
or I<undef> if it is not in the environment.

=item 3

If called in a list context and passed a list of variable names
(which must be strings) return an array of values for those variables
(I<undef> for those not in the environment).

=item 4

If called in a scalar context and passed one or more I<match
specifications>, return a hashref containing the subset
of the environment which matches.  The C<Exclude> option (see below)
may be present.

A I<match specification> may be a string, (for an exact match of a
variable name), a regular expression created with the B<qr> operator,
or a subroutine reference.  The subroutine will be passed two
arguments, the variable name and its value, and should return true if
the variable should be excluded, false otherwise.

To avoid mistaking this context for context 1 if the I<match specification>
is a single string, enclose it in an array, e.g.

   # this is context 1
   $value = $env->env( $variable_name );

   # this is context 3
   $hash = $env->env( [ $variable_name ] );

=back

Variable names may be excluded from the list by passing a hash with
the key C<Exclude> as the last argument (valid only in contexts 0 and
3).  The value is either a scalar or an arrayref composed of match
specifications (as an arrayref) as described in context 3.

=item setenv

  # set an environmental variable
  $env->setenv( $var, $value );

  # delete an environmetal variable
  $env->setenv( $var );

If C<$value> is present, assign it to the named environmental
variable.  If it is not present, delete the variable.

B<Note:> If the environment refers to a cached environment, this will
affect all instances of the environment which share the cache.

=item module

  $module = $env->module;

This returns the name of the module which was used to load the
environment.  If multiple modules were used, the names are
concatenated, seperated by the C<$;> (subscript separator) character.

=item str

  $envstr = $env->str( @match_specifications, \%options );

This function returns a string which may be used with the *NIX B<env>
command to set the environment.  The string contains space separated
C<var=value> pairs, with shell magic characters escaped.

The environment may be pared down by passing I<match specifications>
and an C<Exclude> option; see the documentation for the B<env> method,
context 3, for more information.

Because the B<TERMCAP> environment variable is often riddled with
escape characters, which are not always handled well by shells, the
B<TERMCAP> variable is I<always> excluded unless it is explicitly
included via an exact variable name match specification. For example,

  $envstr = $env->str( qr/.*/, 'TERMCAP );

is the only means of getting all of the environment returned.

=item system

  $env->system( $command, @args );

This runs the passed command in the environment defined by B<$env>.
It has the same argument and returned value convention as the core
Perl B<system> command.

If the B<SysFatal> flag is set for this environment,
B<IPC::System::Simple::system> is called, which will cause this method
to throw an exception if the command returned a non-zero exit value.
It also avoid invoking a shell to run the command if possible.


=item exec

  $env->exec( $command, @args );

This execs the passed command in the environment defined by B<$env>.
It has the same argument and returned value convention as the core
Perl B<exec> command.

=item qexec

  $output = $env->qexec( $command, @args );
  @lines = $env->qexec( $command, @args );

This acts like the B<qx{}> Perl operator.  It executes the passed
command in the environment defined by B<$env> and returns its
(standard) output.  If called in a list context the output is
split into lines.

If the B<SysFatal> flag is set for this environment,
B<IPC::System::Simple::capture> is called, which will cause this
method to throw an exception if the command returned a non-zero exit
value.  It also avoid invoking a shell to run the command if possible.

=item capture

  $stdout = $env->capture( $command, @args );
  ($stdout, $stderr) = $env->capture( $command, @args );

Execute the passed command in the environment defined by B<$env> and
returns content of its standard output and (optionally) standard error
streams.

If the B<SysFatal> flag is set for this environment,
B<IPC::System::Simple::capture> is called, which will cause this
method to throw an exception if the command returned a non-zero exit
value.  It also avoid invoking a shell to run the command if possible.

=back

=head2 Changing Default Option Values

Default values for some options may be changed via any of the
following:

=over

=item *

Passing a hashref as the only argument when initially importing the
package:

  use App::Env \%Default;

=item *

Calling the B<config> function:

  App::Env::config( %Default );

=back

The following options may have their default values changed:

  Force  Cache  Site  SysFatal


=head1 EXAMPLE USAGE


=head2 A single application

This is the simplest case.  If you don't care if you "pollute" the
current environment, then simply

  use App::Env qw( ApplicationName );

=head2 A single application with options

If the B<CIAO> environment module provides a C<Version> option:

  use App::Env ( 'CIAO', { AppOpts => { Version => 3.4 } } );

=head2 Two compatible applications

If two applications can share an environment, and you don't mind
changing the current environment;

  use App::Env qw( Application1 Application2 );

If you need to preserve the environment you need to be a little more
circumspect.

  $env = App::Env->new( qw( Application1 Application 2 ) );
  $env->system( $command1, @args );
  $env->system( $command2, @args );

or even

  $env->system( "$command1 | $command2" );

Or,

  {
    local %ENV = %$env;
    system( $command1);
  }

if you prefer not to use the B<system> method.

=head2 Two incompatible applications

If two applications can't share the environment, you'll need to
load them seperately:

  $env1 = App::Env->new( 'Application1' );
  $env2 = App::Env->new( 'Application2' );

  $env1->system( $command1 );
  $env2->system( $command2 );

Things are trickier if you need to construct a pipeline.  That's where
the *NIX B<env> command and B<App::Env> object stringification come
into play:

  system( "env -i $env1 $command1 | env -i $env2 $command2" );

This hopefully won't overfill the shell's command buffer. If you need
to specify only parts of the environment, use the B<str> method to
explicitly create the arguments to the B<env> command.


=head2 Localizing changes to an environment

In some contexts an environment must be customized but the changes
shouldn't propagate into the (possibly) cached version.  A good
example of this is in sandboxing functions which may manipulate an
environment.

The B<new()> constructor doesn't indicate whether an environment was
freshly constructed or pulled from cache, so the user can't tell if
manipulating it will affect other code paths.  One way around this is
to force construction of a fresh environment using the C<Force> option
and turning off caching via the C<Cache> option.

This guarantees isolation but is inefficient (if a compatible
environment is cached it won't be used) and any tweaks made to the
environment by the application are not seen.  Instead, use the C<Temp>
option; this will either create a new environment if none exists or
clone an existing one.  In either case the result won't be cached and
any changes will be localized.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-env@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Env>.

The cache id is generated from the contents of the B<AppOpts> hash by
freezing it with B<Storable::freeze> and either generating a digest
using B<Digest> (if the proper modules are available) or using it
directly.  This may cause strangeness if B<AppOpts> contains data or
objects which do not freeze well.

=head1 SEE ALSO

B<appexec>

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2015 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses

=cut
