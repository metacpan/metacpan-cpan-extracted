use Mojo::Base -strict;

use Test::More;
use DBIx::Mojo::Template;
#~ use Mojo::Util qw(dumper);
binmode STDERR, ":utf8";

my $t = DBIx::Mojo::Template->new(__PACKAGE__, vars=>{'фу'=>'фу1', 'бар'=>'бар1'}, mt=>{tag_start=>'{%', tag_end=>'%}',});

my $test1 = sub {
  like $t->{'фу/бар.1'}, qr/\$фу/, 'string non render';
  like $t->{'фу/бар.1'}->render, qr/фу1.бар1/, 'render global vars';
  like $t->{'фу/бар.1'}->render('бар'=>'бар2'), qr/фу1.бар2/, 'render merge vars';
  is $t->{'фу/бар.1'}->param->{'кэш'}, 'есть', 'param';
  is $t->{'фу.бар.2'}->render('бла'=>'бла2'), "фу.бар.2\n", 'expr+comment';
  is $t->render('фу.бар.2', 'бла'=>'бла2'), "фу.бар.2\n", 'render dict key';
  like $t->{'части'}->render, qr/вставка1/, 'render include1';
  like $t->{'части'}->render, qr/вставка2/, 'render include2';
};

$test1->();

use lib 't';
require Dict1;
my $ts1 = DBIx::Mojo::Template->singleton('Dict1');

my $test2 = sub {is scalar keys %{ shift() }, shift, 'singleton';};

$test2->($ts1, 3);

require Dict2;
my $ts2 = DBIx::Mojo::Template->singleton('Dict2');

$test2->($ts1, 4);
$test2->($ts2, 4);

$test1->();
$test2->($ts1, 4);
$ts1 = undef;
$test2->($ts2, 4);


done_testing();

__DATA__
@@ фу/бар.1?кэш=есть

select *, 1 as "колонка"
from {%= $фу %}.{%= $бар %}
;

@@ фу.бар.2
%# 123
% my ($hash) = @_;
фу.бар.2

@@ часть1
вставка1

@@ часть2
вставка2

@@ части
{%= $dict->render("часть1") %}.{%= $dict->render("часть2") %}