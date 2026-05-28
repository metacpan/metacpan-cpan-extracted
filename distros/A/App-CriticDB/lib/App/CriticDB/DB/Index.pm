package App::CriticDB::DB::Index;
use strict;
use warnings;

use Carp qw/confess/;

our $VERSION='0.0.4';

my %vtypes=(
	id =>'App::CriticDB::DB::Index::Id',
	set=>'App::CriticDB::DB::Index::Set',
);

sub new {
	my ($ref,%opt)=@_;
	$opt{values}//='id';
	my $type=$vtypes{$opt{values}};
	if(!$type) { confess("Invalid index type requested:  $opt{values}") }
	return bless({%opt},$type)->init();
}

sub import {
	foreach my $pkg (values %vtypes) { eval "require $pkg;" }
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB::Index - Permit storage of raw-or-indexed values

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

  use App::CriticDB::DB::Index;
  my $idx=App::CriticDB::DB::Index->new(
    values=>'id/set',
    ...
  );
  $idx->operation(pathspec, ...);

=head1 DESCRIPTION

A variety of indexing operations are supported for literal strings or associative lists.  See the subclasses for more details.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
