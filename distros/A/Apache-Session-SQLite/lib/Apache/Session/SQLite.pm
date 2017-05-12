package Apache::Session::SQLite;

use strict;
use vars qw($VERSION);
use base 'Apache::Session';

$VERSION='0.21';

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Store::MySQL;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Base64;

sub populate {
    my $self = shift;
    
    $self->{object_store} = Apache::Session::Store::MySQL->new($self);
    $self->{lock_manager} = Apache::Session::Lock::Null->new($self);
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::Base64::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::Base64::unserialize;
    
    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::SQLite - use DBD::SQLite for Apache::Session storage

=head1 SYNOPSIS

  use Apache::Session::SQLite;

  tie %hash, 'Apache::Session::SQLite', $id, {
      DataSource => 'dbi:SQLite:dbname=/tmp/hoge.db'};

=head1 DESCRIPTION

This module is equal to the following.

  tie %hash,'Apache::Session::Flex',$id,{
      Store => 'MySQL',
      Lock  => 'Null',
      Generate => 'MD5',
      Serialize => 'Base64',
      DataSource => 'dbi:SQLite:dbname=/tmp/hoge.db'};

=head1 AUTHOR

Kobayashi Hiroyuki <kobayasi@piano.gs>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Flex>, L<DBD::SQLite>


