package CGI::Portal::Controls::register;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Insert user info

use strict;

use Digest::MD5 qw(md5_hex);
use CGI::Portal::Scripts::logon;
use CGI::Portal::Scripts::register;
use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my $self = shift;

            # Validate
  unless ($self->input_error("user","password","cpassw","email") || $self->register_error()){

            # Get the current index
    my $cc = $self->{'rdb'}->exec("select $self->{'conf'}{'user_index_field'} from $self->{'conf'}{'user_table'} order by $self->{'conf'}{'user_index_field'} desc limit 1")->fetch;
    my $c = $cc->[0]+1;

            # Hash the passw
    my $enc_passw = md5_hex($self->{'in'}{'password'});

            # Collect values for SQL
    my @additional_values;
    foreach my $f (@{$self->{'conf'}{'user_additional'}}) {
      push(@additional_values, $self->{'in'}{$f});
    }

            # Escape values
    my $values = $self->{'rdb'}->escape($c,$self->{'in'}{'user'},$enc_passw,@additional_values);

            # Join fields for SQL
    my $fields = join(',', @{$self->{'conf'}{'user_additional'}});

            # Insert
    $self->{'rdb'}->exec("insert into $self->{'conf'}{'user_table'} ($self->{'conf'}{'user_index_field'},$self->{'conf'}{'user_user_field'},$self->{'conf'}{'user_passw_field'},$fields) values ($values)");

            # Assign user to object
    $self->{'user'} = $self->{'in'}{'user'};

            # Redirect
    $self->CGI::Portal::Scripts::logon::launch();
    return;
  }

            # Redirect
  $self->CGI::Portal::Scripts::register::launch();
  return;
}

            # Validate
sub input_error {
  my ($self, @requireds)  = @_;
  my $input_error = 0;

            # Loop thru requireds
  foreach my $required (@requireds) {
    if (!$self->{'in'}{$required}){
      $self->{'tmpl_vars'}{"${required}_msg"} = "Field is required";
      $input_error = 1;
    }
  }

  if ($input_error) {
    $self->{'tmpl_vars'}{'result'} = "Missing fields, no changes made.";
  }

  return $input_error;
}

            # Validate
sub register_error {
  my ($self)  = @_;
  my $input_error = 0;

            # See if user name is available
  my $r = $self->{'rdb'}->exec("select $self->{'conf'}{'user_index_field'} from $self->{'conf'}{'user_table'} where $self->{'conf'}{'user_user_field'} like " . $self->{'rdb'}->escape($self->{'in'}{'user'}) . " limit 1")->fetch;
  if ($r->[0]) {
    $self->{'tmpl_vars'}{'user_msg'} = "User name $self->{'in'}{'user'} is not available";
    $input_error = 1;
  }

            # User name requirements
  if ($self->{'in'}{'user'} && $self->{'in'}{'user'} =~ /[^\w ]/i) {
    $self->{'tmpl_vars'}{'user_msg'} = "User names must consist of letters or numbers";
    $input_error = 1;
  }
  if ($self->{'in'}{'user'} && $self->{'in'}{'user'} =~ / /i) {
    $self->{'tmpl_vars'}{'user_msg'} = "User names cannot contain spaces";
    $input_error = 1;
  }
  if ($self->{'in'}{'user'} && $self->{'in'}{'user'} =~ /................/i) {
    $self->{'tmpl_vars'}{'user_msg'} = "User names must consist of less than 16 characters";
    $input_error = 1;
  }

            # Password requirements
  if ($self->{'in'}{'password'} && $self->{'in'}{'password'} !~ /..../i) {
    $self->{'tmpl_vars'}{'password_msg'} = "Passwords must consist of at least 4 characters";
    $input_error = 1;
  }
  if ($self->{'in'}{'cpassw'} && $self->{'in'}{'password'} ne $self->{'in'}{'cpassw'}) {
    $self->{'tmpl_vars'}{'cpassw_msg'} = "Please reenter and confirm password";
    $input_error = 1;
  }

  return $input_error;
}