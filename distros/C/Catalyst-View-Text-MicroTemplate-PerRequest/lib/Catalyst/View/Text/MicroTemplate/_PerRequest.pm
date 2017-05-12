package Catalyst::View::Text::MicroTemplate::_PerRequest;

use HTTP::Status;
use Scalar::Util;
use Catalyst::Utils;

sub data {
  my ($self, $data) = @_;
  if($data) {
    if($self->{data}) {
      die "Can't set view data attribute if its already set";
    } else {
      $data = $self->{ctx}->model($data) unless ref $data;
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

sub handle_process_error {
  my ($self, $value) = @_;
  if(defined $value) {
    $self->{handle_process_error} = $value;
  }
  return $self->{handle_process_error};
}

sub template {
  my ($self, $value) = @_;
  
  if(defined $value) {
    if(
      Scalar::Util::blessed($value) &&
      $value->isa('Catalyst::Action')
    ) {
      $value = "$value";
    }
    $self->{template} = $value;
  }
  return $self->{template} || $self->template_factory;
}

sub template_factory {
  my $self = shift; 

  if(defined $_[0]) {
    die 'The value must be a subroutine reference'
      unless ref($_[0]) eq 'CODE';
    $self->{template_factory} = $_[0];
  }

  unless(exists $self->{template_factory}) {
    $self->{template_factory} = $self->{parent}->default_template_factory;
  }

  return $self->{template_factory}->($self, $self->{ctx});
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
      $self->data->$key($var->{$key});
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

  if($self->{ctx}->debug) {
    my $name = Catalyst::Utils::class2classsuffix($self->{parent}->catalyst_component_name);
    $self->{ctx}->stats->profile(begin => "=> ${name}->response($status)")
  }

  my $res = $self->{ctx}->response;
  $res->headers->push_header(@headers) if @headers;
  $res->status($status) unless $res->status != 200; # Catalyst default is 200...
  $res->content_type($self->{parent}->content_type) unless $res->content_type;
  
  my $out;
  MT: {
    # Localize this so we don't clobber the global
    local $self->{mt}->{template_args};
    # Allow the data model to provide named args
    my %args = $self->data->can('TO_HASH') ? $self->data->TO_HASH : ();
    # Allow the view object to provide named args as well
    if(my $extra_cb = $self->{parent}->can('extra_template_args')) {
      %args = ($extra_cb->($self->{parent}, $self, $self->{ctx}), %args);
    }
    # Merge stash args if requested
    if($self->{parent}->merge_stash) {
      %args = (%args, %{$self->{ctx}->stash});
    }

    $self->{mt}->template_args({ c => $self->{ctx}, %args});
    $out = $self->render($self->template, $self->data);
  }

  $res->body($out) unless $res->has_body;
}

sub render {
  my ($self, $template, @data) = @_;
  my $out = eval {   
    $self->{mt}->render($template, @data);
  } || do {
    $self->{ctx}->log->error("Can't render template '$template', $@") if $self->{ctx}->debug;
    if(my $cb = $self->handle_process_error) {
      delete $self->{data}; # Clear out any existing data since its not valid
      delete $self->{handle_process_error}; # Avoid recursion if your error handler is iself bad
      $self->{ctx}->log->info("Invoking process error callback") if $self->{ctx}->debug;
      return $cb->($self, $@);
    } else {
      # Bubble up the unhandled error
      $self->{ctx}->log->info("Rethrowing template error since there's no 'handle_process_error' defined")
        if $self->{ctx}->debug;
      die $@;
    }
  };

  return $out;
}

sub process {
  my ( $self, $c ) = @_;
  $self->response;
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

Catalyst::View::Text::MicroTemplate::_PerRequest - Private object for Text::MicroTemplate views that own data

=head1 SYNOPSIS

    No user servicable bits

=head1 DESCRIPTION

See L<Catalyst::View::Text::MicroTemplate::PerRequest> for details.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<Catalyst::View::Text::MicroTemplate::PerRequest>,
L<HTTP::Status>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2016, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
