package App::CriticDB::DB;
use strict;
use warnings;

use Carp qw/confess/;
use Perl::Critic::Violation;

use App::CriticDB::DB::Index;

our $VERSION='0.0.5';

my %engines=(
	storable=>'App::CriticDB::DB::Stor',
);

sub new {
	my (undef,%opt)=@_;
	$opt{mode}//='not provided';
	my ($class,%self);
	if($opt{mode} eq 'file') {
		if(!$opt{file}) { confess('File storage requires filename') }
		$opt{type}//='storable';
		%self=map {$_=>$opt{$_}} qw/mode file type/;
		$class=$engines{$opt{type}}//$engines{storable};
		eval "require $class";
	}
	else { confess("Storage type not available:  $opt{mode}") }
	my $self=bless(\%self,$class);
	$self->read();
	return $self;
}

sub _initStore {
	my ($self)=@_;
	return (
		version=>1001,
		index=>{
			policy=>App::CriticDB::DB::Index->new(values=>'id',prefix=>'p:'),
			'policy-file'=>App::CriticDB::DB::Index->new(values=>'set'),
		},
		file=>{},
	);
}

sub _init {
	my ($self)=@_;
	%{$$self{store}}=$self->_initStore();
	return $self->write();
}

sub _filemtime {
	my ($fn)=@_;
	if(!-e $fn) { return }
	return (stat($fn))[9];
}

sub _fileNewer {
	my ($self,$fn,$ts)=@_;
	if(!$ts) { return }
	my $tm=_filemtime($fn);
	if(!$tm) { return }
	return ($tm>$ts);
}

sub _violation {
	my ($self,$fn,$V)=@_;
	my %res;
	my %remap=(
		'_description'  =>'desc',
		'_explanation'  =>'expl',
		'_policy'       =>'policy',
		'_severity'     =>'sev',
		'_source'       =>'code',
	);
	if('Perl::Critic::Violation' eq ref($V)) {
		%res=(
			(map {$remap{$_}=>$$V{$_}} keys(%remap)),
			line  =>$V->line_number(),
			col   =>$V->column_number(),
		)
	}
	elsif('HASH' eq ref($V)) { %res=%$V }
	else { confess('Invalid type of violation') }
	$res{file}=$fn; # added for IndexSet construction
	foreach my $ka (keys %res) {
		if(defined($$self{store}{index}{$ka})) { $res{$ka}=$$self{store}{index}{$ka}->upsert($res{$ka}) }
		foreach my $kb (grep {$_ ne $ka} keys %res) {
			if($$self{store}{index}{"$ka-$kb"}) { $$self{store}{index}{"$ka-$kb"}->add(@res{$ka,$kb}) }
		}
	}
	delete($res{file}); # not needed in the stored violation
	return %res;
}

sub store {
	my ($self,%opt)=@_;
	if(!$opt{file}) { return $self }
	my @violations=map {+{$self->_violation($opt{file},$_)}} @{$opt{violations}//[]};
	$$self{store}{file}{$opt{file}}{violations}=\@violations;
	$$self{store}{file}{$opt{file}}{mtime}=_filemtime($opt{file})//$opt{mtime}//time();
	return $self;
}

sub flush {
	my ($self,$fn)=@_;
	return $self->write(fn=>$fn);
}

sub newer {
	my ($self,$fn)=@_;
	if(!$$self{store}{file}{$fn}) { return 1 }
	return $self->_fileNewer($fn,$$self{store}{file}{$fn}{mtime}//0);
}

sub cleanup {
	my ($self)=@_;
	if(my @remove=grep {!-e $_} keys %{$$self{store}{file}}) {
		foreach my $idx (values %{$$self{store}{index}}) { $idx->remove(@remove) }
		delete(@{$$self{store}{file}}{@remove});
	}
	return $self;
}

sub read  { confess('Unimplemented abstract') }
sub write { confess('Unimplemented abstract') }

my @reportIterator;
sub report {
	my ($self)=@_;
	if(!@reportIterator) {
		@reportIterator=map {[$_]} sort keys %{$$self{store}{file}};
		push @reportIterator,[]; # terminate the iterator
	}
	while(@reportIterator) {
		my ($fn,$violation)=@{shift(@reportIterator)};
		if($violation) { return $violation }
		if(!$fn)       { return }
		my @violations;
		foreach my $V (@{$$self{store}{file}{$fn}{violations}}) {
			my $violation=Perl::Critic::Violation->new(@$V{qw/desc expl/},bless({},'PPI::Statement'),$$V{sev});
			$$violation{_filename}=$fn;
			$$violation{_source}=$$V{code};
			$$violation{_policy}=$$self{store}{index}{policy}->value($$V{policy});
			@{$$violation{_location}}[2..4]=(@$V{qw/col line/},$fn);
			push @violations,[$fn,$violation];
		}
		unshift(@reportIterator,@violations);
	}
	return;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB - Datastores for Perl::Critic violations

=head1 VERSION

Version 0.0.5

=head1 SYNOPSIS

  use App::CriticDB::DB;
  my $db=App::CriticDB::DB->new(
    mode=>'file',
    file=>'path',
    type=>'storable',
  );
  if($db->newer($filename)) {
    my @violations=...;
    $db->store(file=>$filename,violations=>\@violations);
    $db->flush();
  }

=head1 DESCRIPTION

The datastore manager for per-file Perl::Critic violation data, supporting creation, upgrade, and management of the data storage subclasses.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
