package Acme::BABYMETAL;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

my @members = qw(SU-METAL YUIMETAL MOAMETAL);

sub new {
    my $class = shift;
    my $self  = bless {members => []}, $class;
    for my $member (@members) {
        $member =~ s|-|_|;
        my $module_name = 'Acme::BABYMETAL::' . $member;
        eval qq|require $module_name;|;
        push @{$self->{members}}, $module_name->new;
    }
    return $self;
}

sub homepage {
    my ($self) = @_;
    return 'http://www.babymetal.jp/';
}

sub youtube {
    my ($self) = @_;
    return 'https://www.youtube.com/BABYMETAL';
}

sub facebook {
    my ($self) = @_;
    return 'https://www.facebook.com/BABYMETAL.jp/';
}

sub instagram {
    my ($self) = @_;
    return 'https://www.instagram.com/babymetal_official/';
}

sub twitter {
    my ($self) = @_;
    return 'https://twitter.com/BABYMETAL_JAPAN';
}

sub members {
    my ($self, $member) = @_;
    return @{$self->{members}} unless $member;

    if ( $member =~ /^S/i ) {
        @members = $self->{members}[0];
    } elsif ( $member =~ /^Y/i ) {
        @members = $self->{members}[1];
    } elsif ( $member =~ /^M/i ) {
        @members = $self->{members}[2];
    } else {
        @members = @{$self->{members}};
    }
    return @members;
}

sub shout {
    my ($self) = @_;
    print "We are BABYMETAL DEATH!!\n";  
}


1;
__END__

=encoding utf-8

=head1 NAME

Acme::BABYMETAL - All about Japanese metal idol unit "BABYMETAL"

=head1 SYNOPSIS

  use Acme::BABYMETAL;

  my $babymetal = Acme::BABYMETAL->new;

  $babymetal->homepage;
  $babymetal->youtube;
  $babymetal->facebook;
  $babymetal->instagram;
  $babymetal->twitter;

  my @members = $babymetal->members;
  for my $member (@members) {
      my $metal_name     = $member->metal_name;
      my $name_ja        = $member->name_ja;
      my $first_name_ja  = $member->first_name_ja;
      my $family_name_ja = $member->family_name_ja;
      my $name_en        = $member->name_en;
      my $first_name_en  = $member->first_name_en;
      my $family_name_en = $member->family_name_en;
      my $birthday       = $member->birthday;
      my $age            = $member->age;
      my $blood_type     = $member->blood_type;
      my $hometown       = $member->hometown;
      my $shout          = $member->shout;
  }

  my ($su_metal) = $babymetal->members('SU-METAL');
  my ($yuimetal) = $babymetal->members('YUIMETAL');
  my ($moametal) = $babymetal->members('MOAMETAL');

  $su_metal->shout;  # SU-METAL DEATH!!
  $yuimetal->shout;  # YUIMETAL DEATH!!
  $moametal->shout;  # MOAMETAL DEATH!!
  $babymetal->shout; # We are BABYMETAL DEATH!!


=head1 DESCRIPTION

BABYMETAL is a Japanese metal idol unit.

Acme::BABYMETAL provides an easy method to information of BABYMETAL.

=head1 LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hondallica E<lt>hondallica@gmail.comE<gt>

=cut

