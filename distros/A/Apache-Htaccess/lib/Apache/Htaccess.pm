=head1 NAME

Apache::Htaccess - Create and modify Apache .htaccess files

=head1 SYNOPSIS

	use Apache::Htaccess;

	my $obj = Apache::Htaccess->new("htaccess");
	die($Apache::Htaccess::ERROR) if $Apache::Htaccess::ERROR;

	$obj->global_requires(@groups);

	$obj->add_global_require(@groups);

	$obj->directives(CheckSpelling => 'on');

	$obj->add_directive(CheckSpelling => 'on');
	
	$obj->requires('admin.cgi',@groups);

	$obj->add_require('admin.cgi',@groups);

	$obj->save();
	die($Apache::Htaccess::ERROR) if $Apache::Htaccess::ERROR;


=head1 DESCRIPTION

This module provides an object-oriented interface to Apache .htaccess
files. Currently the ability exists to read and write simple htaccess
files.

=head1 METHODS

=over 5

=cut

package Apache::Htaccess;

use strict;
use warnings;
use vars qw($VERSION $ERROR);

use Carp;

( $VERSION ) = '1.6';

#####################################################
# parse
# - Private function -
# In/Out Param: an Apache::Htaccess object
# Function: opens the content stored in $self->{HTACCESS} and converts it to 
#			Apache::Htaccess' internal data structure.
# Note: this will act on the object in place (note the prototype).

my $parse = sub (\$) { 
	my $self = shift;


	#Suck off comments
	$self->{HTACCESS} =~ s/[\#\;].*?\n//sg;


	#Suck off and store <files> directives
	my @files = $self->{HTACCESS} =~ m|(<files.+?/files>)|sig;
	$self->{HTACCESS} =~ s|<files.+?/files>||sig;


	#Munge <files> directives into the data structure
	foreach my $directive (@files) {
		my ($filelist) = $directive =~ /<files\s+(.+?)>/sig;
		my @filelist = split(/\s+/,$filelist);
		
		my ($groups) = $directive =~ /require group\s+(.+?)\n/sig;
		my @groups = split(/\s+/,$groups);
		
		foreach my $file (@filelist) {
			foreach (@groups) {
				$self->{REQUIRE}->{$file}->{$_}++;
			}
		}
	}		

	if( $self->{HTACCESS} =~ s/require group\s+(.+?)\n//is )
		{
		@{$self->{GLOBAL_REQ}} = split( /\s+/, $1);
		}
		
	#Suck off and store all remaining directives
	while($self->{HTACCESS} =~ /^(.+?)$/mg) 
		{
		my( $directive, $value ) = split /\s+/, $1, 2;
		$value = defined $value ? $value : '';
		push @{$self->{DIRECTIVES}}, $directive, $value;
		}

	chomp @{$self->{DIRECTIVES}};


	#dump the remaining file bits
	delete $self->{HTACCESS};
};



#####################################################
# deparse
# - Private function -
# In/Out Param: an Apache::Htaccess object
# Function: takes the object's internal data structures 
# and generates an htaccess file.
# The htaccess file contents are stored in $self->{HTACCESS}
# Note: this will act on the object in place (note the prototype).

my $deparse = sub (\$) {
	my $self = shift;
	my $content;
		
	if( $self->{GLOBAL_REQ} ) { 
		$content .= "require group @{$self->{GLOBAL_REQ}}\n";
	}
	
	if(exists($self->{DIRECTIVES})) {	
		my $i;
		for($i = 0; $i < @{$self->{DIRECTIVES}}; $i++) {
			my $key = $self->{DIRECTIVES}[$i];
			my $value = $self->{DIRECTIVES}[++$i];
			next unless defined $key && defined $value;
			$content .= "$key";
			$content .= " $value" if $value ne '';
			$content .= "\n";
		}
	}
	
	# $content .= "\n";	

	if(exists($self->{REQUIRE})) {
		foreach (keys %{$self->{REQUIRE}}) {
			next unless exists $self->{REQUIRE}->{$_};
			
			my $groups = join " " , sort keys %{$self->{REQUIRE}->{$_}};
			next unless $groups;
			
			$content .= "<files $_>\n";
			$content .= "\trequire group $groups\n";
			$content .= "</files>\n";
		}
	}

	$self->{HTACCESS} = $content;

};



##########################################################
=back

=head2 B<new()>

	my $obj = Apache::Htaccess->new($path_to_htaccess);

Creates a new Htaccess object either with data loaded from an existing
htaccess file or from scratch

=cut
		  
sub new {
	undef $ERROR;
	my $class = shift;
	my $file = shift;
	
	unless($file) {
		$ERROR = "Must provide a path to the .htaccess file";
		return 0;
	}
	
	my $self = {};
	$self->{FILENAME} = $file;
	if(-e $file) {
		unless( open(FILE,$file) ) {
			$ERROR = "Unable to open $file";
			return 0;
		}
		
		{	local $/; 
			$self->{HTACCESS} = <FILE>;
		}
		
		close FILE;
		&$parse($self);
	}

	bless $self, $class;
	return $self;
}


=head2 B<save()>

	$obj->save();

Saves the htaccess file to the filename designated at object creation.
This method is automatically called on object destruction.

=cut

sub save {
	undef $ERROR;
	my $self = shift;
	&$deparse($self);
	unless( open(FILE,"+>$self->{FILENAME}") ) {
		$ERROR = "Unable to open $self->{FILENAME} for writing";
		return 0;
	}
	print FILE $self->{HTACCESS};
	close FILE;
	return 1;
}

sub DESTROY {
	my $self = shift;
	$self->save();
}


=head2 B<global_requires()>

	$obj->global_requires(@groups);

Sets the global group requirements. If no params are provided,
will return a list of the current groups listed in the global
require. Note: as of 0.3, passing this method a 
parameter list causes the global requires list to be overwritten
with your parameters. see L<add_global_require()>.

=cut

sub global_requires {
	undef $ERROR;
	my $self = shift;
	
	if( @_ ) {
		@{$self->{GLOBAL_REQ}} = @_
		}
	elsif( @{$self->{GLOBAL_REQ}} ) {
		return @{$self->{GLOBAL_REQ}}
		}
	else {
		return 0;
		}

	return 1;
}


=head2 B<add_global_require()>

	$obj->add_global_require(@groups);

Sets a global require (or requires) nondestructively. Use this
if you just want to add a few global requires without messing
with all of the global requires entries.

=cut

sub add_global_require {
	undef $ERROR;
	my $self = shift;
	@_ ? push @{$self->{GLOBAL}}, @_
	   : return 0;
	return 1;
}


=head2 B<requires()>

	$obj->requires($file,@groups);

Sets a group requirement for a file. If no params are given,
returns a list of the current groups listed in the files
require directive.  Note: as of 0.3, passing this method a 
parameter list causes the requires list to be overwritten
with your parameters. see L<add_require()>.

=cut

sub requires {
	undef $ERROR;
	my $self = shift;
	my $file = shift or return 0;
	if(@_) {
		delete $self->{REQUIRE}->{$file};
		foreach my $group (@_) {
			$self->{REQUIRE}->{$file}->{$group}++;
		}
	} else {
	   return sort keys %{$self->{REQUIRE}->{$file}};
	}
	return 1;
}



=head2 B<add_require()>

	$obj->add_require($file,@groups);

Sets a require (or requires) nondestructively. Use this
if you just want to add a few requires without messing
with all of the requires entries.

=cut

sub add_requires {
	undef $ERROR;
	my $self = shift;
	my $file = shift or return 0;
	if(@_) {
		foreach my $group (@_) {
			$self->{REQUIRE}->{$file}->{$group}++;
		}
	} else {
		return 0;
	}
}



=head2 B<directives()>

	$obj->directives(CheckSpelling => 'on');

Sets misc directives not directly supported by the API. If
no params are given, returns a list of current directives 
and their values. Note: as of 0.2, passing this method a 
parameter list causes the directive list to be overwritten
with your parameters. see L<add_directive()>.

=cut

sub directives {
	undef $ERROR;
	my $self = shift;
	@_ ? @{$self->{DIRECTIVES}} = @_
	   : return @{$self->{DIRECTIVES}};
	return 1;
}


=head2 B<add_directive()>

	$obj->add_directive(CheckSpelling => 'on');

Sets a directive (or directives) nondestructively. Use this
if you just want to add a few directives without messing
with all of the directive entries.

=cut

sub add_directive {
	undef $ERROR;
	my $self = shift;
	@_ ? push @{$self->{DIRECTIVES}}, @_
	   : return 0;
	return 1;
}


1;


=head1 TO DO

* rewrite the parser to handle blocks
* improve documentation
* Oracale iPlanet htaccess parser

=head1 SOURCE CODE

This module is in GitHub:

	https://github.com/archeac/apache-htaccess.git

=head1 AUTHOR 

Matt Cashner <matt@cre8tivegroup.com> originally created this module.
brian d foy <bdfoy@cpan.org> maintained it for a long time.

Now this module is maintained by Arun Venkataraman <arun@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2016 Arun Venkataraman

This module may be distributed under the terms of Perl itself.	

=cut
