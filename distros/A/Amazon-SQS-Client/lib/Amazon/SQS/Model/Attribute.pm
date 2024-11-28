################################################################################ 
#  Copyright 2008 Amazon Technologies, Inc.
#  Licensed under the Apache License, Version 2.0 (the "License"); 
#  
#  You may not use this file except in compliance with the License. 
#  You may obtain a copy of the License at: http://aws.amazon.com/apache2.0
#  This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
#  CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#  specific language governing permissions and limitations under the License.
################################################################################ 
#    __  _    _  ___ 
#   (  )( \/\/ )/ __)
#   /__\ \    / \__ \
#  (_)(_) \/\/  (___/
# 
#  Amazon SQS Perl Library
#  API Version: 2009-02-01
#  Generated: Thu Apr 09 01:13:11 PDT 2009 
# 

package Amazon::SQS::Model::Attribute;

use base qw (Amazon::SQS::Model);

=pod

=head1 NAME

 Amazon::SQS::Model::Attribute

=head1 SYNOPSIS

 my $attribute = new Amazon::SQS::Model::Attribute( 
                                                   { 
                                                    Name  => 'VisibilityTimeout', 
                                                    Value => '60'
                                                   }
                                                  );

=head1 DESCRIPTION

Create an attribute object for use with various SQS API requests.

=head1 METHODS

=head2 new

 new( options )

C<options> is a hash reference that contains the attribute name and value.

=over 5

=item Name

=item Value

=back

=cut

sub new {
  my ($class, $data) = @_;
  my $self = {};
  $self->{_fields} = {
            
		      Name => { FieldValue => undef, FieldType => "string"},
		      Value => { FieldValue => undef, FieldType => "string"},
		     };

  bless ($self, $class);
  if (defined $data) {
    $self->_fromHashRef($data); 
  }
        
  return $self;
}

    
sub getName {
  return shift->{_fields}->{Name}->{FieldValue};
}


sub setName {
  my ($self, $value) = @_;

  $self->{_fields}->{Name}->{FieldValue} = $value;
  return $self;
}


sub withName {
  my ($self, $value) = @_;
  $self->setName($value);
  return $self;
}


sub isSetName {
  return defined (shift->{_fields}->{Name}->{FieldValue});
}


sub getValue {
  return shift->{_fields}->{Value}->{FieldValue};
}


sub setValue {
  my ($self, $value) = @_;

  $self->{_fields}->{Value}->{FieldValue} = $value;
  return $self;
}


sub withValue {
  my ($self, $value) = @_;
  $self->setValue($value);
  return $self;
}


sub isSetValue {
  return defined (shift->{_fields}->{Value}->{FieldValue});
}


=pod

=head1 SEE OTHER

C<Amazon::SQS::Client>

=head1 AUTHOR

Elena@AWS

=cut


1;
