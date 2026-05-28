package App::CriticDB;
use strict;
use warnings;

use Carp qw/confess/;

use App::CriticDB::Collector;
use App::CriticDB::DB;
use App::CriticDB::Report;

our $VERSION='0.0.4';

sub new {
	my ($ref,%opt)=@_;
	my $class=ref($ref)||$ref;
	my %self;
	if($opt{file})                             { %self=(mode=>'file',file=>$opt{file},type=>$opt{type}//'storable') }
	else                                       { confess('Only file mode is available at this time') }
	@self{qw/profile debug/}=@opt{qw/profile debug/};
	return bless(\%self,$class);
}

sub _load {
	my ($self)=@_;
	if($$self{db}) { return }
	$$self{db}=App::CriticDB::DB->new(%$self);
	return $self;
}

sub collect {
	my ($self,@paths)=@_;
	$self->_load();
	$$self{db}->cleanup();
	$$self{collector}//=App::CriticDB::Collector->new(
		profile=>$$self{profile},
		debug=>$$self{debug},
		store=>sub{$$self{db}->store(@_)},
		flush=>sub{$$self{db}->flush(@_)},
		newer=>sub{$$self{db}->newer(@_)},
		);
	$$self{collector}->collect(@paths);
	return $self;
}

sub report {
	my ($self,%opt)=@_;
	$self->_load();
	my $report=App::CriticDB::Report->new(verbose=>$opt{verbose});
	while(my $violation=$$self{db}->report()) { print $report->text($violation) }
	return $self;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB - Manage a database of Perl::Critic violations

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

  use App::CriticDB;
  my $criticdb=App::CriticDB->new(
    ...
  );
  $criticdb->collect(pathspec, ...);
  $criticdb->report();

Or called via commandline

  perlcriticdb --file=filename.stor --profile=perlcritic.rc /path/to/files

=head1 DESCRIPTION

The C<perlcriticdb> tool finds and retains L<Perl::Critic> violations for a large repository of files, permits updates per file, and quick reporting of policy counts without the large runtimes of the main C<perlcritic> command.

=head1 STORAGE ENGINES

Violation data can be stored on disk.

=head2 File

L<Perl::Critic> violations may be stored in a local file:

  my $criticdb=App::CriticDB->new(file=>'violations.stor',type=>'storable');
  $criticdb->collect('/path/to/lib');

The C<type> may be:

  storable   Storable (default)
  dump       Data::Dumper (not yet available)

Note that L<Data::Dumper> files can be useful for debugging purposes but are not recommended for long term use, as they can be 10--30x slower for read/write operations.

=head1 REPORTING

Output similar to C<perlcritic> can be produced by calling as

  $criticdb->report(verbose=>'... format ...')

This supports both numeric and the string format specifiers from C<perlcritic>.

Currently only reporting to STDOUT is supported.

=head1 FILE UPDATES

=head2 Detecting file updates

Violations are stored together with the current I<mtime> for each file.  On subsequent scans, files will be skipped unless their on-disk I<mtime> exceeds the previous value.

=head2 File deletions

The collector will re-verify the existence of all files at the beginning of each run.  Files that no longer exist are removed from the datastore.

=head1 TODO

=head2 Collection

Newer file discovery:  Add support for any combination of timestamp/filesize/MD5 method for determining files that need scanned.

File deletion currently always happens.  Add an option to retain missing files.

=head2 Storage

DBD::*. Plain file input (such as the lines produced by perlcritic normally).

=head2 Reporting

Support named-module hooks that handle each violation.  This will be useful for filename remapping, addition of org-specific data, and rerouting to metrics collectors.

Behavior of "OK" files is not currently defined, as the datastore retains violations only.

=head2 Commandline tool

The script should support filter/selection similar to `perlcritic`, specifically severity selection and include/exclude.  File aggregation may also be useful, but should not be the default.  Support a --nodelete option to prevent removal of missing files.

From the commandline, the profile must always be specified, which permits migration to new profiles.  In the common use case, however, the profile file should likely be retained in the datastore so subsequent execution can be performed without the explicit commandline argument.

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
