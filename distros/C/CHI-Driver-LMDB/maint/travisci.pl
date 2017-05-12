#!/usr/bin/env perl
# ABSTRACT: Munge travis.ci options
sub {
  my ($yaml) = @_;
  $yaml->{sudo} = 'required';
  $yaml->{dist} = 'trusty';
  splice @{ $yaml->{before_install} }, 0, 0, ('sudo apt-get install liblmdb-dev');
  for my $field ( @{ $yaml->{matrix}->{include} } ) {
    $field->{perl} = '5.22' if $field->{perl} eq '5.21';
  }

  # Nuke 5.22 + Sterile for now
  @{ $yaml->{matrix}->{include} } =
    grep { $_->{perl} ne '5.22' or $_->{env} !~ /STERILIZE_ENV=1/ } @{ $yaml->{matrix}->{include} };

  # Nuke 5.20 + Sterile due to 5.20.3 > not a known sterile
  @{ $yaml->{matrix}->{include} } =
    grep { $_->{perl} ne '5.20' or $_->{env} !~ /STERILIZE_ENV=1/ } @{ $yaml->{matrix}->{include} };

  # Nuke 5.10 + Sterile due -llmdb not working
  @{ $yaml->{matrix}->{include} } =
    grep { $_->{perl} ne '5.10' or $_->{env} !~ /STERILIZE_ENV=1/ } @{ $yaml->{matrix}->{include} };

  # Nuke 5.8 + Sterile due to 5.8.8 > not a known sterile
  @{ $yaml->{matrix}->{include} } =
    grep { $_->{perl} ne '5.8' or $_->{env} !~ /STERILIZE_ENV=1/ } @{ $yaml->{matrix}->{include} };

};

