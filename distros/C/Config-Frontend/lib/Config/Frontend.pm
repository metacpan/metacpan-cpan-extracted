package Config::Frontend;

use 5.006;
use strict;

our $VERSION = '0.18';

sub new {
  my $class=shift;
  my $backend=shift;
  my $self;

  $self->{"backend"}=$backend;
  $self->{"cache_items"}=0;
  $self->{"cache"}={};

  bless $self,$class;

return $self;
}

#####################################################
# Cache
#####################################################

sub cache {
  my ($self,$cache_on)=@_;
  $self->{"cache_items"}=$cache_on;
}

sub clear_cache {
  my ($self)=@_;
  $self->{"cache"}={};
}

#####################################################
# Variables
#####################################################

sub set {
  my ($self,$var,$val)=@_;
  if ($self->{"cache_items"}) {
    if (exists $self->{"cache"}->{$var}) {
      delete $self->{"cache"}->{$var};
    }
  }
  $self->{"backend"}->set($var,$val);
}

sub get {
  my ($self,$var,$preset)=@_;
  if ($self->{"cache_items"}) {
    if (exists $self->{"cache"}->{$var}) {
      return $self->{"cache"}->{$var};
    }
    else {
      my $val=$self->{"backend"}->get($var);
      if (not defined $val) { $val=$preset; }
      $self->{"cache"}->{$var}=$val;
      return $val;
    }
  }
  else {
    my $val=$self->{"backend"}->get($var);
    if (not defined $val) { $val=$preset; }
    return $val;
  }
}

sub del {
  my ($self,$var)=@_;
  $self->{"backend"}->del($var);
  if ($self->{"cache_items"}) {
    if (exists $self->{"cache"}->{$var}) {
      delete $self->{"cache"}->{$var};
    }
  }
  $self->del_props($var);
}

sub exists {
  my ($self,$var)=@_;
  if ($self->{"cache_items"}) {
    if (exists $self->{"cache"}->{$var}) {
      return defined $self->{"cache"}->{$var};
    }
    else {
      my $val=$self->{"backend"}->get($var);
      return defined $val;
    }
  }
  else {
    my $val=$self->{"backend"}->get($var);
    return defined $val;
  }
}

sub move {
  my ($self,$fromvar,$tovar)=@_;
  for my $prop ( $self->properties($fromvar) ) {
    if ($self->exists_prop($fromvar,$prop)) {
      $self->set_prop($tovar,$prop,$self->get_prop($fromvar,$prop));
      $self->del_prop($fromvar,$prop);
    }
  }
  if ($self->exists($fromvar)) {
    $self->set($tovar,$self->get($fromvar));
    $self->del($fromvar);
  }
}

#####################################################
# Properties
#####################################################

sub set_prop {
  my ($self,$var,$prop,$val)=@_;
  $self->set("#props_exist#.$var",1);
  $self->set("#prop#.$var.$prop",$val);
}

sub get_prop {
  my ($self,$var,$prop,$default)=@_;
return $self->get("#prop#.$var.$prop",$default);
}

sub del_prop {
  my ($self,$var,$prop)=@_;
return $self->del("#prop#.$var.$prop");
}

sub exists_prop {
  my ($self,$var,$prop)=@_;
  return $self->exists("#prop#.$var.$prop");
}

sub move_prop {
  my ($self,$var,$fromprop,$toprop)=@_;
  if ($self->exists($var,$fromprop)) {
    $self->set_prop($var,$toprop,$self->get_prop($var,$fromprop));
    $self->del_prop($var,$fromprop);
  }
}

sub del_props {
  my ($self,$var)=@_;
  if ($self->exists("#props_exist#.$var")) {
    my @props=$self->properties($var);
    for my $v (@props) {
      $self->del_prop($var,$v);
    }
    $self->del("#props_exist#.$var");
  }
}

#####################################################
# Variables/properties
#####################################################

sub properties {
  my ($self,$var)=@_;
  my $prefix="#prop#.$var";
  my $N=length($prefix);
  my @props;
  for my $prop ( grep { (substr($_,0,$N) eq $prefix) } $self->{"backend"}->variables() ) {
    push @props,substr($prop,$N+1);
  }
return @props;
}

sub variables {
  my ($self)=@_;
  my $prefix="#prop#.";
  my $N=length($prefix);
  return grep { (substr($_,0,$N) ne $prefix) } $self->{"backend"}->variables();
}

#####################################################
# info
#####################################################

sub cached {
  my $self=shift;
  my $items=scalar (keys %{$self->{"cache"}});
return $items;
}


1;
__END__

=head1 NAME

Config::Frontend - Configuration module with flexible backends

=head1 SYNOPSIS

 use Config::Frontend;
 use Config::Frontend::String;
 
 open my $in,"<conf.cfg";
 my $string=<$in>;
 close $in;

 my $cfg=new Conf(new Config::Frontend::String(\$string))

 print $cfg->get("config item 1");
 $cfg->set("config item 1","Hi There!");

 $cfg->set("cfg2","config 2");

 $cfg->del("config item 1");

 open my $out,">conf.cfg";
 print $out $string;
 close $out;

=head1 ABSTRACT

This module can be used to put configuration items in.
It's build up by using a backend and an interface. The
interface is through the C<Config::Frontend> module. A 
C<Config::Frontend> object is instantiated with a backend.

=head1 DESCRIPTION

=head2 C<new(backend) --E<gt> Conf>

Should be called with a pre-instantiated backend.
Returns a C<Config::Frontend> object.

=head2 C<set(var,val) --E<gt> void>

Sets a variable with value val in the backend.

=head2 C<get(var [, default]) --E<gt> string>

Returns the value for var as stored in the backend.
Returns C<undef>, if var does not exist in the backend and
C<default> has not been given. Otherwise, returns C<default>, if
var does not exist in the backend.

=head2 C<del(var) --E<gt> void>

Deletes a variable from the backend. All properties for the variable
are also removed.

=head2 C<move(fromvar,tovar) --E<gt> void>

Rename a variable  C<fromvar> with all it's properties to C<tovar>.
Note. If C<tovar> already exists, it will be overwritten.

=head2 C<exists(var) --E<gt> boolean>

Returns true, if C<var> exists. Returns false, otherwise.

=head2 C<set_prop(var,prop,val) --E<gt> void>

Sets property C<prop> for variable C<var> to value C<val>.

=head2 C<set_prop(var,prop,val) --E<gt> void>

Sets property C<prop> for variable C<var> to value C<val>.

=head2 C<get_prop(var,prop [,default]) --E<gt> string>

Returns property C<prop> for variable C<var>, or C<undef> cq. C<default>
if the property doesn't exist.

=head2 C<del_prop(var,prop) --E<gt> void>

Deletes property C<prop> for variable C<var>.

=head2 C<move_prop(var,fromprop,toprop) --E<gt> void>

Renames a property withing the bounds of a variable from C<fromprop>
to C<toprop>. Note. If C<toprop> already exists, it will be
overwritten.

=head2 C<exists_prop(var,prop) --E<gt> boolean>

Returns true if property C<prop> exists for variable C<var>.
False, otherwise.

=head2 C<variables() --E<gt> list of stored variables>

Returns a list all variables (not properties) stored in the backend.

=head2 C<properties(var) --E<gt> list of stored properties>

Returns a list of all properties for a variable in the backend.

=head2 C<cache(cache_on) --E<gt> void>

If C<cache_on> = true, this will turn on caching for
the C<get()> method. If caching is on, the get() method
will only go to the backend if a variable does not exist
in it's cache. The C<set()> function will delete a
variable from cache if it is updated. The C<del()> function
will delete a variable from cache.

=head2 C<clear_cache() --E<gt> void>

Clears the cache.

=head1 SEE ALSO

L<Config::Backend::String|Config::Backend::String>, 
L<Config::Backend::SQL|Config::Backend::SQL>, 
L<Config::Backend::File|Config::Backend::File>,
L<Config::Backend::INI|Config::Backend::INI>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under Artistic License. 

=cut
