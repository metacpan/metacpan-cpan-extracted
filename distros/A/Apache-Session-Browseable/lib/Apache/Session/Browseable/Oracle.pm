package Apache::Session::Browseable::Oracle;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::Oracle;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::DBI;

our $VERSION = '1.2.2';
our @ISA     = qw(Apache::Session::Browseable::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Apache::Session::Browseable::Store::Oracle $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSONserialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSONunserialize;

    return $self;
}

1;

