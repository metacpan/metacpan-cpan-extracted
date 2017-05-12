package Data::RuledValidator::Util;

use strict;
use warnings qw/all/;
use base qw/Exporter/;

our @EXPORT = qw(NEED_ALIAS ALLOW_NO_VALUE RKEYS _arg _vand _vor);

our $VERSION = 0.02;

sub NEED_ALIAS      { 1 }
sub ALLOW_NO_VALUE  { 2 }

# '&' validation for multiple values
sub _vand{
  my ($self, $key, $c, $val, $sub) = @_;
  my $ok = 1;
  foreach my $v (@$val){
    my $_ok = 1;
    if($_ok = $sub->($self, $v) ? 1 : 0){
      push @{$self->{right}->{"${key}_$c"} ||= []},  $v;
    }else{
      push @{$self->{wrong}->{"${key}_$c"} ||= []},  $v;
    }
    $ok &= $_ok;
  }
  return $ok;
}

# '|' validation for multiple values
sub _vor{
  my ($self, $key, $c, $val, $sub) = @_;
  my $ok = 0;
  foreach my $v (@$val){
    my $_ok = 0;
    if($_ok = $sub->($self, $v) ? 1 : 0){
      push @{$self->{right}->{"${key}_$c"} ||= []},  $v;
    }else{
      push @{$self->{wrong}->{"${key}_$c"} ||= []},  $v;
    }
    $ok |= $_ok;
  }
  return $ok;
}

sub _arg{# to escape quote, use \
  shift if $_[0] eq __PACKAGE__;
  # it is refer to Perl memo()
  # http://www.din.or.jp/~ohzaki/perl.htm#CSV2Values
  my($arg) = @_;
  my @arg;
  $arg =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
  return \@arg if $arg eq ',';
  while($arg){
    if($arg =~ s/^\s*('[^']*(?:\\'[^']*)*')\s*,//){
      # value quoted with ""
      $_ = $1;
      push @arg, scalar(s/^\s*'(.*)'\s*$/$1/, s/\\'/'/g, $_)
    }elsif($arg =~ s/^\s*("[^"]*(?:\\"[^"]*)*")\s*,//){
      # value quoted with ''
      $_ = $1;
      push @arg, scalar(s/^\s*"(.*)"\s*$/$1/, s/\\"/"/g, $_)
    }elsif($arg =~s/^([^,]+),//){
      $_ = $1;
      s/\s*$//g;
      push @arg, $_ unless $_ eq '';
    }else{
      warn $arg;
    }
    $arg =~s/^[,\s]*//;
  }
  return @arg;
}

1;

=head1 Name

Data::RuledValidator::Util - utilitie functions to be used Data::RuledValidator*

=head1 Description

=head1 Synopsys

=head1 Author

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 Copyright

Copyright 2006-2007 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
