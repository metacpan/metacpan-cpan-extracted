#!/usr/bin/perl -w
$|=1;
use strict;
#use lib  qw( ../lib );
use vars qw($DEBUG);
use Data::Dumper;
use Test::More tests => 18;
use SQL::Statement;
use SQL::Parser;
printf "SQL::Statement v.%s\n", $SQL::Statement::VERSION;
my($stmt,$cache)=(undef,{});
my $p = SQL::Parser->new();
$p->{RaiseError}=1;
$p->{PrintError}=0;

$DEBUG=0;
if ($DEBUG) {
  parse('SELECT * FROM x WHERE y newopfunc z');
  parse('CREATE FUNCTION newopfunc');
  parse('SELECT * FROM x WHERE y newopfunc z');
    my $s = SQL::Statement->new('CREATE OPERATOR foo',$p);
    $s = SQL::Statement->new('SELECT * FROM x WHERE y foo z',$p);
    exit;
}

# fail on unknown TYPE, create the type, succeed
#
#diag('TYPE');
ok(!parse('CREATE TABLE x (id NEWTYPE)'),'unknwon type');
ok(parse('CREATE TYPE newtype'),'create type');
ok(parse('CREATE TABLE x (id NEWTYPE)'),'user-defined type');

# succeed on known TYPE, drop the type, fail
#
ok(parse('CREATE TABLE x (id INT)'),'known type');
ok(parse('DROP TYPE int'),'drop type');
ok(!parse('CREATE TABLE x (id INT)'),'unknown type');
parse('CREATE TYPE INT'); # put it back :-)

#diag('KEYWORD');
# succeed on unknown KEYWORD, create the keyword, fail
#
ok(parse('SELECT * FROM newkeyword'),'unknown keyword');
ok(parse('CREATE KEYWORD newkeyword'),'create keyword');
ok(!parse('SELECT * FROM newkeyword'),'user-defined keyword');

# fail on known KEYWORD, drop the keyword, succeed
#
ok(!parse('SELECT * FROM table'),'known keyword');
ok(parse('DROP KEYWORD table'),'drop keyword');
ok(parse('SELECT * FROM table'),'keyword as identifier');

#diag('OPERATOR');
# fail on unknown OP, create the op, succeed
#
ok(!parse('SELECT * FROM x WHERE y newop z'),'unknown operator');
ok(parse('CREATE OPERATOR newop'),'create operator');
ok(parse('SELECT * FROM x WHERE y newop z'),'user-defined operator');

#do_('CREATE TABLE x (id INT)');
#do_("INSERT INTO x VALUES($_)") for 0..7;
##ok( '0^1^2^' eq  fetchStr("SELECT * FROM x WHERE id < 3"), ';
#ok( '0^1^2^' eq  fetchStr("SELECT * FROM x WHERE id newop 3"), 'exec operator');

# succeed on known OP, drop the op, fail
#
ok(parse('SELECT * FROM x WHERE y LIKE z'),'known operator');
ok(parse("DROP OPERATOR 'LIKE'"),'drop operator');
ok(!parse('SELECT * FROM x WHERE y LIKE z'),'unkown operator');
parse('CREATE OPERATOR LIKE'); # put it back :-)

sub parse {
    my($sql)=@_;
    eval { $stmt = SQL::Statement->new($sql,$p) };
    warn $@ if $@ and $DEBUG;
    return ($@) ? 0 : 1;
}
sub do_ {
    my($sql,@params)=@_;
    @params = () unless @params;
    $stmt = SQL::Statement->new($sql,$p);
    eval { $stmt->execute($cache,@params) };
    return ($@) ? 0 : 1;
}
sub fetchStr {
    my($sql,@params)=@_;
    do_($sql,@params);
    my $str='';
    while (my $r=$stmt->fetch) {
        $str .= sprintf "%s^",join'~',@$r;
    }
    return $str;
}
sub newop {
    my ( $self, $owner, $left, $right ) = @_;
    return $left < $right;
}
__END__
"a disjunction of conjunctions of literals, where each literal is an elementary relational formula or its negation"

