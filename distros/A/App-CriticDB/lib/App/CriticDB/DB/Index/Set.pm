package App::CriticDB::DB::Index::Set;
use strict;
use warnings;

use parent 'App::CriticDB::DB::Index';

our $VERSION='0.0.3';

sub init {
	my ($self)=@_;
	%$self=(kset=>{});
	return $self;
}

sub add {
	my ($self,$ka,$kb)=@_;
	$$self{kset}{$ka}{$kb}=undef;
	return $self;
}

sub all {
	my ($self,$ka,$kb)=@_;
	my @res;
	if(defined($ka)) {
		if(!defined($kb)) { push @res,keys(%{$$self{kset}{$ka}}) }
		elsif(exists($$self{kset}{$ka}{$kb})) { push @res,[$ka,$kb] }
	}
	else {
		if(!defined($kb)) {
			while(my ($k,$va)=each %{$$self{kset}}) {
				push @res,map {[$k,$_]} keys(%$va) } }
		else { push @res,grep {exists($$self{kset}{$_}{$kb})} keys(%{$$self{kset}}) }
	}
	return @res;
}

sub remove {
	my ($self,@K)=@_;
	if(@K) {
		delete(@{$$self{kset}}{@K});
		foreach my $V (values %{$$self{kset}}) { delete(@$V{@K}) }
	}
	return $self;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB::Index::Set - Store sets associated with names

=head1 VERSION

Version 0.0.3

=head1 SYNOPSIS

  use App::CriticDB::DB::Index;
  my $idx=App::CriticDB::DB::Index->new(
    values=>'set',
  );
  $idx->add('A','one');
  $idx->add('A','two');
  $idx->add('B','two');
  ...;

=head1 DESCRIPTION

Named sets can be stored, supporting faster retrieval of associated records.  The construction is effectively a hash, ie a regular database index.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
