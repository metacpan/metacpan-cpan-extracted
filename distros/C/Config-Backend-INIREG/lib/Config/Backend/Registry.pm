package Config::Backend::Registry;

use 5.006;
use strict;

use Win32::TieRegistry qw(KEY_READ KEY_WRITE KEY_ALL_ACCESS);

sub new {
  my $class=shift;
  my $appname=shift;
  my $self=shift;

  $self->{"reg"}=new Win32::TieRegistry "CUser", { Access => KEY_ALL_ACCESS(), Delimiter => "/" };
  $self->{"root"}=$self->{"reg"}->Open("Software/$appname", { Access => KEY_ALL_ACCESS(), Delimiter => "/" });
  if (not defined $self->{"root"}) {
    $self->{"reg"}->CreateKey("Software/$appname",{ Access => KEY_ALL_ACCESS(), Delimiter => "/" });
    $self->{"root"}=$self->{"reg"}->Open("Software/$appname", { Access => KEY_ALL_ACCESS(), Delimiter => "/" });
  }
  $self->{"root"}->SetValue(".$appname","1");

  bless $self,$class;
return $self;
}

sub DESTROY {
}

sub set {
  my ($self,$var,$val)=@_;
  my $vars;

  if (not $self->exists($var,$val)) {
    $vars=$self->{"root"}->GetValue(".vars");
    print "vars=$vars\n";
    if (not defined $vars) {
      $vars=$var;
    }
    elsif ($vars eq "") {
      $vars=$var;
    }
    else {
      $vars.=",#%#,".$var;
    }
    $self->{"root"}->SetValue(".vars",$vars);
  }

  $self->{"root"}->SetValue($var,$val);
  $self->{"root"}->Flush();
}

sub get {
  my ($self,$var)=@_;
return $self->{"root"}->GetValue($var);
}

sub del {
  my ($self,$var)=@_;
  $self->{"root"}->RegDeleteValue($var);
  my $vars=$self->{"root"}->GetValue(".vars");
  print "delete: vars=$vars\n";
  my @V=split /,#%#,/, $vars;
  $vars="";
  my $delim="";
  for my $v (@V) {
    if ($v ne $var) {
      $vars.=$delim.$v;
      $delim=",#%#,";
    }
  }
  $self->{"root"}->SetValue(".vars",$vars);
  print "deleted: vars=$vars\n";
}

sub variables {
  my $self=shift;
  my $vars=$self->{"root"}->GetValue(".vars");
  my @V=split /,#%#,/,$vars;
return @V;
}

sub exists {
  my ($self,$var)=@_;
  my $val=$self->{"root"}->GetValue($var);
  if (not defined $val) {
    return 0;
  }
  else {
    return 1;
  }
}

1;
__END__

=head1 NAME

Config::Backend::Registry - a registry backend for Config::Frontend.

=head1 ABSTRACT 

C<Config::Backend::Registry> is normally used through L<Config::Backend::INIREG>.
But it can also function alone. It provides a backend for L<Config::Frontend>
that uses the Windows Registry as configuration base.

=head1 Description

This module uses L<Win32::TieRegistry> for reading and writing the 
windows registry. Each call to C<set()> or C<del()> will immediately result in a 
commit to the Windows registry.

=head2 C<new(appname) --E<gt> Config::Backend::Registry>

Invoked with an application name, 
will return a Config::Backend::Registry object that is connected to
the windows registry at location C<HKEY_CURRENT_USER/Software/appname>.

=head2 DESTROY()

This function will untie from the registry.

=head2 C<set(var,value) --E<gt> void>

Sets config key var to value. 

=head2 C<get(var) --E<gt> string>

Reads var from config. Returns C<undef>, if var does not
exist. Returns the value of configuration item C<var>,
otherwise.

=head2 C<del(var) --E<gt> void>

Deletes variable var from the Configuration.

=head2 C<variables() --E<gt> list of strings>

Returns all variables set through this backend in the windows
registry at location C<HKEY_CURRENT_USER/Software/appname>.

=head3 Important Note

The enumeration functions of C<Win32::TieRegistry> turned out
not to work on C<Win2K>. I've programmed a workaround by keeping
an administration of variables in the special variable C<'.vars'>.

=head1 SEE ALSO

L<Config::Frontend|Config::Frontend>, L<Win32::TieRegistry|Win32::TieRegistry>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under Artistic license. 

=cut





