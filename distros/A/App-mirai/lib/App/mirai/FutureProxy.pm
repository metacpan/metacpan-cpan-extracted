package App::mirai::FutureProxy;
$App::mirai::FutureProxy::VERSION = '0.003';
use strict;
use warnings;

my %ID;

sub new { my $class = shift; bless { @_ }, $class }
sub _create { $ID{$_[1]->id} = $_[1] }
sub _lookup { $ID{$_[1]} }
sub _delete { delete $ID{$_[1]} }

sub id { shift->{id} }
sub class { shift->{class} }
sub deps { shift->{deps} }
sub subs { shift->{subs} }
sub status { shift->{status} }
sub elapsed { shift->{elapsed} }
sub ready_at { shift->{ready_at} }
sub ready_stack { shift->{ready_stack} }
sub label { shift->{label} }
sub type { shift->{type} }
sub created_at { shift->{created_at} }
sub creator_stack { shift->{creator_stack} }

1;

