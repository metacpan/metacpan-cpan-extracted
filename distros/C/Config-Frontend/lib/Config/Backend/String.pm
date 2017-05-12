package Config::Backend::String;

use 5.006;
use strict;

sub new {
  my $class=shift;
  my $strref=shift;
  my $self;

  if (ref($strref) ne "SCALAR") {
    die "Conf::String must be initialized with a reference to a string";
  }

  $self->{"ref"}=$strref;
  my $str=${$strref};

  my @cfgs;
  my $k=0;
  my $i=0;
  my $N=length $str;
  while ($i<$N) {
    if (substr($str,$i,2) eq "\n%") {
      if (substr($str,$i,3) ne "\n%%") {
	my $cfg=substr($str,$k,($i-$k));
	$cfg=~s/\n%%/\n%/g;
	$k=$i+2;
	push @cfgs,$cfg;
      }
      else {
	$i+=1;
      }
    }
    $i+=1;
  }
  if ($str ne "") {
    my $cfg=substr($str,$k,$N);
    $cfg=~s/\n%%/\n%/g;
    push @cfgs,$cfg;
  }

  for my $cfg (@cfgs) {
    my ($var,$val) = split /=/,$cfg,2;
    $self->{"cfg"}->{$var}=$val;
  }

  bless $self,$class;
return $self;
}

sub DESTROY {
  my $self=shift;
  $self->commit();
}

sub commit {
  my $self=shift;

  my $str="";
  my $delim="";
  for my $var (keys %{$self->{"cfg"}}) {
    $var=~s/\n%/\n%%/g;
    my $val=$self->{"cfg"}->{$var};
    $val=~s/\n%/\n%%/g;
    my $cfg="$var"."=".$val;
    $str.=$delim.$cfg;
    $delim="\n%";
  }
  ${$self->{"ref"}}=$str;
}

sub set {
  my ($self,$var,$val)=@_;
  $self->{"cfg"}->{$var}=$val;
  $self->commit();
}

sub get {
  my ($self,$var)=@_;
  return $self->{"cfg"}->{$var};
}

sub del {
  my ($self,$var)=@_;
  delete $self->{"cfg"}->{$var};
  $self->commit();
}

sub variables {
  my $self=shift;
return keys %{$self->{"cfg"}};
}

1;
__END__

=head1 NAME

Config::Backend::String - String backend for Config::Frontend.

=head1 Synopsys

 use Config::Frontend;
 use Config::Backend::String;
 
 open my $in,"<conf.cfg";
 my $string=<$in>;
 close $in;

 my $cfg=new Config::Frontend(new Config::Backend::String(\$string))

 print $cfg->get("config item 1");
 $cfg->set("config item 1","Hi There!");

 open my $out,">conf.cfg";
 print $out $string;
 close $out;

=head1 ABSTRACT

C<Config::Backend::String> is a backend module for C<Config::Frontend>.

=head1 Description

=head2 C<new(\$strref) --E<gt> Config::Backend::String>

If called with a reference to a string, will instantiate a C<Config::Backend::String> 
object. Otherwise will attempt to die.

=head2 C<set(var,val) --E<gt> void>

This method will set variable C<var> to value <val>. All set methods will
immediately reset the value of the string that the object references to.
So, all changes through 'set' will be visibile imediately to the 
program environment.

=head2 C<get(var) --E<gt> string>

Returns C<undef>, if var does not exist.
Returns the value of var (string), otherwise.

=head2 C<del(var) --E<gt> void>

Delets var from the string.

=head2 C<variables() --E<gt> list>

Will return a list of all variables in Conf::String.

=head1 SEE ALSO

L<Config::Backend::String|Config::Backend::String>, 
L<Config::Backend::SQL|Config::Backend::SQL>, 
L<Config::Backend::File|Config::Backend::File>,
L<Config::Frontend|Config::Frontend>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under LGPL. 

=cut

