package Amazon::SQS::Sample;

use strict;
use warnings;

use Amazon::SQS::Client;
use Amazon::SQS::Config;
use Amazon::SQS::Exception;
use Pod::Usage;

use Carp qw( carp croak );
use Data::Dumper;
use English qw(-no_match_vars);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(file service config endpoint_url));

use parent qw(Class::Accessor::Fast);

########################################################################
sub sample {
########################################################################
  my ($service) = @_;

  return;
}

########################################################################
sub help {
########################################################################
  my ($self) = @_;

  my $class = ref $self;
  $class =~ s/::/\//xsmg;
  my $path = $INC{"$class.pm"};

  return pod2usage( { -exitval => 1, -input => $path } );
}

########################################################################
sub check_error {
########################################################################
  my ( $self, $ex ) = @_;

  return
    if !$ex;

  croak $EVAL_ERROR
    if !ref $ex || ref $ex ne 'Amazon::SQS::Exception';

  print {*STDERR} sprintf "Caught Exception: %s\n",     $ex->getMessage();
  print {*STDERR} sprintf "Response Status Code: %s\n", $ex->getStatusCode();
  print {*STDERR} sprintf "Error Code: %s\n",           $ex->getErrorCode();
  print {*STDERR} sprintf "Error Type: %s\n",           $ex->getErrorType();
  print {*STDERR} sprintf "Request ID: %s\n",           $ex->getRequestId();
  print {*STDERR} sprintf "XML: %s\n",                  $ex->getXML();

  return;
}

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  foreach my $var ( keys %{$options} ) {
    next
      if $var !~ /\-/xsm;

    my $val = $options->{$var};

    $var =~ s/\-/_/xsmg;
    $options->{$var} = $val;
  }

  my $self = $class->SUPER::new($options);

  my $config;

  if ( $self->get_file ) {
    $config = Amazon::SQS::Config->new( file => $self->get_file );

    $self->set_config($config);
  }

  my $endpoint_url = $self->get_endpoint_url;

  my $service = Amazon::SQS::Client->new(
    $config ? $config->get_aws_access_key_id     : undef,
    $config ? $config->get_aws_secret_access_key : undef,
    { ServiceURL => $config ? $config->get_aws_endpoint_url : $endpoint_url }
  );

  $self->set_service($service);

  return $self;
}

1;
