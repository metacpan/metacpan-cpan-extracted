package Config::Backend::INI;

use 5.006;
use strict;
use Config::IniFiles;

our $VERSION='0.12';

my $DEFSECT="!!Conf::INI!!default!!";

sub new {
  my $class=shift;
  my $file=shift;

  my $self;
  my $ini;

  if ((-z $file) or (not -e $file)) {
    $ini=new Config::IniFiles();
    $ini->newval($DEFSECT,$DEFSECT,1);
    $ini->WriteConfig($file);
  }
  $ini=new Config::IniFiles(-file => $file);
  if (not defined $ini) {
    die "Cannot open ini file $file\n";
  }

  $self->{"ini"}=$ini;

  bless $self,$class;

return $self;
}

sub DESTROY {
  my $self=shift;
  $self->{"ini"}->RewriteConfig();
}

sub set {
  my $self=shift;
  my $_var=shift;
  my $val=shift;

  my ($section,$var)=split /[.]/,$_var,2;
  if (not defined $var) {
    $var=$section;
    $section=$DEFSECT;
  }
  if (not defined $self->{"ini"}->setval($section,$var,$val)) {
    $self->{"ini"}->newval($section,$var,$val);
  }

  $self->{"ini"}->RewriteConfig();

}

sub get {
  my $self=shift;
  my $_var=shift;

  my ($section,$var)=split /[.]/,$_var,2;
  if (not defined $var) {
    $var=$section;
    $section=$DEFSECT;
  }
return $self->{"ini"}->val($section,$var);
}

sub del {
  my $self=shift;
  my $_var=shift;

  my ($section,$var)=split /[.]/,$_var,2;
  if (not defined $var) {
    $var=$section;
    $section=$DEFSECT;
  }
  $self->{"ini"}->delval($section,$var);

  $self->{"ini"}->RewriteConfig();

}

sub variables {
  my $self=shift;
  my @vars;

  for my $s ($self->{"ini"}->Sections()) {
    for my $v ($self->{"ini"}->Parameters($s)) {
      if ($s eq $DEFSECT) { 
	if ($v ne $DEFSECT) {
	  push @vars,$v;
	}
      }
      else {
	push @vars,"$s.$v";
      }
    }
  }
return @vars;
}

1;

__END__

=head1 NAME

Config::Backend::INI - a .ini file backend for conf

=head1 ABSTRACT

C<Config::Backend::INI> is an INI file (windows alike) backend for Conf. 
It handles a an INI file with identifiers that are 
assigned values. Identifiers with a '.' (dot) in it,
are divided in a section and a variable.

=head1 Description

This module uses Config::IniFiles for reading and writing .INI files.
Each call to C<set()> or C<del()> will immediately result in a 
commit to the .ini file.

=head2 C<new(filename) --E<gt> Config::Backend::INI>

Invoked with a valid filename, 
will return a Config::Backend::INI object that is connected to
this file.

=head2 DESTROY()

This function will untie from the ini file.

=head2 C<set(var,value) --E<gt> void>

Sets config key var to value. If var contains a dot (.),
the characters prefixing the '.' will represent a section
in the .ini file. Sample:

  $conf->set("section.var","value")

will result in:

  [section]
  var=value

=head2 C<get(var) --E<gt> string>

Reads var from config. Returns C<undef>, if var does not
exist. Returns the value of configuration item C<var>,
otherwise.

=head2 C<del(var) --E<gt> void>

Deletes variable var from the Configuration.

=head2 C<variables() --E<gt> list of strings>

Returns all variables in the configuraton backend.

=head1 SEE ALSO

L<Config::Frontend|Config::Frontend>.

=head1 AUTHOR

Hans Oesterholt-Dijkema, E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under LGPL. 

=cut



