package Config::Frontend::Tie;

use strict;
use Config::Frontend;

our $VERSION='0.02';

sub TIEHASH {
  my ($class,$conf)=@_;
  my $self;

  $self->{'conf'}=$conf;
  bless $self,$class;

return $self;
}

sub FETCH {
  my ($self,$key)=@_;
  return $self->{"conf"}->get($key);
}

sub STORE {
  my ($self,$key,$val)=@_;
  $self->{"conf"}->set($key,$val);
return $val;
}

sub DELETE {
  my ($self,$key)=@_;
  $self->{"conf"}->del($key);
}

sub EXISTS {
  my ($self,$key)=@_;
  return (defined $self->{"conf"}->get($key));
}

sub CLEAR {
  my ($self)=@_;
  my @vars=$self->{"conf"}->variables();
  for my $var (@vars) {
    $self->{"conf"}->del($var);
  }
}

sub FIRSTKEY {
  my ($self)=@_;
  my @vars=$self->{"conf"}->variables();
  $self->{"vars"}=\@vars;
return shift @{$self->{"vars"}};
}

sub NEXTKEY {
  my ($self)=@_;
return shift @{$self->{"vars"}};
}

sub UNTIE {
  # Nothing to do.
}

sub DESTROY {
  # Nothing to do.
}

1;
__END__

=head1 NAME

Config::Frontend::Tie - Ties hashes to Config::Frontend.

=head1 ABSTRACT

This module provides a hash interface to the Config::Frontend module.

=head1 SYNOPSYS

    tie my %conf,'Config::Frontend::Tie',new Config::Frontend(new Config::Backend::INIREG("Application"));

    ok($conf{"test"} eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
    ok($conf{"test1"} eq "NO!", "initial conf in \$string -> test1=NO!");
    ok($conf{"test2"} eq "%joep%", "initial conf in \$string -> test2=%joep%");
    ok($conf{"test3"} eq "ok\n%Hello", "initial conf in \$string -> test3=ok");

    $conf{"oesterhol"}="account";
    ok($conf{"oesterhol"} eq "account","initial conf in \$string -> oesterhol=account");

    for my $var (keys %conf) {
      print "$var=",$conf{$var},"\n";
    }

=head1 DESCRIPTION

The use of this module is obvious. One could look at L<perltie|perltie> for more
information.

=head1 AUTHOR

Hans Oesterholt-Dijkema E<lt>oesterhol@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Hans Oesterholt-Dijkema

This library is free software; you can redistribute it and/or modify
it under Artistic License. 


=cut




