#!perl -T

use Test::More tests => 1;
use Perl::Critic;
use Data::Validate::WithYAML::Plugin::NoSpam;

my $pc = Perl::Critic->new( -theme => 'core', -severity => 5 );
my @violations = $pc->critique($INC{'Data/Validate/WithYAML/Plugin/NoSpam.pm'});
is_deeply(\@violations,[],'Perl::Critic');
