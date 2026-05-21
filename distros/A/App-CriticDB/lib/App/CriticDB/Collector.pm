package App::CriticDB::Collector;
use strict;
use warnings;

use Carp qw/confess/;
use Perl::Critic;
use Perl::Critic::Utils;

our $VERSION='0.0.3';

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self=map {$_=>$opt{$_}} qw/store flush newer profile debug/;
	$self{profile}//='';
	$self{debug}//={};
	foreach my $k (grep {'CODE' ne ref($self{$_})} qw/store flush newer/) { delete($self{$k}) }
	return bless(\%self,$class);
}

sub store {
	my ($self,$fn,@violations)=@_;
	if(!$$self{store}) { return $self }
	&{$$self{store}}(file=>$fn,violations=>\@violations);
}

sub flush {
	my ($self,$fn)=@_;
	if(!$$self{flush}) { return $self }
	&{$$self{flush}}($fn);
}

sub newer {
	my ($self,$fn)=@_;
	if(!$$self{newer}) { return 1 }
	&{$$self{newer}}($fn);
}

sub _critique {
	my ($self,$fn)=@_;
	my @violations;
	if($$self{debug}{critique}) { print STDERR "Critique $fn\n" }
	eval { @violations=$$self{critic}->critique($fn) };
	if($@) { return {error=>$@} }
	foreach my $v (grep {'ARRAY' eq ref($$_{_explanation})} @violations) { $$v{_explanation}=[@{$$v{_explanation}}] } # unbless ReadOnly objects
	return @violations;
}

sub collect {
	my ($self,@paths)=@_;
	$$self{critic}//=Perl::Critic->new(-profile=>$$self{profile},-severity=>1,-top=>1e6,-verbose=>1);
	my (@valid,@gone);
	foreach my $path (@paths) {
		if(-e $path) { push @valid,$path }
		else         { push @gone,$path }
	}
	if(@gone) { confess("Unable to handle missing paths:  @gone") }
	foreach my $fn (sort {int(rand(3))-1} grep {$self->newer($_)} Perl::Critic::Utils::all_perl_files(@valid)) {
		my @violations=$self->_critique($fn);
		$self->store($fn,@violations);
		$self->flush($fn);
	}
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::Collector - Collect Perl::Critic violations for files

=head1 VERSION

Version 0.0.3

=head1 SYNOPSIS

  use App::CriticDB::Collector;
  my $collector=App::CriticDB::Collector->new(
    profile=>'path',
    store  =>sub { callback },
    flush  =>sub { callback },
    newer  =>sub { callback },
  );
  $collector->collect(@paths);

=head1 DESCRIPTION

The Collector builds a C<Perl::Critic> instance to retrieve violations at any severity and stores them via callback (to datastore providers).

=head2 Caveats

The collect defaults to the C<top> one million violations per file.

=head1 CALLBACKS

Discovered violations are passed to a datastore via the configured callbacks.

=head2 Store

Store a list of violations associated with a file:

  store(file=>'name',violations=>[...])

The current time is stored as the mtime associated with the update.  Depending on the datastore, updates may only be committed to memory.

=head2 Flush

Force the updates to be saved in the datastore.  A datastore may queue updates from C<store> to reduce overhead, but C<flush> will ensure updates are committed.

Because violation storage includes the current mtime, results that are not committed will be rescanned by the collector on the next run.

=head2 Newer

If defined, files will be skipped if their current on-disk mtime is less than or equal to their mtime in the datastore.  Files not in the datastore are always included.

=head1 TODO

The Collector should support all standard and reasonable C<perlcritic> commandline options.

Provide a mode where files are always "newer" (forced rescan).

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
