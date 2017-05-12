#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#
package Crypt::PWSafe3::PasswordPolicy;


use Carp::Heavy;
use Carp;
use Exporter ();
use vars qw(@ISA @EXPORT);
use utf8;

$Crypt::PWSafe3::PasswordPolicy::VERSION = '1.01';

my %flagbits = (
        UseLowercase       => 0x8000,
        UseUppercase       => 0x4000,
        UseDigits          => 0x2000,
        UseSymbols         => 0x1000,
        UseHexDigits       => 0x0800,
        UseEasyVision      => 0x0400,
        MakePronounceable  => 0x0200
);


my @flags  = qw(UseLowercase UseUppercase UseDigits UseSymbols UseHexDigits UseEasyVision MakePronounceable);
my @fields = qw(raw MaxLength MinLowercase MinUppercase MinDigits MinSymbols);

foreach my $field (@fields, @flags) {
  eval  qq(
      *Crypt::PWSafe3::PasswordPolicy::$field = sub {
              my(\$this, \$arg) = \@_;
              if (\$arg) {
                return \$this->{$field} = \$arg;
              }
              else {
                return \$this->{$field};
              }
      }
    );
}

sub new {
  #
  # new PasswordPolicy object
  my($this, %param) = @_;
  my $class = ref($this) || $this;
  my $self = \%param;
  bless($self, $class);


  if (exists $param{raw}) {
    $self->decode($param{raw});
  }
  else {
    foreach my $field (@fields, @flags) {
      if(exists $param{$field}) {
        $self->{$field} = $param{$field};
      }
      else {
        $self->{$field} = 0;
      }
    }
  } 

  return $self;
}


sub decode {
  my($this, $raw) = @_;

  return if $raw eq '';

  # expected input: ffffnnnllluuudddsss

  # create a 6-elemt array
  my @exp = unpack("A4A3A3A3A3A3", $raw);

  # convert the hex strings to integers
  my %pwpol;
  foreach my $i (0 .. 5) {
    $pwpol{$fields[$i]} = hex($exp[$i]);
  }

  # assign the numbers to interns
  foreach my $field (@fields) {
    next if $field eq "raw";
    $this->{$field} = $pwpol{$field};
  }

  # convert binary flags to true/false values
  foreach my $bit (keys %flagbits) {
    if($pwpol{raw} & $flagbits{$bit}) {
      $this->{$bit} = 1;
    }
    else {
      $this->{$bit} = 0;
    }
  } 
}


sub encode {
  my($this) = @_;
 
  # create the bitmask
  my $mask = 0;
  foreach my $bit (keys %flagbits) {
    if($this->{$bit}) {
      $mask |= $flagbits{$bit};
    }
  } 

  # first 4hex chars for the bitmask of policy flags
  my $raw = sprintf "%04x", $mask;

  # followed by the number fields
  foreach my $field (@fields) {
    next if $field eq "raw";
    $raw .= sprintf "%03x", $this->{$field};
  }

  if($raw =~ /^0*$/) {
    return '';
  }
  else {
    return $raw;
  }
}



=head1 NAME

Crypt::PWSafe3::PasswordPolicy - represent a passwordsafe v3 passwprd policy entry of a record.

=head1 SYNOPSIS

 use Data::Dumper;
 use Crypt::PWSafe3;
 use Crypt::PWSafe3::PasswordPolicy;
 my $record = $vault->getrecord($uuid);
 my $policy = $record->policy;

 # print current values
 print Dumper($policy);

 # print some values
 print $policy->UseEasyVision;

 # change some of them
 $policy->MaxLength(8);
 $policy->MinSymbols(2);

 # put back into record
 $record->policy($policy);

 

=head1 DESCRIPTION

The following flags can be set (1 = TRUE, 0 = FALSE):

 - UseLowercase
 - UseUppercase
 - UseDigits
 - UseSymbols
 - UseHexDigits
 - UseEasyVision
 - MakePronounceable

The following numerical settings can be tuned:

 - MaxLength
 - MinLowercase
 - MinUppercase
 - MinDigits
 - MinSymbols

All of them can be called as functions, see SYNOPSIS for examples. If called with an argument,
the value will be changed, otherwise it will just returned.

The raw database value can be assigned by using the B<raw> parameter.

=head1 SEE ALSO

L<Crypt::PWSafe3::Record>

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011-2015 by T.v.Dein <tlinden@cpan.org>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms of the Artistic
License 2.0, see: L<http://www.perlfoundation.org/artistic_license_2_0>


=cut

1;
