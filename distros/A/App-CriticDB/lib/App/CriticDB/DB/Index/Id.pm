package App::CriticDB::DB::Index::Id;
use strict;
use warnings;

use parent 'App::CriticDB::DB::Index';

our $VERSION='0.0.3';

sub init {
	my ($self)=@_;
	%$self=(prefix=>$$self{prefix}//'',kv=>{''=>0},vk=>['']);
	return $self;
}

sub upsert {
	my ($self,$key,$idx)=@_;
	if(defined($key)) {
		if(defined($$self{kv}{$key})) { return $$self{kv}{$key} }
		$key="$key";
		$idx=$$self{prefix}.(1+$#{$$self{vk}});
		push @{$$self{vk}},$key;
		$$self{kv}{$key}=$idx;
		return $idx;
	}
	elsif(defined($idx)) { return $$self{vk}[$idx] }
	else { return }
}

sub value {
	my ($self,$value)=@_;
	if($value=~/^\Q$$self{prefix}\E(?<idx>\d+)/) { return $$self{vk}[$+{idx}] }
	return $value;
}

sub remove {
	my ($self,@K)=@_;
	if(!@K) { return $self }
	foreach my $k (grep {defined($$self{kv}{$_})} @K) {
		my $idx=$$self{kv}{$k};
		if($idx=~/^\Q$$self{prefix}\E(?<idx>\d+)/) { $$self{vk}[$+{idx}]=undef }
		delete($$self{kv}{$k});
	}
	return $self;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB::Index::Id - Store redundant strings as prefixed IDs

=head1 VERSION

Version 0.0.3

=head1 SYNOPSIS

  use App::CriticDB::DB::Index;
  my $idx=App::CriticDB::DB::Index->new(
    values=>'id',
    prefix=>'p:',
  );
  my $one=$idx->upsert('one');
  my $two=$idx->upsert('two');
  print $idx->value($two);

=head1 DESCRIPTION

Literal strings are given auto-increasing numeric IDs and stored with a prefix.  Value lookup returns the original value for C<prefix:id> strings, or the literal value as fallback.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
