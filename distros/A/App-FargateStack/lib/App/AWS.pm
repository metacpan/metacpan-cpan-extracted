package App::AWS;

use strict;
use warnings;

use App::FargateStack::Constants;
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use List::Util qw(none);

use JSON;

use Role::Tiny;

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(qw(_service_name));

########################################################################
sub profile {
########################################################################
  my ($self) = @_;

  return $self->get_profile // $ENV{AWS_PROFILE};
}

########################################################################
sub region {
########################################################################
  my ($self) = @_;

  return $self->get_region // 'us-east-1';
}

########################################################################
sub command {
########################################################################
  my ( $self, $command, $extra ) = @_;

  my $service = $self->get__service_name;

  if ( !$service ) {
    ($service) = ref($self) =~ /App::(.*)$/xsm;
    $service = lc $service;
  }

  my @cmd = ( 'aws', $service, $command );

  my @args = (
    '--profile' => $self->profile,
    '--region'  => $self->region,
    @{ $extra || [] },
  );

  my $result = $self->execute( @cmd, @args );

  $self->get_logger->trace( sub { return Dumper( [ result => $result ] ); } );

  return
    if !$result;

  chomp $result;

  my $obj = eval { return decode_json($result); };

  if ( !$obj && none { '--output' eq $_ } @args ) {
    # note that errors may occur when $result is just text, that's ok
    $self->get_logger->error($EVAL_ERROR);
    $self->get_logger->error( join q{ }, @cmd, @args );
  }

  return $obj ? $obj : $result;
}

########################################################################
sub check_result {
########################################################################
  my ( $self, @options ) = @_;

  # unpack args
  # check_result({ message => '', params => [] });
  # check_result( message => '', params => []);
  # check_result( message => '', single-param);
  # check_result( { message => '' }, multiple-params);

  my $args;

  if ( @options == 1 || ref $options[0] ) {
    $args = shift @options;
    $args->{params} //= [@options];
  }
  elsif ( @options % 2 ) {
    my $param = pop @options;
    $args = {@options};
    $args->{params} = [$param];
  }
  else {
    $args = {@options};
  }

  my $msg    = $args->{message} // 'Operation failed';
  my $params = $args->{params} || [];
  my $regexp = $args->{regexp};
  my $warn   = $args->{warn} // $FALSE;

  my $croak = $args->{croak} // $TRUE;

  my $result = $self->get_last_result;
  my $err    = $self->get_error // q{};

  return $TRUE
    if $result || !$err;

  # Accept either a qr// or a plain string for regexp
  if ( defined $regexp && ref $regexp ne 'Regexp' ) {
    $regexp = qr/$regexp/xsm;
  }

  my $base_msg = sprintf $msg, @{$params};
  my $full_msg = $base_msg . "\n$err";

  if ( $regexp && $err && $err =~ $regexp ) {
    if ($warn) {
      $self->get_logger->warn($full_msg);
    }
    return $FALSE;
  }

  croak $full_msg
    if $croak;

  $self->log_warn($full_msg);

  return $FALSE;
}

1;
