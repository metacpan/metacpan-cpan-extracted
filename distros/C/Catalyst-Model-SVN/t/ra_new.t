use strict;
use warnings;
use Test::More tests => 5;
# Not using Test::Exception any more as it doesn't play nicely with NEXT :(
use Catalyst::Model::SVN;
use Scalar::Util qw(blessed);

my @args;
{
    no warnings 'redefine';
    *SVN::Ra::new = sub {
        @args = @_;
    };
};

eval { 
    Catalyst::Model::SVN->new(); 
};
ok($@, 'Throws with no config');
Catalyst::Model::SVN->config(
    repository => 'http://www.test.com/svn/repos/',
);
eval {
    Catalyst::Model::SVN->new();
};
ok(!$@, 'Can construct');
ok(scalar(@args), 'Has args');
my $self = shift(@args);
my %p = @args;
ok($p{pool}->isa('SVN::Pool'), 'Have an SVN::Pool arg');
ok(!blessed($p{url}), 'url not blessed');
