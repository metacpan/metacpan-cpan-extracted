#!perl
package CGI::JSONRPC::Base;

use strict;
use warnings;

use JSON::Syck;
use JSON::Syck qw(Dump Load);

(our $JAVASCRIPT = __FILE__) =~ s{\.pm$}{.js};

1;

sub new {
  my($class, %args) = @_;
  return bless { dispatcher => $class->default_dispatcher, %args }, $class;
}

sub default_dispatcher {
  'CGI::JSONRPC::Dispatcher'
}


sub run_json_request {
  my($self, $json) = @_;
  my $data = (JSON::Syck::Load($json))[0];
    
  die "Did not get a hash from RPC request!" 
    unless(ref($data) && ref($data) eq 'HASH');
    
  unless($data->{method}) {
    warn "JSONRPC payload did not have a method!";
    return $self->return_error($data, "JSONRPC payload did not have a method!"); 
  }

  return $self->run_data_request($data);
}

sub data_request {
  my($self, $data) = @_;
  $data->{params} ||= [];
  my $method = "$self->{dispatcher}\::$data->{method}";
  no strict 'refs';
  return(&{$method}($self, $data->{id}, @{$data->{params}}));
}

sub run_data_request {
  my($self, $data) = @_;
    
  my @rv = eval { $self->data_request($data); };

  if(my $error = $@) {
    warn $error;
    return $self->return_error($data, $error);
  }
    
  if(defined $data->{id}) {
    return $self->return_result($data, \@rv);
  } else {
    return "";
  }
}

sub return_result {
  my($self, $data, $result) = @_;
  return JSON::Syck::Dump({ id => $data->{id}, result => $result })
}

sub return_error {
  my($self, $data, $error) = @_;
  return JSON::Syck::Dump({
    id      =>  (defined $data->{id} ? $data->{id} : undef),
    error   =>  $error
  });
}

sub return_javascript {
  my $self = shift;
  if(my $class = $self->{path_info}) {
    my $data = {
      params => [ $class ], method => "jsonrpc_javascript", id => 0
    };
    return $self->data_request($data);
  } else {
    return $self->jsonrpc_javascript($self);
  }
}

sub jsonrpc_javascript {
  my $self = shift;
  my $fh;
  open($fh, '<', $JAVASCRIPT) or die $!;
  my @rv = <$fh>;
  if($self->{path}) {
    push(@rv, "\nJSONRPC.URL = '$self->{path}';\n");
  }
  return join('', @rv);
}
    



