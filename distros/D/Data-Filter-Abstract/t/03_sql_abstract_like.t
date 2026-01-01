use Test::Simple;
use Test::More;
use Data::Filter::Abstract::Util qw/:all/;
use Data::Filter::Abstract;
use SQL::Abstract;
use Data::Dumper;
use B;
use Scalar::Util qw(looks_like_number);

sub dumper { Data::Dumper->new([@_])->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

sub where {
    my ($where, @bind) = SQL::Abstract->new->where(shift);
    while ($where =~ /\?/) {
	my $v = shift @bind;
	$v = looks_like_number($v) ? $v : B::perlstring($v);
	$where =~ s/\?/$v/e
    }
    $where =~ s/\"/'/g;
    $where =~ s/^\s+WHERE //r;
}

my @wheres = (
	      { priority => [ -or => {'!=', 2}, {'!=', 1} ] },
	      { priority => [ -and => {'!=', 2}, {'!=', 1} ] },
	      { user => 'nwiger', status => ['assigned', 'in-progress', 'pending'] },
	      { user => 'nwiger', status => { "!=" => undef } }, # this fails
	      { user => 'nwiger', status => undef },
	      { user => 'nwiger', status => { 'ne', 'completed' } },
	      { status => { '==', [ 'assigned', 'in-progress', 'pending'] } },
	      { user => 'nwiger', status => { 'ne' => 'completed', "eq" => 'pending' } },
	      { user => 'nwiger', priority => [ { '==', 2 }, { '>', 5 } ] },
	      { priority => [ -and => {'!=', 2}, {'!=', 1} ] },
	      { status => {'eq', 'completed', 'ne', 'pending%' } },
	      { status => [ -and => {'eq', 'completed'}, {'eq', 'pending%'}] },
	      { status => {'eq', ['assigned', 'in-progress']} },
	      { status => [ -or => {'eq', 'assigned'}, {'eq', 'in-progress'}] },
	      { status => [ {'eq', 'assigned'}, {'eq', 'in-progress'} ] }
	     );

for (@wheres) {
    isa_ok(Data::Filter::Abstract->new($_), "Data::Filter::Abstract", dumper $_);
    # print dumper $_;
    # print simple_sub($_);
    # print where($_);
    # print ""
}

done_testing()
