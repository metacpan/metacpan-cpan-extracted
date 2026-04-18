package TAP::Harness::Metrics;
use parent qw/TAP::Harness/;

use strict;
use warnings;

our $VERSION='0.0.4';

use Carp qw/confess/;
use Fcntl qw/:flock/;

my %options=(
	prefix    =>'PREFIX',
	sep       =>'.',
	subdepth  =>1,
	label     =>0,
	allowed   =>'-._/A-Za-z0-9',
	rollup    =>0,
	bubble    =>1,
	#
	type   =>'file',
	append =>1,
	outfile=>'/tmp/metrics-tests.txt',
	# format =>'tsv',
	#
	module=>undef,
	f     =>'save',
);
my @configurable=(qw/prefix sep subdepth label allowed rollup/); # not fully "enforced"

sub verifyCallback {
	my ($module,$f)=@_;
	if(!$module) { confess("'module' must be provided") }
	if(!$f)      { confess("'f' must be non-empty") }
	eval "require $module;";
	if($@) { confess($@) }
	my $cb=$module->can($f);
	if(!$cb) { confess("${module}::${f} not available") }
	return $cb;
}

sub new {
	my ($ref,@opt)=@_;
	my $class=ref($ref)||$ref;
	my $self=$class->SUPER::new(@opt);
	while(my ($k,$v)=each(%options)) { $$self{$k}=$v }
	if($$self{type} eq 'module') {
		$$self{modulef}=verifyCallback($$self{module},$$self{f});
		if(my $cfg=$$self{module}->can('configureHarness')) {
			my %config=&$cfg();
			foreach my $k (grep {exists($config{$_})} @configurable) { $options{$k}=$$self{$k}=$config{$k} }
		}
	}
	$$self{parser_class}='TAP::Parser::Metrics';
	return $self;
}

sub make_parser {
	my ($self,@args)=@_;
	my ($parser,$session)=$self->SUPER::make_parser(@args);
	$parser->configure(callback=>sub { $self->save(@_) });
	return ($parser,$session);
}

sub import {
	my ($class,$type,@opt)=@_;
	$type//='file';
	if($type eq 'module') { unshift(@opt,'module') }
	%options=(%options,@opt,type=>$type);
	return 1;
}

sub name {
	my ($self,%event)=@_;
	my @path=@{$event{path}};
	if(defined($$self{subdepth})&&($$self{subdepth}>=0)) { splice(@path,$$self{subdepth}) }
	my @name=map {s/[^$$self{allowed}]//sgr} (($$self{prefix}?$$self{prefix}:()),$event{file},@path,($$self{label}&&defined($event{label})?$event{label}:()));
	return join($$self{sep},@name);
}

sub bubbled {
	my ($self,%event)=@_;
	if(!@{$event{path}}) { return }
	$event{label}=pop(@{$event{path}});
	return $self->name(%event);
}

sub collateRollup {
	my ($self,@metrics)=@_;
	my (%res,%count);
	foreach my $event (@metrics) {
		if(defined($$event{label})) {
			foreach my $name ($self->name(%$event), ($$self{label}?$self->bubbled(%$event):())) {
				$count{$name}++; $res{$name}+=$$event{pass} } }
		else {
			local($$self{label})=0;
			foreach my $name ($self->bubbled(%$event)) {
				$count{$name}++; $res{$name}+=$$event{pass} } }
	}
	foreach my $k (keys %res) { $res{$k}/=$count{$k} }
	return %res;
}

sub collate {
	my ($self,@metrics)=@_;
	my (%res,%count);
	if($$self{rollup}) { return $self->collateRollup(@metrics) }
	foreach my $event (@metrics) {
	foreach my $name ($self->name(%$event), ($$self{bubble}?$self->bubbled(%$event):())) {
		$count{$name}++; $res{$name}//=1; $res{$name}&&=$$event{pass} } }
	return %res;
}

sub save {
	my ($self,@metrics)=@_;
	my %metrics=$self->collate(@metrics);
	if($$self{type} eq 'file')   { $self->saveFile(%metrics) }
	if($$self{type} eq 'module') { &{$$self{modulef}}(%metrics) }
	if($$self{type} eq 'stderr') { $self->printMetrics(%metrics) }
	return;
}

sub printMetrics {
	my ($self,%metrics)=@_;
	if(!%metrics) { return }
	while(my ($name,$pass)=each %metrics) { print STDERR join("\t",'METRIC:',$pass,$name),"\n" }
	return;
}

sub saveFile {
	my ($self,%metrics)=@_;
	if(!%metrics) { return }
	my $append=($$self{append}?'>>':'>');
	open(my $fh,$append,$$self{outfile}) or return;
	my $countdown=5;
	while(!flock($fh,LOCK_EX)) {
		if($countdown--) { sleep(2) }
		else { return }
	}
	while(my ($name,$pass)=each %metrics) { print $fh join("\t",$pass,$name),"\n" }
	flock($fh,LOCK_UN);
	return;
}

1;

__END__
