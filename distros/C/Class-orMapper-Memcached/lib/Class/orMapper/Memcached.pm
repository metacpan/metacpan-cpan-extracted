package Class::orMapper::Memcached;
use strict;
use warnings;
use String::CRC32;
use Cache::Memcached::Fast;
#use Data::Dumper;
use base qw/Class::orMapper/;

our $VERSION = '0.03';

=head1 NAME

 Class::orMapper::Memcached - DBI base easy O/R Mapper with Memcached.

=head1 SYNOPSIS

 use Class::orMapper::Memcached;
 my $read_database = {
    dsn => 'dbi:xxxx:dbname=xxxx;host=localhost;port=xxxx',
    uid => 'xxxx',
    pwd => 'xxxx',
    opt => {AutoCommit => 0},
 };
 my $write_database = {
    dsn => 'dbi:xxxx:dbname=xxxx;host=localhost;port=xxxx',
    uid => 'xxxx',
    pwd => 'xxxx',
    opt => {AutoCommit => 0},
 };
 my $memcached = {
 	servers => [qw/localhost:11211/],
 };
 my $db = new Class::orMapper::Memcached($read_database, $write_database, $memcached);

=head1 DESCRIPTION

This Module is easy database operation module with memcached.

=head1 Usage

 my $data = $db->select_n_arrayref_c($sql,$value);
 my $data = $db->select_n_hashref_c($sql,$value);

 ex.) my $sql = "select * from test where hoge=?";
      my $value = [qw/abc/];

 my $data = $db->select_arrayref_c($param);
 my $data = $db->select_hashref_c($param);
 
 ex.)
 $param = {
    table => 'table_name',
    columns => [aaa,bbb,ccc],
    where => [
        {xxx => {'=' => 'value1', '>' => 'value2'}},
        {xxx => [qw/abc def cfg/],
    ],
    order => {'yyy' => 'desc', 'zzz' => 'asc'},
 };

=head1 Copyright

Kazunori Minoda (c)2012

=cut

sub new{
	my ($this,$r,$w,$m) = @_;
	my $self = new Class::orMapper($r,$w);
	$self->{mem} = new Cache::Memcached::Fast($m);
	$self->{expiration_time} = 7*24*60*60; # 1week
	return bless($self,$this);
}

sub select_n_arrayref_c{
	my ($self,$s,$v) = @_;
	my $key = crc32($s.join("",@{$v}.'na'));
	my $q = $self->{mem}->get($key);
	if(!$q){
		$q = $self->select_n_arrayref($s,$v);
		$self->{mem}->set($key,$q,$self->{expiration_time});
	}
	return $q;
}

sub select_n_hashref_c{
	my ($self,$s,$v) = @_;
	my $key = crc32($s.join("",@{$v}.'nh'));
	my $q = $self->{mem}->get($key);
	if(!$q){
		$q = $self->select_n_hashref($s,$v);
		$self->{mem}->set($key,$q,$self->{expiration_time});
	}
	return $q;
}

sub select_arrayref_c{
	my ($self,$p) = @_;
	my $key = crc32(Dumper($p).'a');
	my $q = $self->{mem}->get($key);
	if(!$q){
		$q = $self->select_arrayref($p);
		$self->{mem}->set($key,$q,$self->{expiration_time});
	}
	return $q;
}

sub select_hashref_c{
	my ($self,$p) = @_;
	my $key = crc32(Dumper($p).'h');
	my $q = $self->{mem}->get($key);
	if(!$q){
		$q = $self->select_hashref($p);
		$self->{mem}->set($key,$q,$self->{expiration_time});
	}
	return $q;
}

1;

