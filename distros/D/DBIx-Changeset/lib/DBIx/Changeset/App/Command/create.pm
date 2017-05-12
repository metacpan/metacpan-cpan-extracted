package DBIx::Changeset::App::Command::create;

use warnings;
use strict;

use base qw/DBIx::Changeset::App::BaseCommand/;
use DBIx::Changeset::Collection;
use DBIx::Changeset::Exception;
use Term::Prompt;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::App::Command::create - command module used to create a new blank changeset

=head1 SYNOPSIS

=head1 METHODS

=head2 run

=cut
sub run {
	my ($self, $opt, $args) = @_;

	my $coll = DBIx::Changeset::Collection->new('disk', {
		changeset_location => $opt->{'location'},
		create_template => $opt->{'template'},
	});
	my $tag = $args->[0];
	my $filename;	
	### add via our collection
	eval { $filename = $coll->add_changeset($tag); };

	my $e;
	if ( ($e = Exception::Class->caught('DBIx::Changeset::Exception::DuplicateRecordNameException')) && ( defined $opt->{'prompt'} ) ) {
		### ok we have a duplicate record name
		# prompt for overwrite
		my $overwrite_flag = &prompt("y", "File ".$e->filename." already exists, overwrite ?", "y/N", "N");
		if ( $overwrite_flag == 1 ) {
			# remove existing file
			eval { unlink $e->filename };
			if ( $@ ) {
				warn "Could not unlink ".$e->filename." to overwrite it because: $@";
				exit;
			} else {
				eval { $filename = $coll->add_changeset($tag); };
				if ( my $e = Exception::Class->caught() ) {
					warn $e->error, "\n";
					warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
					exit;
				}
			}
		} else {
			# prompt for new filename suggest givenname + _time()
			my $new_file = &prompt("x", "Ok then what shall we call it ?", "valid filename", $tag . "_" . time() );
			eval { $filename = $coll->add_changeset($new_file); };
			if ( my $e = Exception::Class->caught() ) {
				warn $e->error, "\n";
				warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
				exit;
			}
		}
	} elsif ( $e = Exception::Class->caught() ) {
		warn $e->error, "\n";
		warn $e->trace->as_string, "\n" if defined $opt->{'debug'};	
		exit;
	}

	### get the record to get the proper filename
	my $rec = $coll->next();

	printf "Changeset file created: %s\n", $filename;

	if ( $opt->{'edit'} ) {
		my $editor = $opt->{'editor'} || $ENV{'EDITOR'};
		if ($editor) {
			system($editor, $filename);
		}
	}
	
	if ( $opt->{'vcs'} ) {
		if ($opt->{'vcsadd'} ) {	
			my $cmd = sprintf("%s %s", $opt->{'vcs'}, $filename);
			system($cmd);
		} else {
			warn qq{--vcs option has no effect without also specifying --vcsadd\n};
			warn qq{  eg:  --vcs --vcsadd="svn add"\n};
		}
	}

	return;
}

=head2 options

	define the options for the create command

=cut

sub options {
	my ($self, $app) = @_;
	return (
		[ 'edit' => 'Call editor', { default => $app->{'config'}->{'create'}->{'edit'} || undef } ],
		[ 'editor=s' => 'Path to Editor', { default => $app->{'config'}->{'create'}->{'edit'} || undef } ],
		[ 'location=s' => 'Path to changeset files', { default => $app->{'config'}->{'location'} || $app->{'config'}->{'create'}->{'location'} || undef, required => 1 } ],
		[ 'vcs' => 'Add to version control', { default => $app->{'config'}->{'create'}->{'vcs'} || undef } ],
		[ 'vcsadd=s' => 'Command to add to version control', { default => $app->{'config'}->{'create'}->{'vcsadd'} || undef } ],
		[ 'template=s' => 'Path to changeset template', { default => $app->{'config'}->{'create'}->{'template'} || 'template.txt', required => 1 } ],
	);
}

=head2 validate

 define the options validation for the create command

=cut

sub validate {
	my ($self,$opt,$args) = @_;
	$self->usage_error('This command requires a valid changeset location') unless ( ( defined $opt->{'location'} ) && ( -d $opt->{'location'} ) );
	$self->usage_error('This command requires a valid changeset name') unless ( ( defined $args->[0] ) && ( length $args->[0] > 0 ) );
	return;
}


=head2 usage_desc

	Override to show usage of changeset_name

=cut

sub usage_desc {
	return "%c create %o <changeset_name>";
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset
