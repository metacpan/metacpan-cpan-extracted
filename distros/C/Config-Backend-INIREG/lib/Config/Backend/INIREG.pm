package Config::Backend::INIREG;

use 5.006;
use strict;

use Config;
our $VERSION='0.02';

if ($Config{'osname'} eq "MSWin32") {
  require Config::Backend::Registry;
}
else {
  require Config::Backend::INI;
}

sub new {
  my $class=shift;
  my $appname=shift;
  my $self;

  if ($Config{'osname'} eq "MSWin32") {
    $self->{"cfg"}=new Config::Backend::Registry($appname);
  }
  else {
    my $home=$ENV{'HOME'};
    if (not defined $home) { $home="."; }
    elsif ($home eq "") { $home="."; }
    $self->{"cfg"}=new Config::Backend::INI("$home/.$appname.ini");
  }

  bless $self,$class;

return $self;
}

sub set { 
  my $self=shift;
  $self->{"cfg"}->set(@_);
}

sub get {
  my $self=shift;
  $self->{"cfg"}->get(@_);
}

sub del {
  my $self=shift;
  $self->{"cfg"}->del(@_);
}

sub variables {
  my $self=shift;
  $self->{"cfg"}->variables(@_);
}



1;
__END__

=head1 NAME

Config::Backend::INIREG - a .ini or registry backend for Config::Frontend.

=head1 ABSTRACT 

C<Config::Backend::INIREG> is an INI file (for UNIX OS's) or REGISTRY 
(for Windows) backend Config::Frontend. It uses Config::Backend::INI for
.ini files. And Config::Backend::Registry for windows registry access.

=head1 Description

See L<Config::Backend::INI|Config::Backend::INI> or
L<Config::Backend::Registry|Config::Backend::Registry>.


=head1 For Non MSWin32 Operating Systems

=head2 C<new(appname) --E<gt> Config::Backend::INIREG>

Invoked with a valid Application Name, it will try to instantiate
L<Config::Backend::INI|Config::Backend::INI> backend with C<$HOME/.appname.ini> 
filename.

will return a Config::Backend::INI object that is connected to
this file.

=head2 All other functions

Are the same as for L<Config::Frontend|Config::Frontend>.

=head1 For MSWin32 Operating Systems

=head2 C<new(appname) --E<gt> Config::Backend::INIREG>

Invoked with a valid Application Name, it will try to instantiate
L<Config::Backend::Registry|Config::Backend::Registry> backend with C<appname>.
Config::Backend::Registry will try to make the key 'appname' at  
C<HKEY_CURRENT_USER/Software/appname>.

will return a Config::Backend::Registry object that is connected to
this part of the windows registry.

=head2 All other functions

Are the same as for L<Config::Frontend|Config::Frontend>.

=head1 SEE ALSO

L<Config::Frontend|Config::Frontend>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under Artistic license. 

=cut



