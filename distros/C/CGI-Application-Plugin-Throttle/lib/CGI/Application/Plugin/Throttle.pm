package CGI::Application::Plugin::Throttle;

=head1 NAME

CGI::Application::Plugin::Throttle - Rate-Limiting for CGI::Application



=head1 SYNOPSIS

    use CGI::Application::Plugin::Throttle;
    
    
    # Your application
    sub setup {
        
      ...
      
      # Create a redis handle
      my $redis = Redis->new();
      
      # Configure throttling
      $self->throttle()->configure(
        redis     => $redis,
        prefix    => "REDIS:KEY:PREFIX",
        limit     => 100,
        period    => 60,
        exceeded  => "slow_down_champ"
      );
      
      ...
      
    }
    
    sub throttle_keys {
        my $self = shift;
        
        # do not throttle at all when returning `undef`
        return undef if %ENV{DEVELOPMENT};
        
        return (
            remote_addr => $ENV{REMOTE_ADDR},
            
            maybe
            pwd_recover => $self->_is_password_recovery
        );
    }
    
    sub throttle_spec {
        { pwd_recover => 1 } =>
        {  limit =>     5, period => 300, exceeded => 'stay_out' }
        
        { remote_addr => '127.0.0.1' }
        { limit => 10_000, period =>   1, exceeded => 'get_home' }
    }

=cut



=head1 VERSION

This is version '0.7'



=head1 DESCRIPTION

This module allows you to enforce a throttle on incoming requests to your
application, based upon the remote IP address, or other parameters.

This module stores a count of accesses in a Redis key-store, and once hits
exceed the specified threshold the user will be redirected to the run-mode
you've specified.



=head1 POTENTIAL ISSUES / CONCERNS

Users who share IP addresses, because they are behind a common-gateway for
example, will all suffer if the threshold is too low.  We attempt to mitigate
this by building the key using a combination of the remote IP address, and the
remote user-agent.

This module has added great flexibillity to change the parameters being used for
generating the redis key. It now also has the posibillity to select different
throttle rules specified by filters that need to match the parameters.

=cut



use strict;
use warnings;

our $VERSION = '0.7';

use Digest::SHA qw/sha512_base64/;


=head1 METHODS

=cut



=head2 C<import>

Force the C<throttle> method into the caller's namespace, and configure the
prerun hook which is used by L<CGI::Application>.

=cut

sub import
{
    my $pkg     = shift;
    my $callpkg = caller;

    {
        ## no critic
        no strict qw(refs);
        ## use critic
        *{ $callpkg . '::throttle' } = \&throttle;
    }

    if ( UNIVERSAL::can( $callpkg, "add_callback" ) )
    {
        $callpkg->add_callback( 'prerun' => \&throttle_callback );
    }

}



=head2 C<new>

This method is used internally, and not expected to be invoked externally.

The defaults are setup here, although they can be overridden in the
L</"configure"> method.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};

    #
    #  Configure defaults.
    #
    $self->{ 'limit' }  = 100;
    $self->{ 'period' } = 60;

    #
    #  The redis key-prefix.
    #
    $self->{ 'prefix' } = $supplied{ 'prefix' } || "THROTTLE";

    #
    #  Run mode to redirect to on exceed.
    #
    $self->{ 'exceeded' } = "slow_down";

    #
    #  Set the code reference for getting the throttle keys
    #
    $self->{ 'throttle_keys_callback' } = $supplied{ 'throttle_keys_callback' }
    || \&_get_default_throttle_keys;
    
    #
    #  Set the code reference for getting throttle specific rules
    #
    $self->{ 'throttle_spec_callback' } = $supplied{ 'throttle_spec_callback' };

    bless( $self, $class );
    return $self;
}



=head2 C<throttle>

Gain access to an instance of this class.  This is the method by which you can
call methods on this plugin from your L<CGI::Application> derived-class.

=cut

sub throttle
{
    my $cgi_app = shift;
    return $cgi_app->{ __throttle_obj } if $cgi_app->{ __throttle_obj };
    
    #
    #  Setup the prefix of the Redis keys to default to the name of
    # the CGI::Application.
    #
    #  This avoids collisions if multiple applications are running on
    # the same host, and the developer won't need to explicitly setup
    # distinct prefixes.
    #
    my $throttle = $cgi_app->{ __throttle_obj } =
      __PACKAGE__->new(
        prefix => ref($cgi_app),
        throttle_keys_callback => $cgi_app->can('throttle_keys'),
        throttle_spec_callback => $cgi_app->can('throttle_spec'),
      )
    ;

    return $throttle;
}



# sub _get_redis_key>
#
# Build and return the Redis key to use for this particular remote request.
#
# The key is built from the C<prefix> string set in L</"configure"> method,
# along with:
#
# * The remote IP address of the client.
# * The remote HTTP Basic-Auth username of the client.
# * The remote User-Agent.
#
sub _get_redis_key
{
    my $self = shift;
    my $key  = $self->{ 'prefix' };

    #
    #  Build up the key based on the:
    #
    #  1.  User using HTTP Basic-Auth, if present.
    #  2.  The remote IP address.
    #  3.  The remote user-agent.
    #
    foreach my $env (qw! REMOTE_USER REMOTE_ADDR HTTP_USER_AGENT !)
    {
        if ( $ENV{ $env } )
        {
            $key .= ":";
            $key .= $ENV{ $env };
        }
    }

    return ($key);
}



=head2 C<count>

Returns two values: the number of times the remote client has hit a run mode,
along with the maximum allowed visits:

=for example begin

    sub your_run_mode
    {
        my ($self) = (@_);
        
        my( $count, $max ) = $self->throttle()->count();
        return( "$count visits seen - maximum is $max." );
    }

=for example end

=head3 warning

This method must be called in list context, in scalar context, the result will
always be '2'.

=cut

sub count
{
    my ($self) = (@_);
    
    my $keys = $self->_get_keys();
    my $rule = $self->_get_throttle_rule( $keys );

    my $visits = 0;
    my $max    = $rule->{ 'limit' };

    if ( $self->{ 'redis' } )
    {
        my $digest_key = $self->_digest_key_in_timeslot($keys, $rule->{period});
        $visits = $self->{ 'redis' }->llen($digest_key);
    }
    return ( $visits, $max );
}



# sub throttle_callback
#
# This method is invoked by L<CGI::Application>, as a hook.
#
# The method is responsible for determining whether the remote client which
# triggered the current request has exceeded their request threshold.
#
# If the client has made too many requests their intended run-mode will be
# changed to redirect them.
#
sub throttle_callback
{
    my $cgi_app = shift;
    my $self    = $cgi_app->throttle();

    #
    # Get the redis handle
    #
    my $redis = $self->{ 'redis' } || return;

    #
    # The key relating to this user.
    #
    my $keys = $self->_get_keys();

    #
    # Get throttle rule
    #
    my $rule = $self->_get_throttle_rule( $keys );
    
    #
    #  If too many redirect.
    #
    if ( my $exceeded = $self->_is_exceeded($rule, $keys) )
    {
        $cgi_app->prerun_mode( $exceeded );
        return;
    }

    #
    #  Otherwise if we've been called with a mode merge it in
    #
    if ( $cgi_app->query->url_param( $cgi_app->mode_param ) )
    {
        $cgi_app->prerun_mode(
                           $cgi_app->query->url_param( $cgi_app->mode_param ) );
    }

}



=head2 C<configure>

This method is what the user will invoke to configure the throttle-limits.

It is expected that within the users L<CGI::Application>
L<CGI::Application/setup> method there will be code similar to this:

=for example begin

    sub setup {
        my $self = shift;
        
        my $r = Redis->new();
        
        $self->throttle()->configure( redis => $r,
                                      # .. other options here
                                    )
    }

=for example end

The arguments hash contains the following known keys:

=over

=item C<redis>

A L<Redis> handle object.

=item C<limit>

The maximum number of requests that the remote client may make, in the given
period of time.

=item C<period>

The period of time which requests are summed for.  The period is specified in
seconds and if more than C<limit> requests are sent then the client will be
redirected.

=item C<prefix>

This module uses L<Redis> to store the counts of client requests.  Redis is a
key-value store, and each key used by this module is given a prefix to avoid
collisions.  You may specify your prefix here.

The prefix will default to the name of your application class if it isn't set
explicitly, which should avoid collisions if you're running multiple
applications on the same host.

=item C<exceeded>

The C<run_mode> to redirect the client to, when their request-count has exceeded
the specified limit.

=back

=cut

sub configure
{
    my ( $self, %args ) = (@_);

    #
    #  The rate-limiting number of requests per time period
    #
    $self->{ 'limit' }  = $args{ 'limit' }  if ( $args{ 'limit' } );
    $self->{ 'period' } = $args{ 'period' } if ( $args{ 'period' } );

    #
    #  Redis key-prefix
    #
    $self->{ 'prefix' } = $args{ 'prefix' } if ( $args{ 'prefix' } );

    #
    #  The handle to Redis for state-tracking
    #
    $self->{ 'redis' } = $args{ 'redis' } if ( $args{ 'redis' } );

    #
    #  The run-mode to redirect to on violation.
    #
    $self->{ 'exceeded' } = $args{ 'exceeded' } if ( $args{ 'exceeded' } );

}

#
# This is the original default list of values
#
sub _get_default_throttle_keys
{
  remote_user     => $ENV{ REMOTE_USER },
  remote_addr     => $ENV{ REMOTE_ADDR },
  http_user_agent => $ENV{ HTTP_USER_AGENT },
}

# returns a 'key'
#
# This routine will take the normal key and adds a 'timeslot' to it, so all keys
# will now fall in the same group during the time interval of the 'period'
# Since the key is becomming uglier, we just base64 encode the sha512 hash
#
sub _digest_key_in_timeslot
{
    my ($self, $keys, $period ) = @_;
    my @throttle_keys = @$keys;
    
    # we need to preserve order and can not use random order of a hash
    my (@keys, @vals);
    for ( my $i =0  ; $i < @throttle_keys; )
    {
      push @keys, $throttle_keys[$i++];
      push @vals, $throttle_keys[$i++] || '* * *';
    }
    my $key_string = join q{:}, @vals;
    
    $key_string .= q{#} . int(time() / $period );

    sha512_base64( $key_string )
}

# returns the 'keys' relating to the current user / session etc.
#
sub _get_keys
{
    my $self = shift;
    my @throttle_keys = $self->{ throttle_keys_callback }->();

    # return undef, as an explicit instruction to ignote throttling at all
    return undef if scalar(@throttle_keys) == 1 && !defined($throttle_keys[0]);
    
    # prepend the list with the prefix if missing
    unshift @throttle_keys, (prefix => $self->{ prefix } )
      unless exists  {@throttle_keys}->{ prefix };
    
    return \@throttle_keys;
}

# return a set of key/value pairs for a specific key
#
sub _get_throttle_rule
{
    my $self = shift;
    my $keys = shift;

    return unless defined $keys;

    my $default_rule = $self->_get_default_throttle_rule();
    my $special_rule = $self->_get_special_throttle_rule( $keys );
    my $throttle_rule =  { %$default_rule, %$special_rule };

    return $throttle_rule
}

# returns the default set of rules, set by $throttle->configure
#
sub _get_default_throttle_rule
{
    my $self = shift;
    
    my $rule = {
        limit    => $self->{ 'limit' },
        period   => $self->{ 'period' },
        exceeded => $self->{ 'exceeded' },
    };
    return $rule;
}

# returns the first rule whre all the filters are matched against the keys
#
sub _get_special_throttle_rule
{
    my ( $self, $keys ) = @_;
    return { } unless $self->{ throttle_spec_callback };
    
    my @spec = $self->{ throttle_spec_callback }->();
    
    # set initial rule to an empty set, or the last spec if there is an odd list
    my $rule = scalar @spec %2 ? pop @spec : {};

    while ( my($filter, $rule ) = splice @spec, 0 , 2 )
    {
        next unless $self->_match_all( $filter, $keys );
        return $rule
    }
    
    return $rule;
}

sub _match_all
{
    my ($self, $filter, $keys) = @_;
    
    my $lookup = { @$keys };
    
    foreach ( keys %$filter )
    #
    # In natural language, not in Perl, the below test does match:
    #
    #  "if both are the same"
    #
    # that is, under the precondition that both exists,
    # that both defined strings are the same, or both are undefined
    #
    # normally,in string comparision, `undef` is compared as an empty string
    #
    # take a class in boolean algebra and learn about The Morgan etc
    #
    # we do not match if:
    #
    {
        return unless exists $lookup->{$_};
        
        next if 
            ( defined $filter->{$_} && $filter->{$_} )
            eq
            ( defined $lookup->{$_} && $lookup->{$_} );
        
        return if
            ( defined $filter->{$_}                  )
            ||
            ( defined $lookup->{$_}                  );
        
    }
    return !undef
}

# returns the runmode if the this is true for the given rule and key
#
sub _is_exceeded
{
    my ($self, $rule, $keys) = @_;
    
    return unless defined $keys;
    
    my $redis = $self->{ 'redis' } or return;

    #
    # Use a timeslot defined digest key instead
    #
    my $digest_key = $self->_digest_key_in_timeslot($keys, $rule->{period});

    #
    #  Increase the count, and set the expiry.
    #
    my $cur = $redis->lpush($digest_key, 1);
    $redis->expire( $digest_key, $rule->{ 'period' } ) if $cur == 1;

    #
    #  If limit exceeded, redirect.
    #
    return $rule->{ exceeded } if $cur > $rule->{ limit };
    
    return
}


=head1 CALLBACKS

=head2 C<throttle_keys>

This callback will be called to give the developer the option to use alternative
keys. It must return a list of key value pairs, and the plugin will preserve the
order. Default these are C<remote_user>, C<remote_addr>, and C<http_user_agent>.

=for example begin

    sub throttle_keys {
        remote_user     => $ENV{ REMOTE_USER },
        remote_addr     => $ENV{ REMOTE_ADDR },
        http_user_agent => $ENV{ HTTP_USER_AGENT },
    }

=for example end

This callback can be used to do more fancy things and add a key for run-modes as
in:

=for example begin

    sub throttle_keys {
        my $self = shift;
        
        return (
            runmode_grp => $self->_get_runmode_group(),
            ...         => ...
        )
    }

=for example end

Returning a explicit C<undef> means that no throttling will happen, at all; If
the call back returns an empty list, all incoming request will be throttled and
no difference will be made from where the request comes from.

=for example begin

    sub throttle_keys {
        return undef if $ENV{REMOTE_USER} eq 'superuser';
        return ( );
    }

=for example end

=head2 C<throttle_spec>

This callback can be used to specify different set of throttle rules based on
filters that must match with the throttle keys. This callback must return a list
of filter/settings pairs that will be checked against the current throttle keys.
It can have a additional last set of throttle rules (it is an odd sized list),
which will then be used as a default.

The selected rules willbe merged with the settings from the Cconfigure> call, or
the defaults from the module itself.

Keys mentioned in the filter must be present in the current throttle keys/params
in order to match. The value can be C<undef>, meaning that the throttle param
must exist and be undefined.

=for example begin

    sub throttle_spec {
        { remote_user => undef } =>
        {
            limit    => 5,
            exceeded => 'we_dont_like_strangers'
        },
        
        { runmode_grp => 'pdf_report' } =>
        {
            limit    => 10,
            period   => 3600,
            exceeded => 'these_are_very_expensive'
        }
        
        {
            limit    => rnd * 10 # making people go crazy why? 
        }
    }

=for example end

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=head1 CONTRIBUTORS

Theo van Hoesel <tvanhoesel@perceptyx.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014..2020 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under the
same terms as Perl itself.

=cut



1;
