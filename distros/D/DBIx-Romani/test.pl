#/usr/bin/perl -w

use test::Romani::Query::Select;
use test::Romani::Query::SQL::TTT;
use test::Romani::Query::Comparison;
use test::Romani::Query::Function;
use test::Romani::Query::XML::Select;
use test::Romani::Query::XML::TTT;
use test::Romani::Query::XML::Where;
use test::Romani::Query::XML::Function;
use test::Romani::Query::Insert;
use test::Romani::Query::Update;
use test::Romani::Query::Delete;
use test::Romani::Driver::sqlite;

use Carp;

$SIG{__DIE__} = sub {
	Carp::confess(@_);
	#Carp::confess;
};

if ( @ARGV > 0 )
{
	my @spec;

	foreach my $s ( @ARGV )
	{
		my @t = split('::', $s);
		unshift @t, "Local";
		push @spec, join('::', @t);
	}

	Test::Class->runtests( @spec );
}
else
{
	# run 'em all!
	Test::Class->runtests;
}

