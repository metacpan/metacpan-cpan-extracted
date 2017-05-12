package CogBase::Node;
use strict;
use warnings;
use CogBase::Base -base;
use Data::UUID;
use Digest::MD5;
use Convert::Base32;

field '_connection';

field 'Id';
field 'Type';
field 'Owner';
field 'Group';
field 'Perms';
field 'Revision';
field 'Hid';
field 'Tags' => [];

sub _initialize {
    my $self = shift;
    if (my $type = $self->Type) {
        bless $self, "CogBase::$type";
    }
    my $id = $self->Id;
    if ($id and $id =~ s/-0*(\d+)$//) {
        $self->Id($id);
        $self->Revision($1);
    }
}

sub _fields {
    my $self = shift;
    return grep !/^[A-Z_]/, keys %$self;
}

1;
