package Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles;

#
# copyright (c) 2011 Lukas Thiemeier
#
# this module is free software
#
# see "LICENCE AND COPYRIGHT" below for more information
#

use namespace::autoclean;
use Moose::Role;
use Moose::Util qw/apply_all_roles/;
use Module::Find qw/findallmod/;

our $VERSION = 0.0110;

requires qw/BUILD schema schema_class/;

# where to look for Result-Roles
has role_location => (
	is => 'ro', 
	isa => 'Str', 
	required => 1, 
	lazy => 1,
	init_arg => 'rr_role_location',
	builder => "_build_role_location",
	# transforming "/" to "::" for Module::Find
	trigger => sub {
		my ($self, $value) =@_;
		$value =~ s/\//::/g;
		$self->{role_location} = $value;
	},
);

has quiet => (
	is => 'ro',
	isa => 'Bool',
	required => 1,
	init_arg => 'rr_quiet',
	default => 0,
);

has debug => (
	is => 'ro',
	isa => 'Bool',
	required => 1,
	init_arg => 'rr_debug',
	default => 0,
);

has die => (
	is => 'ro',
	isa => 'Bool',
	required => 1,
	init_arg => 'rr_die',
	default => 0,
);

# apply roles at BUILD time
after BUILD => sub {

	my $self = shift;

	# stop here if role_location is not set
	unless($self->role_location){
		$self->_reaction_on(error => "unable to read \"role_location\", NOT PROCEEDING");
		return;
	}

	my @messages;	# stores status messages
	my @errors;	# stores error messages

	#loop over all result sources
	foreach my $sourcename ($self->schema->sources){

		# store result_class
		my $source = $self->schema->source_registrations->{$sourcename}->result_class;

		# check if the current resultclass is a Moose-class
		if( $source->can("meta")){
			push @messages, "searching roles for $sourcename";

			# find roles
			my $roles = $self->_find_roles_for_source($sourcename);
			if ($roles){

				# try to apply the roles
				eval {apply_all_roles($source->meta, @$roles)};

				if($@){
					# die if roles could not be applied
					die $@;
				}
				else{
					# prepare status messages
					push @messages, "Roles applied to \"$sourcename\": " . join ", ", @$roles;
				}
			}
			else{
				# prepare status messages
				push @messages, "Could not find any roles for \"$sourcename\"";
			}
		}
		else{
			# prepare error messages
			push @errors, "Resultclass \"$sourcename\" does not provide a meta-class";
		}
	}

	# print status and error messages
	my $error_msg = join "\n", @errors if @errors;
	my $status_msg = join "\n", @messages if @messages;
	$self->_reaction_on(
		status => $status_msg,
		error => $error_msg,
	);


};

# returns possible Roles for a given source
sub _find_roles_for_source{
	my ($self,$source) = @_;
	my @roles = findallmod $self->role_location . "::$source";
	return \@roles if @roles;
	return undef;
}

# builds default role_location
sub _build_role_location{
	my ($self) = @_;
	return $self->schema_class . "::ResultRole";
}

# expects error and status message as named parameters
# and prints, warns or dies, depending on the configuration
sub _reaction_on{
	#my ($self) = @_;
	my $self = shift;
	my %args = (@_);
	my $status = "ResultRole [status] :\n". $args{status} if $args{status};
	my $error = "ResultRole [error] :\n". $args{error} if $args{error};
	if($self->die && $error){
		die $error;
	}
	elsif($self->debug){
		warn $error if $error;
		warn $status if $status;
	}
	if(not $self->quiet || $self->debug){
		print "$error\n" if $error and not $self->debug;
		print "$status\n" if $status;
	}
	return 0;
}

1;

__END__

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles - Automatically applying Moose Roles to Result-Classes at BUILD time

=head1 VERSION

Version 0.0110

=head1 SYNOPSIS

In your Catalyst Model (lib/YourApp/Model/YourModel.pm):

	__PACKAGE__->config(
 		...

		traits => "ResultRoles",
	
		...
	);

OR in your Application main file (lib/YourApp.pm):

	__PACKAGE__->config(
		...

		"Model::YourModel" => (
			...

			traits => "ResultRoles",

			...
		),
	);

and then, in an appropriate location (lib/YourApp/Schema/ResultRole/YourResult/YourRole.pm):

	package YourApp::Schema::ResultRole::YourResult::YourRole;

	use namespace::autoclean;
	use Moose::Role;

	YourApp::Schema::Result::YourResult->many_to_many(...);
	YourApp::Schema::Result::YourResult->add_column(...);

	sub your_result_sub{
		# do something result specific
	}
	1;

=head1 DESCRIPTION

This module is a trait for DBIC based Catalyst models.
It hooks to the models BUILD process and appies 
a set of Moose Roles to each loaded resultclass.
This makes it possible to customize the resultclasses
without changing the automaticaly created DBIx::Class::Core files.
Resultclasses can be customized by creating one or more roles per resultclass.
Customized code and automatically created code are clearly seperated.

Because applying roles depends on the presence of a meta-class,
this trait only works with "moosified" resultclasses. "Non-moosified" 
resultclasses are ignored, which makes it possible to use a mixed set
of moosified and non-moosified resultclasses.

=head1 CONFIGURATION

=head2 enabling the traits

See L</SYNOPSIS> above or L<Catalyst::Model::DBIC::Schema/traits>

=head2 creating roles for result classes

=head3 Example:

Assumed the application name is "MyApp", and the schema class is 
"MyApp::Schema". If you want to create a role for "MyApp::Schema::Book",

create lib/MyApp/Schema/ResultRole/Book.pm with the following content:

	package MyApp::Schema::ResultRole::Book::Author;

	use namespace::autoclean;
	use Moose::Role;

	1;

Within this package, MyApp::Schema::Book can be customized with all
features provided by L<Moose::Role>. 
Result-class methods, like "many_to_many" and "has_many" have to be called with the 
full result-class name.

Assumed there is another result-class named "Author" and a corresponding BookAuthor
relation, a many_to_many relation could be defined for MyApp::Schema::Result::Book by
editing the role and adding:

	requires qw/book_authors/;
	MyApp::Schema::Result::Book->many_to_many(authors => 'book_authors', 'author');

to MyApp::Schema::ResultRole::Book::Author, after "use Moose::Role", but before "1;"

=head3 How does it work:

Without further configuration, the trait will guess the role_location attribute
by calling $self->schema_class and appending "::ResultRole". 

Example: Assumed the application name is "MyApp", and the schema class is 
"MyApp::Schema": The result_location will be set to "MyApp::Schema::ResultRole"

Catalyst::TraitFor::Model::DBIC::Schema::Result uses L<Module::Find/find_all_modules> to 
find possible roles for each defined result source. The roles namespace is expected to be:

 $self->role_location . "::". $souce_name

Example: Assumed the application name is "MyApp", the schema class is 
"MyApp::Schema" and the current source name is "Book": All packages in 
"MyApp::Schema::ResultRole::Book" are expected to be roles for
MyApp::Schema::Result::Book;

Possible roles are applied to the schema class with L<Moose::Util/apply_all_roles>.

=head2 setting attributes

All attributes can be configured by setting their "config args"
within the applications configuration, either in the the applications
main file, or in the applications schema class.

Example: Assumed the application name is "MyApp", and the model class is 
"MyApp::Model::DB": To enable the "debug" flag, either add

 __PACKAGE__->config(
 	rr_debug => 1,
 );

to lib/MyApp/Model/DB.pm, or add

 __PACKAGE__->config(
 	'Model::DB' =>{
	 	rr_debug => 1,
	},
 );

to lib/MyApp.pm.


=head1 ATTRIBUTES

The following attributes can be customized:

=over 2

=item * role_location

A String specifying where the trait should look for ResultRoles.
Shoud either be something like "YourApp::Schema::ResultRoles"
or like "YourApp/Schema/ResultRoles"

default: $SCHEMA_CLASS::ResultRoles, where $SCHEMA_CLASS is your 
applications schema class.

config arg: rr_role_location

=item * die

A Boolean. If set to 1, the trait will die when it encounters 
non-moose result classes.

When set to 0, the trait will only die 
on errors concerning user-generated ResultRoles.
Non-moose result classes are ignored.

default: 0

config arg: rr_die

=item * debug 

A Boolean. If set to 1, the trait will print status and
error messages to STERR (unless it has died before)

default: 0

config arg: rr_debug

=item  * quiet

A Boolean. If set to 0, the trait will print status and
error messages to STDOUT (unless it has died or reported to STDERR before)

default: 0

config arg: rr_quiet

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-traitfor-model-dbic-schema-resultroles at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-TraitFor-Model-DBIC-Schema-ResultRoles>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

=over 2

=item * applying roles to ResultSets

=item * manually loading roles from other locations than $self->role_location

=item * moosify result classes on demand

=back

=head1 AUTHOR

Lukas Thiemeier, C<< <lukast at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles

A public subversion repository is available at: 
http://svn.thiemeier.net/public/ResultRole

WebSVN is available at L<http://svn.thiemeier.net/>

=head2 SEE ALSO

=over 2

=item * L<Catalyst::Model::DBIC::Schema/traits>

=item * L<DBIx::Class::Schema>

=item * L<Module::Find> 

=item * L<Moose::Role> 

=item * L<Moose::Util> 

=item * L<MooseX::NonMoose> 

=back

=head1 ACKNOWLEDGEMENTS

=over 2

=item * Larry Marso - thanks for the suggestion

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lukas Thiemeier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

