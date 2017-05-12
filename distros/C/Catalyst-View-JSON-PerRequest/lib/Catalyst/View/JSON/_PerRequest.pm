package Catalyst::View::JSON::_PerRequest;

use HTTP::Status;
use Scalar::Util;

sub data {
  my ($self, $data) = @_;
  if($data) {
    if($self->{data}) {
      die "Can't set view data attribute if its already set";
    } else {
      $data = $self->{ctx}->model($data) unless ref $data;
      #die "Model $data does not do a required method 'TO_JSON'"
      #  unless $data->can('TO_JSON');

      return $self->{data} = $data;
    }
  } else {
    return $self->{data} ||= do {
      my $default_view_model = $self->{parent}->default_view_model;
      $default_view_model = $self->{ctx}->model($default_view_model)
        unless ref $default_view_model;
      $default_view_model;
    };
  }
}

sub handle_encode_error {
  my ($self, $value) = @_;
  if(defined $value) {
    $self->{handle_encode_error} = $value;
  }
  return $self->{handle_encode_error};
}

sub callback_param {
  my ($self, $value) = @_;
  if(defined $value) {
    $self->{callback_param} = $value;
  }
  return $self->{callback_param};
}

sub res { return shift->response(@_) }

sub response {
  my ($self, @proto) = @_;
  my ($status, @headers) = ();
  
  if( (ref \$proto[0] eq 'SCALAR') and
    Scalar::Util::looks_like_number($proto[0])
  ){
    $status = shift @proto;
  } else {
    $status = 200;
  }

  if(
    scalar(@proto) &&
    ref $proto[$#proto] eq 'HASH'
  ) {
    my $var = pop @proto;
    foreach my $key (keys %$var) {
      if($self->data->can('set')) {
        $self->data->set($key,$var->{$key});
      } else {
        $self->data->$key($var->{$key});
      }
    }
  } elsif(
    scalar(@proto) &&
    Scalar::Util::blessed($proto[$#proto])
  ) {
    my $obj = pop @proto;
    $self->data($obj);
  }

  if(@proto) {
    @headers = @proto;
  }

  $self->{ctx}->stats->profile(begin => "=> JSON->send". ($status ? "($status)": ''))
    if $self->{ctx}->debug; 

  my $res = $self->{ctx}->response;
  my $json = $self->render($self->data);

  $res->headers->push_header(@headers) if @headers;
  $res->status($status) unless $res->status != 200; # Catalyst default is 200...
  $res->content_type('application/json') unless $res->content_type;

  if(my $param = $self->{callback_param}) {
    my $cb = $c->req->query_parameter($cbparam);
    $cb =~ /^[a-zA-Z0-9\.\_\[\]]+$/ || die "Invalid callback parameter $cb";
    $json = "$cb($json)";
  }

  $res->body($json) unless $res->has_body;
  return $self->{ctx}->detach if $self->{auto_detach};
}

sub render {
  my ($self, $data) = @_;
  my $json = eval {
    $self->{json}->encode($self->data);
  } || do {
    if(my $cb = $self->handle_encode_error) {
      delete $self->{data}; # Clear out any existing data since its not valid
      return $cb->($self, $@);
    } else {
      # Bubble up the unhandled error
      die $@;
    }
  };
  return $json;
}

sub process {
  my ( $self, $c ) = @_;
  $self->send;
}

# Send Helpers.
foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
  my $subname = lc $helper;
  $subname =~s/http_//i;  
  eval "sub $subname { return shift->response(HTTP::Status::$helper,\@_) }";
  eval "sub detach_$subname { my \$self=shift; \$self->response(HTTP::Status::$helper,\@_); \$self->{ctx}->detach }";
}

1;

=head1 NAME

Catalyst::View::JSON::_PerRequest - Private object for JSON views that own data

=head1 SYNOPSIS

    No user servicable bits

=head1 DESCRIPTION

See L<Catalyst::View::JSON::PerRequest> for details.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::JSON::PerRequest>,
L<HTTP::Status>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
