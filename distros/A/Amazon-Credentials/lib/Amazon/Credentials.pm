package Amazon::Credentials;

use strict;
use warnings;

use parent qw/Class::Accessor Exporter/;

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw/aws_secret_access_key aws_access_key_id token region
			     user_agent profile debug expiration role container order 
			     serialized logger
			    /);

use Data::Dumper;
use Date::Format;
use Exporter;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use POSIX::strptime qw/strptime/;
use Time::Local;
use Scalar::Util qw/reftype/;

use constant  AWS_IAM_SECURITY_CREDENTIALS_URL       => 'http://169.254.169.254/latest/meta-data/iam/security-credentials/';
use constant  AWS_AVAILABILITY_ZONE_URL              => 'http://169.254.169.254/latest/meta-data/placement/availability-zone';
use constant  AWS_CONTAINER_CREDENTIALS_URL          => 'http://169.254.170.2';

use vars qw/$VERSION @EXPORT/;

$VERSION = '1.0.6-0'; $VERSION=~s/\-.*$//;

@EXPORT = qw/$VERSION/;

# we only log at debug level, create a default logger
{
  no strict 'refs';
  
  *{'Amazon::Credentials::Logger::debug'} = sub {
    shift;
    my @tm = localtime(time);
    print STDERR sprintf("%s [%s] %s", strftime("%c", @tm), $$, @_);
  };
}

=pod

=head1 NAME

C<AWS::Credentials>

=head1 SYNOPSIS

 my $aws_creds = new Amazon::Credentials({order => [qw/env file container role/]});

=head1 DESCRIPTION

Class to find AWS credentials from either the environment,
configuration files, instance meta-data or container role.

You can specify the order using the C<order> option in the constructor
to determine the order in which the class will look for credentials.
The default order is I<environent>, I<file>, I<container>, I<instance
meta-data>. See L</new>.

=head1 METHODS

=head2 new

 new( options );

 my $aws_creds = new Amazon::Credential( { profile => 'sandbox', debug => 1 });

C<options> is a hash of keys that represent options.  Any of the
options can also be retrieved using their corresponding 'get_{option}
method.

Options are listed below.

=over 5

=item aws_access_key_id

AWS access key.

=item aws_secret_access_key

AWS secret access key.

I<Note: If you pass the access keys in the constructor then the
constructor will not look in other places for credentials.>

=item debug

Set to true for verbose troubleshooting information.

=item logger

Pass in your own logger that has a C<debug()> method.  Otherwise the
default logger will output debug messages to STDERR.

=item user_agent

Pass in your own user agent, otherwise LWP will be used. I<Probably
only useful to override this for testing purposes.>

=item profile

The profile name in the configuration file (F<~/.aws/config> or
F<~/.aws/credentials>).

 my $aws_creds = new Amazon::Credentials({ profile => 'sandbox' });

The class will also look for the environment variable C<AWS_PROFILE>,
so you can invoke your script like this:

 $ AWS_PROFILE=sandbox my-script.pl

=item order

An array reference containing tokens that specifies the order in which the class will
search for credentials.

default: role, env, file

Example:

  my $creds = new Amazon::Credentials( { order => [ qw/file env role/] });

=over 5

=item env - Environment

If there exists an environment variable $AWS_PROFILE, then an attempt
will be made to retrieve credentials from the credentials file using
that profile, otherwise we'll look for these environment variables to
provide credentials.

C<AWS_ACCESS_KEY_ID>
C<AWS_SECRET_ACCESS_KEY>
C<AWS_SESSION_TOKEN>

I<Note that when you set the environment variable AWS_PROFILE, the
order essentially is overridden and we'll look in your credential
files (F<~/.aws/config>, F<~/.aws/credentials>) for your credentials.

=item file - Configuration Files

=over 10

=item ~/.aws/config

=item ~/.aws/credentials

=back

The class will attempt to find the credentials in either of these two
files.  You can also specify a profile to use for looking up the
credentials by passing it into the constructor or setting in an the
environment variable C<AWS_PROFILE>.  If no profile is provided, the
default credentials or the first profile found is used.

 my $aws_creds = new Amazon::Credentials({ order => [qw/environment role file/] });

=item container - Task Role

If the process is running in a container, the container may have a
task role.  We'll look credentials using the container metadata
service.

 http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI

=item role - Instance Role

The class will use the
I<http://169.254.169.254/latest/meta-data/iam/security-credential> URL
to look for an instance role and credentials.

Keep in mind that these credentials include a token that needs to be
passed to Amazon APIs when using the credentials returned when using
instance meta-data.  That token has an expiration and should be
refreshed as required.

 if ( $aws_creds->is_token_expired() ) {
   $aws_creds->refresh_token()
 }

=back

=item region

Default region. The class will attempt to find the region in either
the configuration files or the instance unless you specify the region
in the constructor.

=back

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(ref($_[0]) ? $_[0] : { @_ });

  unless ( $self->get_logger ) {
    $self->set_logger(bless {}, 'Amazon::Credentials::Logger');
  }

  unless ($self->get_user_agent) {
    $self->set_user_agent(new LWP::UserAgent);
  }

  $self->set_profile($ENV{AWS_PROFILE}) unless
    $self->get_profile;

  unless ( $self->get_aws_secret_access_key && $self->get_aws_access_key_id ) {
    $self->set_credentials();
  }

  $self->set_region($ENV{AWS_REGION} || $self->get_default_region)
    unless $self->get_region;

  $self;
}

=pod

=head2 get_default_region

Returns the region of the currently running instance.  The constructor
will set the region to this value unless you set your own C<region>
value.  Use C<get_region> to retrieve the value after instantiation or
you can call this method again and it will make a second call to
retrieve the instance metadata.

You can also invoke this as a class method:

 $ AWS_REGION=$(perl -MAmazon::Credentials -e 'print Amazon::Credentials::get_default_region;')

=cut

sub get_default_region {
  my $self = shift;
  
  # try to get credentials from instance role, but we may not be
  # executing on an EC2 or container.
  my $url = AWS_AVAILABILITY_ZONE_URL;
  
  my $ua = ref($self) ? $self->get_user_agent : new LWP::UserAgent;

  my $req = HTTP::Request->new( GET => $url );
     
  my $region = eval {
    my $rsp = $ua->request($req);
      
    # if not 200, then get out of Dodge
    die "could not get availability zone\n"
      unless $rsp->is_success;
    
    my $region = $rsp->content;
    $region =~s/([0-9]+)[a-z]+$/$1/;
    
    $region;
  };
  
  return $region;
}

sub set_credentials {
  my $self = shift;
  my $creds = shift || $self->get_ec2_credentials();
  
  if ( $creds->{aws_secret_access_key} && $creds->{aws_access_key_id} ) {
    $self->set_aws_secret_access_key($creds->{aws_secret_access_key});
    $self->set_aws_access_key_id($creds->{aws_access_key_id});
    $self->set_token($creds->{token});
    $self->set_expiration($creds->{expiration});
  }
  else {
    die "no credentials available\n";
  }
}

=pod

=head2 get_ec2_credentials (deprecated)

=head2 find_credentidals

 find_credentials( option => value, ...);

You normally don't want to use this method. It's automatically invoked
by the constructor if you don't pass in any credentials. Accepts a
hash or hash reference consisting of keys (C<order> or C<profile>) in
the same manner as the constructor.

=cut

sub get_ec2_credentials {
  goto &find_credentials;
}

sub find_credentials {
  my $self = shift;
  my %options = ref($_[0]) ? %{$_[0]} : @_;
  
  $options{order} = $self->get_order || [ qw/env role container file/ ];
  $options{profile} = $options{profile} || $self->get_profile;

  if (defined $options{profile} ) {
    $options{order} = ['file'];
  }
  
  my $creds = {};
    
  foreach (@{$options{order}}) {
    /env/ && do {
      if ( $ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} ) {
	@{$creds}{qw/source aws_access_key_id aws_secret_access_key token/} =
	  ('ENV',@ENV{qw/AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN/});
	last;
      }
    };

    /container/ && do {
      $creds = $self->get_creds_from_container();
      last if ! $@ && $creds->{container};
    };
    
    /role/ && do {
      $creds = $self->get_creds_from_role();
      last if ! $@ && $creds->{role};
    };
    
    /file/ && do {
      # look for ~/.aws/config and/or .aws/credentials
      use File::chdir;
      use File::HomeDir;

      #my $profile_naoptions_profile = $options{profile};
      
      foreach my $config ( ".aws/config", ".aws/credentials" ) {
	# reset this since we have hav
	my $profile_name = $options{profile};
	
	local $CWD = home;
	next unless -e $config;
	
	open my $fh, "<$config" or die "could not open credentials file!";
	
	my $last_profile = '';
	my $profile_to_find = $profile_name;
	
	# look for credentials...by interating through credentials file
	while (<$fh>) {
	  chomp;
	  # once we find a profile section that matches, undef it
	  # ./aws/credentials uses [profile-name]
	  # ./aws/config uses [profile profile-name]
	  
	  if (/^\s*region\s*=\s*(.*?)\s*$/ ) {
	    # go ahead and use this region setting IF:
	    # 1. this is the default profile (we may reset region later though)
	    # 2. the profile we want to use is this profile
	    # 3. we are not in a profile at all (this is yet another default)
	    if ( $last_profile =~/default/ ||
		 ($profile_to_find && $last_profile =~/$profile_to_find/) ||
		 ! $last_profile ) {
	      $self->set_region($1);
	    }
	  }
	  
	  if ( $profile_name ) {
	    if (/^\s*\[\s*profile\s+$profile_name\s*\]/) {
	      undef $profile_name;
	    }
	    elsif (/^\s*\[\s*$profile_name\s*\]/) {
	      undef $profile_name;
	      $last_profile = $_; 
	    }
	  } 
	  elsif (defined $profile_name && /^\s*\[\s*profile\s+/) {
	    last;
	  }
	  elsif (/^\s*aws_secret_access_key\s*=\s*(.*)$/) {
	    last if defined $creds->{aws_secret_access_key}; # next profile
	    $creds->{aws_secret_access_key} = $1;
	  }
	  elsif (/^\s*aws_access_key_id\s*=\s*(.*)$/) {
	    last if defined $creds->{aws_access_key_id}; # next profile
	    $creds->{aws_access_key_id} = $1;
	  }
	  elsif (/^\s*aws_session_token\s*=\s*(.*)$/) {
	    last if defined $creds->{token};
	    $creds->{token} = $1;
	  }
	}
	  
	close $fh;
	  
	$self->get_logger->debug(Dumper [ $creds ])
	  if $self->get_debug;
	
	$creds->{source} = $config if $creds->{aws_secret_access_key} && $creds->{aws_access_key_id};
      }
	
      last if $creds->{source};
    };
  }
  
  foreach ( keys %$creds) {
    $self->set($_, $creds->{$_});
  }
  
  return $creds;
}

=pod

=head2 is_token_expired

 is_token_expired( window-interval )

Returns true if the token is about to expire (or is
expired). C<window-interval> is the time in minutes before the actual
expiration time that the method should consider the token expired.
The default is 5 minutes.  Amazon states that new credentials will be
available I<at least> 5 minutes before a token expires.

=cut

sub is_token_expired {
  my $self = shift;
  my $window_interval = shift || 5;
  
  my $expiration_date = $self->get_expiration();
  
  my $expired = 0;

  if ( defined $expiration_date ) {
    # AWS recommends getting credentials 5 minutes prior to expiration
    my $g = timegm(strptime($expiration_date, "%Y-%m-%dT%H:%M:%S%Z"));
    $g -= $window_interval * 60;

    my $seconds_left = $g - time;

    if ( $self->get_debug ) {
      my $hours = int($seconds_left/3600);
      my $minutes = int(($seconds_left - $hours * 3600)/60);
      my $seconds = $seconds_left - ($hours * 3600 + $minutes * 60);
      $self->get_logger->debug(sprintf("%d hours %d minutes %d seconds until expiry\n", $hours, $minutes, $seconds));
    }
    
    $expired = ($seconds_left < 0) ? 1 : 0;
    
    $self->get_logger->debug(Dumper [ "EXPIRATION TIME: " . $expiration_date, "EXPIRED: " . $expired])
      if $self->get_debug;
  }

  return $expired;
}

=pod

=head2 get_creds_from_role

 get_creds_from_role()

Returns a hash, possibly containing access keys and a token.

=over 5

=item aws_access_key_id

The AWS access key.

=item aws_secret_access_key

The AWS secret key.

=item token

Security token used with access keys.

=item expiration

Token expiration date.

=item role

IAM role if available.

=item source

Will be 'IAM' if role and credentials found.

=back

=cut

sub get_creds_from_role {
  my $self = shift;

  my $creds = {};
  
  # try to get credentials from instance role
  my $url = AWS_IAM_SECURITY_CREDENTIALS_URL;
  
  my $ua = $self->get_user_agent;
  my $role;

  eval {
    # could be infinite, but I don't think so.  Either we get an
    # error ($@), or a non-200 response code
    while ( ! $creds->{token} ) {
      
      $url .= $role if $role;
      
      my $req = HTTP::Request->new( GET => $url );
      
      $self->get_logger->debug(Dumper [ "HTTP REQUEST:\n", $req ])
	if $self->get_debug;
      
      my $rsp = $ua->request($req);
      
      $self->get_logger->debug(Dumper [ "HTTP RESPONSE:\n", $rsp ])
	if $self->get_debug;
      
      # if not 200, then get out of Dodge
      last unless $rsp->is_success;
      
      if ( $role ) {
	$creds->{serialized} = $rsp->content;
	my $this = from_json($creds->{serialized});
	@{$creds}{qw/source role aws_access_key_id aws_secret_access_key token expiration/} =
	  ('IAM',$role, @{$this}{qw/AccessKeyId SecretAccessKey Token Expiration/});
      }
      else {
	$role = $rsp->content;
	$self->get_logger->debug(Dumper ['role', $role])
	  if $self->get_debug;

	last unless $role;
      }
    }
  };
  
  $creds->{error} = $@ if $@;
  
  $creds;
}

=pod

=head2 refresh_token

 refresh_token() (deprecated)
 refresh_credentials()

Retrieves a fresh set of IAM credentials.

 if ( $creds->is_token_expired ) {
   $creds->refresh_token()
 }

=cut

sub refresh_credentials {
  goto &refresh_token;
}

sub refresh_token {
  my $self = shift;
  my $creds;
  
  if ( $self->get_role && $self->get_role eq 'ECS' ) {
    $creds = $self->get_creds_from_container;
   }
  elsif ( $self->get_role ) {
    $creds = $self->get_creds_from_role;
  }

  $self->get_logger->debug(Dumper [$creds])
    if $self->get_debug;

  die "unable to refresh token!"
    unless ref($creds);
  
  $self->set_credentials($creds);
}


sub get_creds_from_container {
  my $self = shift;

  my $creds = {};
  
  if ( exists $ENV{AWS_CONTAINER_CREDENTIALS_RELATIVE_URI} ) {
    # try to get credentials from instance role
    my $url = sprintf("%s%s", AWS_CONTAINER_CREDENTIALS_URL, $ENV{AWS_CONTAINER_CREDENTIALS_RELATIVE_URI});
    
    my $ua = $self->get_user_agent;
    my $req = HTTP::Request->new( GET => $url );
    $req->header("Accept", "*/*");
    
    $self->get_logger->debug(Dumper [ "HTTP REQUEST:\n", $req ])
      if $self->get_debug;

    $self->get_logger->debug(Dumper [ $req->as_string ])
      if $self->get_debug;
    
    my $rsp = $ua->request($req);
    
    $self->get_logger->debug(Dumper [ "HTTP RESPONSE:\n", $rsp ])
      if $self->get_debug;
    
    # if not 200, then get out of Dodge
    if ( $rsp->is_success ) {
      $creds->{serialized} = $rsp->content;
      my $this = from_json($rsp->content);
      @{$creds}{qw/source container aws_access_key_id aws_secret_access_key token expiration/} =
	('IAM','ECS', @{$this}{qw/AccessKeyId SecretAccessKey Token Expiration/});
    }
    else {
      $self->get_logger->debug( "return code: " . $rsp->status_line . "\n");
    }
    
    $creds->{error} = $@ if $@;
  }
  
  $creds;
}

=pod

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut

1;
