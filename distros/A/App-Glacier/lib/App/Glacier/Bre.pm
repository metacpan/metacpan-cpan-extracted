package App::Glacier::Bre;
use strict;
use warnings;
use parent 'Net::Amazon::Glacier';
use App::Glacier::HttpCatch;
use App::Glacier::Signature;
use Carp;
use version 0.77;
use LWP::UserAgent;
use JSON;

sub new {
    my ($class, %opts) = @_;
    my $region = (delete $opts{region} || _get_instore_region())
	or return $class->new_failed('availability region not supplied');
    my $access = delete $opts{access};
    my ($secret,$token);
    if (defined($access)) {
	$secret = delete $opts{secret}
	  	or $class->new_failed('secret not supplied');
    } else {
	($access, $secret, $token) = _get_instore_creds()
	    or return $class->new_failed('no credentials supplied');
    }
    my $self = $class->SUPER::new($region, $access, $secret);
    if ($token) {
	# Overwrite the 'sig' attribute.
	# FIXME: The attribute itself is not documented, so this 
	# method may fail if the internals of the base class change
	# in its future releases.
	# This approach works with Net::Amazon::Glacier 0.15
	$self->{sig} = new App::Glacier::Signature($self->{sig}, $token);
    }
    return $self;
}

sub new_failed {
    my ($class, $message) = @_;
    bless { _error => $message }, $class;
}

my $istore_base_url = "http://169.254.169.254/latest/";
my $istore_document_path = "dynamic/instance-identity/document";
my $istore_credentials_path = "meta-data/iam/security-credentials/";

sub _get_instore_region {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $response = $ua->get($istore_base_url . $istore_document_path);
    unless ($response->is_success) {
	return undef;
    }
    my $doc = JSON->new->decode($response->decoded_content);
    return $doc->{region};
}

sub _get_instore_creds {
    my $ua = LWP::UserAgent->new(timeout => 10);
    my $url = $istore_base_url . $istore_credentials_path;
    my $response = $ua->get($url);
    unless ($response->is_success) {
	return undef;
    }
    chomp(my $name = $response->decoded_content);
    $url .= $name;
    $response = $ua->get($url);
    unless ($response->is_success) {
	return undef;
    }
    my $doc = JSON->new->decode($response->decoded_content);
    return ($doc->{AccessKeyId}, $doc->{SecretAccessKey}, $doc->{Token});
}

# Fix bugs in Net::Amazon::Glacier 0.15
if (version->parse($Net::Amazon::Glacier::VERSION) <= version->parse('0.15')) {
    no strict 'refs';
    *{__PACKAGE__.'::list_vaults'} = \&list_vaults_fixed;
    *{__PACKAGE__.'::get_vault_notifications'} = \&get_vault_notifications_fixed;
}

sub _eval {
    my $self = shift;
    my $method = shift;
    my $wantarray = wantarray;
    my $ret = http_catch(sub {
	                    $wantarray ? [ $self->${\$method}(@_) ]
				       : $self->${\$method}(@_)
			 },
			 err => \my %err,
			 args => \@_);
    if (keys(%err)) {
	$self->{_last_http_err} = \%err;
    } else {
	$self->{_last_http_err} = undef;
    }
    return (wantarray && ref($ret) eq 'ARRAY') ? @$ret : $ret;
}

sub lasterr {
    my ($self, $key) = @_;
    return $self->{_error} if exists $self->{_error};
    return undef unless defined $self->{_last_http_err};
    return 1 unless defined $key;
    return  $self->{_last_http_err}{$key};
}

sub last_error_message {
    my ($self) = @_;
    return $self->{_error} if exists $self->{_error};
    return "No error" unless $self->lasterr;
    return $self->lasterr('mesg') || $self->lasterr('text');
}

# list_vaults_fixed
# A fixed version of Net::Amazon::Glacier::list_vaults. This version correctly
# formats the query string in accordance with the specification[1].
# The bug (along with the fix) was reported on December 15, 2018[2].
# Hopefully it will be fixed in further versions of Net::Amazon::Glacier.
# Until then, the initialization code above overrides installs this method
# as list_vaults, if Net::Amazon::Glacier version 0.15 is in use.
#
# [1] https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html
# [2] https://rt.cpan.org/Public/Bug/Display.html?id=128029
sub list_vaults_fixed {
    my ($self) = @_;
    my @vaults;

#    print "using fixed list_vaults\n";
    my $marker;
    do {
	#10 is the default limit, send a marker if needed
        my $res = $self->_send_receive(
	    GET => "/-/vaults?limit=10" . ($marker ? '&marker='.$marker : '')
	);
        # updated error severity
        croak 'list_vaults failed with error ' . $res->status_line unless $res->is_success;
        my $decoded = $self->_decode_and_handle_response( $res );

        push @vaults, @{$decoded->{VaultList}};
        $marker = $decoded->{Marker};
    } while ( $marker );

    return ( \@vaults );
}

# get_vault_notifications_fixed
# A fixed version of Net::Amazon::Glacier::get_vault_notifications.
# Fixes the use of HTTP method[1].
#
# The bug (along with the fix) was reported on December 15, 2018[2].
# Hopefully it will be fixed in further versions of Net::Amazon::Glacier.
# Until then, the initialization code above overrides installs this method
# as get_vault_notifications, if Net::Amazon::Glacier version 0.15 is in use.
#
# [1] https://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html
# [2] https://rt.cpan.org/Public/Bug/Display.html?id=128028
sub get_vault_notifications_fixed {
    my ($self, $vault_name, $sns_topic, $events) = @_;

    croak "no vault name given" unless $vault_name;

    my $res = $self->_send_receive(
                GET => "/-/vaults/$vault_name/notification-configuration",
              );
    # updated error severity
    croak 'get_vault_notifications failed with error ' . $res->status_line
	unless $res->is_success;

    return $self->_decode_and_handle_response( $res );
}


our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    croak $self->{_error} if exists $self->{_error};
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    if ($meth =~ s/^([A-Z])(.*)/\L$1\E$2/) {
	return $self->_eval($meth, @_);
    }
    croak "unknown method $AUTOLOAD";
}

1;
