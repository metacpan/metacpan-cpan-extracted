package Data::Faker;
use vars qw($VERSION); $VERSION = '0.10';

=head1 NAME

Data::Faker - Perl extension for generating fake data

=head1 SYNOPSIS

  use Data::Faker;

  my $faker = Data::Faker->new();

  print "Name:    ".$faker->name."\n";
  print "Company: ".$faker->company."\n";
  print "Address: ".$faker->street_address."\n";
  print "         ".$faker->city.", ".$faker->us_state_abbr." ".$faker->us_zip_code."\n";

=head1 DESCRIPTION

This module creates fake (but reasonable) data that can be used for things
such as filling databases with fake information during development of
database related applications.

=cut

use strict;
use warnings;
use File::Spec ();
use Carp 'croak';
my %plugins;
my @always_import;

=head1 OBJECT METHODS

=over 4

=item new()

Object constructor.  As a shortcut, you can pass names of plugin modules to
load to new(), although this does not actually restrict the functions available
to the object, it just causes those plugins to be loaded if they haven't been
loaded already. All Data::Faker objects in one interpreter share the plugin
data, so that multiple objects don't multiply the memory requirements.

=cut

sub new {
	my $pack = shift;
	my $self = {};
	bless($self,$pack);
	my @import = (@_,@always_import);
	unless(@import) { push(@import,'*'); }
	foreach my $import (@import) {
		foreach(@INC) {
			for(glob(File::Spec->catfile($_, qw/Data Faker/,"$import.pm"))) {
				require $_ if -f $_ && -r _;
			}
		}
	}
	return $self;
}

sub import { my $self = shift; push(@always_import,@_); }

=item methods();

Return a list of the methods that have been provided by all of the loaded
plugins.

=cut

sub methods { return keys %Data::Faker::plugins; }

=item register_plugin();

Plugin modules call register_plugin() to provide data methods.  See any of
the included plugin modules for examples.

=cut

sub register_plugin {
	my $self = shift;
	my @functions = @_;

	push(@{$Data::Faker::plugins{shift()}}, shift()) while @_;
}

use vars qw($AUTOLOAD);
sub AUTOLOAD {
	my $self = shift;
	my $al = $AUTOLOAD;
	$al =~ s/.*:://;
	my @data = @{$Data::Faker::plugins{$al} || []};
	croak "No data found for method '$al'" unless @data;

	my $data = $data[rand(@data)];

	my $result;
	if(! ref($data)) {
		$result = $data;
	} elsif(ref($data) eq 'ARRAY') {
		$result = $data->[rand(@{$data})];
	} elsif(ref($data) eq 'CODE') {
		$result = $data->($self);
	} else {
		croak "Don't know what to do with result of type '".ref($data)."'";
	}
	$result =~ s/\0//g;

	# replace any tokens that need expansion
	$result =~ s/\\\$/\0/g;
	while($result =~ /\$(\w+)/) {
		my $what = $1;
		my $r = $self->$what();
		$result =~ s/\$$what/$r/;
	}
	$result =~ s/\0/\$/g;

	# replace any number needing expansion
	$result =~ s/\\#/\0/g;
	$result =~ s/#/int(rand(10))/ge;
	$result =~ s/\0/#/g;

	return $result;
}

sub DESTROY {}

=back

=head1 LOADING PLUGINS

You can specify which plugins to load by including just the base part of their
name as an argument when loading the module with 'use'.  For example if you
only wanted to use data from the Data::Faker::Name module, you would load
Data::Faker like this:

  use Data::Faker qw(Name);

By default any modules matching Data::Faker::* in any directory in @INC
will be loaded.  You can also pass plugin names when calling the new() method,
and they will be loaded if not already in memory.  See L<new()>.

=head1 WRITING PLUGINS

Writing a plugin to provide new kinds of data is easy, all you have to do is
create a module named Data::Faker::SomeModuleName that inherits from
Data::Faker.

To provide data, the plugin merely needs to call the register_plugin function
with one or more pairs of function name and function data, like this:

  #!/usr/bin/perl -w
  use strict;
  use warnings;
  use Data::Faker;

  my $faker = Data::Faker->new();
  print "My fake data is ".$faker->some_data_function."\n";

  package Data::Faker::SomeData;
  use base 'Data::Faker';

  __PACKAGE__->register_plugin(
    some_data_function => [qw(foo bar baz gazonk)],
    another_data_item => sub { return '$some_data_function' },
  );

The first argument is the method that will be made available to your object,
the second is a data source.  If the data source is not a reference, it will
simply be returned as the data, if it is a reference to an array, a random
element from the array will be returned, and if it is a subroutine reference,
the subroutine will be run and the results will be returned.  The data that
your data source provides is checked for two things, tokens (that look like
perl variables, starting with a $), and numeric indicators (#).  Any tokens
found will be replaced with their values, and any numeric indicators will be
replaced with random numbers.  You can include a literal $ or # by prefacing
it with a backslash.  If you load more than one module that defines the same
function, it has an additive effect, when the function is called one of the
data sources provided will be selected at random and then it will be called
to get a piece of data.

Some data source examples:

  __PACKAGE__->register_plugin(
    age              => ['#','##'],
    monetary_amount  => ['\$####.##','\$###.##', '\$##.##', '\$#.##'],
    adult_age        => sub { int(rand(70)+18) },
  );

If your data source is a code reference, it will receive the calling object
as an argument so you can build data out of other data if you need to.  See
L<Data::Faker::DateTime> for some examples of this.

=head1 BUGS AND KNOWN ISSUES

There is no way to selectively remove data sources from a plugin that was
loaded, even if you didn't load it.

=head1 SEE ALSO

Text::Lorem

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
