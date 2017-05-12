#line 1
package CGI::Application::Plugin::Session;

use CGI::Session ();
use File::Spec ();
use CGI::Application 3.21;
use Carp qw(croak);
use Scalar::Util ();

use strict;
use vars qw($VERSION @EXPORT);

require Exporter;

@EXPORT = qw(
  session
  session_config
  session_cookie
  session_delete
);
sub import { goto &Exporter::import }

$VERSION = '1.02';

sub session {
    my $self = shift;

    if (!$self->{__CAP__SESSION_OBJ}) {
        # define the config hash if it doesn't exist to save some checks later
        $self->{__CAP__SESSION_CONFIG} = {} unless $self->{__CAP__SESSION_CONFIG};

        # gather parameters for the CGI::Session module from the user,
        #  or use some sane defaults
        my @params = ($self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS}) ?
                        @{ $self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS} } :
                        ('driver:File', $self->query, {Directory=>File::Spec->tmpdir});


        # CGI::Session only works properly with CGI.pm so extract the sid manually if
        # another module is being used
        if (Scalar::Util::blessed($params[1]) && ! $params[1]->isa('CGI')) {
            my $sid = $params[1]->cookie(CGI::Session->name) || $params[1]->param(CGI::Session->name);
            $params[1] = $sid;
        }

        # create CGI::Session object or die with an error
        $self->{__CAP__SESSION_OBJ} = CGI::Session->new(@params);
        if (! $self->{__CAP__SESSION_OBJ} ) {
            my $errstr = CGI::Session->errstr || 'Unknown';
            croak "Failed to Create CGI::Session object :: Reason: $errstr";
        }

        # Set the default expiry if requested and if this is a new session
        if ($self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY} && $self->{__CAP__SESSION_OBJ}->is_new) {
            $self->{__CAP__SESSION_OBJ}->expire($self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY});
        }

        # add the cookie to the outgoing headers under the following conditions
        #  if the cookie doesn't exist,
        #  or if the session ID doesn't match what is in the current cookie,
        #  or if the session has an expiry set on it
        #  but don't send it if SEND_COOKIE is set to 0
        if (!defined $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE} || $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE}) {
            my $cid = $self->query->cookie(CGI::Session->name);
            if (!$cid || $cid ne $self->{__CAP__SESSION_OBJ}->id || $self->{__CAP__SESSION_OBJ}->expire()) {
                session_cookie($self);
            }
        }
    }

    return $self->{__CAP__SESSION_OBJ};
}

sub session_config {
    my $self = shift;

    if (@_) {
      die "Calling session_config after the session has already been created" if (defined $self->{__CAP__SESSION_OBJ});
      my $props;
      if (ref($_[0]) eq 'HASH') {
          my $rthash = %{$_[0]};
          $props = $self->_cap_hash($_[0]);
      } else {
          $props = $self->_cap_hash({ @_ });
      }

      # Check for CGI_SESSION_OPTIONS
      if ($props->{CGI_SESSION_OPTIONS}) {
        die "session_config error:  parameter CGI_SESSION_OPTIONS is not an array reference" if ref $props->{CGI_SESSION_OPTIONS} ne 'ARRAY';
        $self->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS} = delete $props->{CGI_SESSION_OPTIONS};
      }

      # Check for COOKIE_PARAMS
      if ($props->{COOKIE_PARAMS}) {
        die "session_config error:  parameter COOKIE_PARAMS is not a hash reference" if ref $props->{COOKIE_PARAMS} ne 'HASH';
        $self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS} = delete $props->{COOKIE_PARAMS};
      }

      # Check for SEND_COOKIE
      if (defined $props->{SEND_COOKIE}) {
        $self->{__CAP__SESSION_CONFIG}->{SEND_COOKIE} = (delete $props->{SEND_COOKIE}) ? 1 : 0;
      }

      # Check for DEFAULT_EXPIRY
      if (defined $props->{DEFAULT_EXPIRY}) {
        $self->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY} = delete $props->{DEFAULT_EXPIRY};
      }

      # If there are still entries left in $props then they are invalid
      die "Invalid option(s) (".join(', ', keys %$props).") passed to session_config" if %$props;
    }

    $self->{__CAP__SESSION_CONFIG};
}

sub session_cookie {
    my $self = shift;
    my %options = @_;

    # merge in any parameters set by config_session
    if ($self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS}) {
      %options = (%{ $self->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS} }, %options);
    }
    
    if (!$self->{__CAP__SESSION_OBJ}) {
        # The session object has not been created yet, so make sure we at least call it once
        my $tmp = $self->session;
    }

    $options{'-name'}    ||= CGI::Session->name;
    $options{'-value'}   ||= $self->session->id;
    if(defined($self->session->expires()) && !defined($options{'-expires'})) {
        $options{'-expires'} = _build_exp_time( $self->session->expires() );
    }
    my $cookie = $self->query->cookie(%options);
    $self->header_add(-cookie => [$cookie]);
}

sub _build_exp_time {
    my $secs_until_expiry = shift;
    return unless defined $secs_until_expiry;

    # Add a plus sign unless the number is negative
    my $prefix = ($secs_until_expiry >= 0) ? '+' : '';

    # Add an 's' for "seconds".
    return $prefix.$secs_until_expiry.'s';
}

sub session_delete {
    my $self = shift;

    if ( my $session = $self->session ) {
        $session->delete;
        if ( $self->{'__CAP__SESSION_CONFIG'}->{'SEND_COOKIE'} ) {
            my %options;
            if ( $self->{'__CAP__SESSION_CONFIG'}->{'COOKIE_PARAMS'} ) {
                %options = ( %{ $self->{'__CAP__SESSION_CONFIG'}->{'COOKIE_PARAMS'} }, %options );
            }
            $options{'name'} ||= CGI::Session->name;
            $options{'value'}    = '';
            $options{'-expires'} = '-1d';
            my $newcookie = $self->query->cookie(%options);

            # See if a session cookie has already been set (this will happen if
            #  this is a new session).  We keep all existing cookies except the
            #  session cookie, which we replace with the timed out session
            #  cookie
            my @keep;
            my %headers = $self->header_props;
            my $cookies = $headers{'-cookie'} || [];
            $cookies = [$cookies] unless ref $cookies eq 'ARRAY';
            foreach my $cookie (@$cookies) {
                if ( ref($cookie) ne 'CGI::Cookie' || $cookie->name ne CGI::Session->name ) {
                    # keep this cookie
                    push @keep, $cookie;
                }
            }
            push @keep, $newcookie;

            # We have to set the cookies this way, because CGI::Application has
            #  an annoying interface to the headers (why can't we have
            #  'header_set as well as header_add?).  The first call replaces all
            #  cookie headers with the one new cookie header, and the next call
            #  adds in the rest of the cookies if there are any.
            $self->header_add( -cookie => shift @keep );
            $self->header_add( -cookie => \@keep ) if @keep;
        }
    }
}

1;
__END__

#line 439

