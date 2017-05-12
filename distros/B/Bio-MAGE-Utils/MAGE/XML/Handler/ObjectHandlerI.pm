package Bio::MAGE::XML::Handler::ObjectHandlerI;

use strict;
use Bio::MAGE::Base;
use base qw(Bio::MAGE::Base);
our $VERSION = '0.99';

sub new {
  my $pack = shift;
  my $self = bless {}, $pack;
  $self->throw_not_implemented("new not defined for ".ref(caller()));
}

sub handle {
  my $self = shift;
  $self->throw_not_implemented("handle not defined for ".ref(caller()));
}

1;

__END__

=head1 NAME

Bio::MAGE::XML::Handler::ObjectHandlerI - Abstract class for processing
Bio::MAGE objects.

=head1 SYNOPSIS

  my $objhandler;    #get an Bio::MAGE::XML::ObjectHandlerI somehow
  my $handler;       #get an Bio::MAGE::XML::Handler somehow
  my $reader;        #get a  Bio::MAGE::XML::Reader somehow

  $handler->objecthandler($objhandler);
  $reader->handler($handler)

=head1 DESCRIPTION

=head1 METHODS

=head2 CONSTRUCTORS AND FRIENDS

=head2 METHODS

=head1 AUTHORS

 Copyright (c) 2002
 Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

=cut
