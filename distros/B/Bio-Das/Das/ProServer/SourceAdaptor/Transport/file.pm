#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Transport layer for file-based storage (slow)
#
package Bio::Das::ProServer::SourceAdaptor::Transport::file;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Bio::Das::ProServer::SourceAdaptor::Transport::generic;
use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);

sub init {
  my $self = shift;
  $self->{'capabilities'} = {
                             'features' => '1.0',
                            };
}

sub fh {
  my $self = shift;

  unless($self->{'fh'}) {
    my $fn = $self->{'filename'} || $self->config->{'filename'};
    open($self->{'fh'}, $fn) or die qq(Could not open $fn);
  }
  return $self->{'fh'};
}

#########
# assume text files are tab delimited (?)
# queries are of the form:
# field1 = 'value'
# field3 like '%value%'
# compound queries not (yet) supported
#
sub query {
  local $/  = "\n";
  my $self  = shift;
  my $query = shift;
  my $fh    = $self->fh();
  seek($fh, 0, 0);

  my ($field, $cmp, $value) = split(/\s/, $query);
  $field   =~ s/^field//;
  $value   =~ s/^[\"\'](.*?)[\"\']$/$1/;
  $value   =~ s/%/.*?/g;
  $cmp     = lc($cmp);
  my $ref  = [];

  while(my $line = <$fh>) {
    chomp $line;
    my @parts = split("\t", $line);

    my $flag = 0;
    if($cmp eq "=") {
      $flag = 1 if($parts[$field] eq $value);

    } elsif($cmp eq "lceq") {
      $flag = 1 if(lc($parts[$field]) eq lc($value));

    } elsif($cmp eq "like") {
      $flag = 1 if($parts[$field] =~ /^$value$/i);
    }

    if($flag) {
      push @{$ref}, \@parts;
      last if($self->config->{'unique'});
    }
  }
  return $ref;
}

sub DESTROY {
  my $self = shift;
  close($self->{'fh'}) if($self->{'fh'});
}

1;
