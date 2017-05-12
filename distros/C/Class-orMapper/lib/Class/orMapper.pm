package Class::orMapper;
use strict;
use warnings;
use DBI;

our $VERSION = '0.06';

=head1 NAME

orMapper - DBI base easy O/R Mapper.

=head1 SYNOPSIS

 use Class::orMapper;
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
 my $db = new Class::orMapper($read_database, $write_database);
 my $data = $db->select_arrayref({
 	table => 'xxxx',
 	columns => [qw/aaa bbb ccc/],
 	where => [
 		{aaa => {'=' => 'dddd'}},
 	],
 	order => {'bbb' => 'desc'},
 });
 use Data::Dumper;
 warn Dumper($data);

=head1 DESCRIPTION

This Module is easy database operation module.

=head1 Usage

 my $data = $db->select_n_arrayref($sql,$value); # $data is Array Reference.
 my $data = $db->select_n_hashref($sql,$value);  # $data is Hash Reference.

 $sql  : SQL(Strings)
 $value: Bind variable with Array Reference.
 ex.) my $sql = "select * from test where hoge=?";
      my $value = [qw/abc/];

 my $data = $db->select_arrayref($param);
 my $data = $db->select_hashref($param);

 parameter format:
 $param = {
    table => 'table_name',
    columns => [aaa,bbb,ccc],
    where => [
        {xxx => {'=' => 'value1', '>' => 'value2'}},
        {xxx => [qw/abc def cfg/],
    ],
    order => {'yyy' => 'desc', 'zzz' => 'asc'},
 };

 $db->insert($param);
 
 parameter format:
 $param = {
    table => 'table_name',
    columns => {
        aaa => 'bbb',
        ccc => 'ddd',
        eee => 'fff',
    },
 };

 $db->update($param);

 parameter format:
 $param = {
    table => 'table_name',
    columns => {
        aaa => 'bbb',
        ccc => 'ddd',
        eee => 'fff',
    },
    where => [
        {xxx => {'=' => 'value1', '>' => 'value2'}},
        {xxx => [qw/abc def cfg/],
    ],
 };	

 $db->delete($param);

 parameter format:
 $param = {
    table => 'table_name',
    where => [
        {xxx => {'=' => 'value1', '>' => 'value2'}},
        {xxx => [qw/abc def cfg/],
    ],
 };

 $db->truncate($param);

 parameter format:
 $param = {
    table => 'table_name',
 };

=head1 Copyright

Kazunori Minoda (c)2012

=cut

sub new{
	my ($this,$db_r,$db_w) = @_;
	my $dbh_r = DBI->connect($db_r->{dsn},$db_r->{uid},$db_r->{pwd},$db_r->{opt})
		||die $DBI::errstr;
	my $dbh_w = DBI->connect($db_w->{dsn},$db_w->{uid},$db_w->{pwd},$db_w->{opt})
		||die $DBI::errstr;
	my $self = {
		dbh_r => $dbh_r,
		dbh_w => $dbh_w,
	};
	return bless($self,$this);
}

sub DESTROY{
	my $self = shift;
	$self->{dbh_r}->disconnect if($self->{dbh_r});
	$self->{dbh_w}->disconnect if($self->{dbh_w});
}

# select
sub select_n_arrayref{
	my ($self,$s,$v) = @_;
	my $sth = $self->{dbh_r}->prepare($s);
	$sth->execute(@{$v});
	my @o;
	while(my $r = $sth->fetchrow_arrayref){
		my @tmp = map{$_?$_:''} @{$r};
		push(@o, \@tmp);
	}
	$sth->finish;
	return \@o;
}

sub select_n_hashref{
	my ($self,$s,$v) = @_;
	my $sth = $self->{dbh_r}->prepare($s);
	$sth->execute(@{$v});
	my @o;
	while(my $r = $sth->fetchrow_hashref){
		push(@o, $r);
	}
	$sth->finish;
	return \@o;
}

sub select_arrayref{
	my ($self,$p) = @_;
	my ($s,@v) = $self->select_base($p);
	my $sth = $self->{dbh_r}->prepare($s);
	$sth->execute(@v);
	my @o;
	while(my $r = $sth->fetchrow_arrayref){
		my @tmp = map{$_?$_:''} @{$r};
		push(@o, \@tmp);
	}
	$sth->finish;
	return \@o;
}

sub select_hashref{
	my ($self,$p) = @_;
	my ($s,@v) = $self->select_base($p);
	my $sth = $self->{dbh_r}->prepare($s);
	$sth->execute(@v);
	my @o;
	while(my $r = $sth->fetchrow_hashref){
		push(@o, $r);
	}
	$sth->finish;
	return \@o;
}

# insert
sub insert{
	my ($self,$p) = @_;
	my ($s,@v);
	$s = "insert into " . $p->{table} . "(" . join(",",map{push(@v,$p->{columns}->{$_});$_} keys %{$p->{columns}}) . ") values(" . join(',',map{$_ = '?';$_} values %{$p->{columns}}) . ")";
	my $sth = $self->{dbh_w}->prepare($s);
	$sth->execute(@v);
	$sth->finish;
}

# update
sub update{
	my ($self,$p) = @_;
	my ($s,@v);
	$s = "update " . $p->{table} . " set " . join(',', map{push(@v,$p->{columns}->{$_});$_ = $_ . '=?'} keys %{$p->{columns}});
	my ($w,@vv) = where($p);
	if($w){
		$w =~ s/ and //;
		$s .= ' where ' . $w;
	}
	push(@v,$_) for (@vv);
	my $sth = $self->{dbh_w}->prepare($s);
	$sth->execute(@v);
	$sth->finish;
}

# delete
sub delete{
	my ($self,$p) = @_;
	my $s = "delete from " . $p->{table};
	my ($w,@v) = where($p);
	if($w){
	$w =~ s/ and //;
	$s .= ' where ' . $w;
	}
	my $sth = $self->{dbh_w}->prepare($s);
	$sth->execute(@v);
	$sth->finish;
}

# truncate
sub truncate{
	my ($self,$p) = @_;
	my $s = "truncate table " . $p->{table};
	$self->{dbh_w}->do($s);
}

# internal use function
sub select_base{
	my ($self,$p) = @_;
	my $s = "select " . join(',',@{$p->{columns}}) . " from " . $p->{table};
	my ($w,@v) = where($p);
	if($w){
		$w =~ s/ and //;
		$s .= ' where ' . $w;
	}
	my $o;
	if($p->{order}){
		$o .= ',' . $_ . ' ' . $p->{order}->{$_} for (keys %{$p->{order}});
	}
	if($o){
		$o =~ s/^,//;
		$s .= ' order by ' . $o;
	}
	return ($s,@v);
}

sub where{
	my $p = shift;
	my ($w,@v);
	for my $ww (@{$p->{where}}){
		for my $www (keys %{$ww}){
			if(ref($ww->{$www}) eq 'ARRAY'){
				$w .= ' and ' . $www . ' in (' . join(",",map{push(@v,$_); $_ = '?'; $_ } @{$ww->{$www}}) . ')';
			}
			elsif(ref($ww->{$www}) eq 'HASH'){
				for (keys %{$ww->{$www}}){
					$w .= ' and ' . $www . $_ . '?';
					push(@v,$ww->{$www}->{$_});
				}
			}
		}
	}
	return ($w,@v);
}

1;


