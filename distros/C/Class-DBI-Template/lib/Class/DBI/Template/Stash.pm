package Class::DBI::Template::Stash;
use strict;
use warnings;
use base qw/Template::Stash/;
our $VERSION = '0.03';
require UNIVERSAL;

use vars qw/$default_order $default_preload/;
$default_preload = [qw/arguments/];
$default_order = [qw/columns template_data functions/];

my %handlers = (
	columns	=> sub {
		my($self,$this,$ident,$args) = @_;
		return if ref $ident;
		return unless ref $this;
		return unless UNIVERSAL::isa($this,"Class::DBI");
		return unless UNIVERSAL::can($this,"find_column");
		return unless $this->find_column($ident);
		return unless UNIVERSAL::can($this,"get");
		return $this->get($ident);
	},
	template_data => sub {
		my($self,$this,$ident,$args) = @_;
		return if ref $ident;
		return unless UNIVERSAL::can($this,"template_data");
		my %data = $this->template_data();
		return unless exists $data{$ident};
		return $data{$ident};
	},
	functions => sub {
		my($self,$this,$ident,$args) = @_;
		return if ref $ident;
		return unless UNIVERSAL::can($this,$ident);
		return unless ref($this);
		return $this->$ident($args);
	},
	environment => sub {
		my($self,$this,$ident,$args) = @_;
		return if ref $ident;
		return $ENV{$ident};
	},
	arguments => sub {
		my($self,$this,$ident,$args) = @_;
		return if ref $ident;
		return unless ref $self;
		return $self->{_ARGS}->{$ident};
	},
);

sub unfold {
	my @start = @_;
	if(@start == 1 && ref($start[0])) { @start = @{$start[0]}; }
	unless(@start) { @start = @{$default_order} }
	my @order = ();
	{
		my @new = ();
		foreach(@start) {
			next unless $_;
			if($_ eq '+') {
				push(@new,@{$default_order});
			} else {
				push(@new,$_);
			}
		}
		my %seen = ();
		foreach(@new) {
			push(@order,$_) unless $seen{$_}++;
		}
	}
	return @order;
}

sub get {
	my $self = shift;
	my $ident = shift;
	my $args = shift;
	my $root = $self;
	my $result;

	return '' if $ident eq '_SELF';

	if (ref $ident eq 'ARRAY'
		|| ($ident =~ /\./)
		&& ($ident = [ map { s/\(.*$//; ($_,0) } split(/\./, $ident) ])) {

		foreach(my $i = 0; $i <= $#$ident; $i += 2) {
			$result = $self->_dotop($root, @$ident[$i, $i+1]);
			unless($i || defined $result) {
				$result = $self->find_item(@$ident[$i, $i+1]);
			}
			last unless defined $result;
			$root = $result;
		}
	} else {
		$result = $self->_dotop($root, $ident, $args);
		unless(defined $result) {
			$result = $self->find_item($ident,$args);
		}
	}
	return defined $result ? $result : $self->undefined($ident,$args);
}

sub find_item {
	my $self = shift;
	my $ident = shift;
	my $args = shift;

	die "Can't find_item(_SELF)" if $ident eq '_SELF';
	my $this = $self->{'_SELF'} || die "Couldn't find myself!";
	my $conf = $self->{'_CONF'} || {};

	my $result;
	# TODO - this needs better error handling
	foreach my $order (unfold($conf->{stash_order})) {
		# basically need to eval everything in here, in case the functions
		# being called die.  If they die we try the next handler.
		$result = eval {
			if(!ref($order) && exists $handlers{$order}) {
				return $handlers{$order}->($self,$this,$ident,$args);
			} elsif(ref($order) =~ /CODE/) {
				return $order->($this,$ident,$args);
			} elsif(ref($order) =~ /HASH/) {
				return $order->{$ident};
			}
		};
		last if(defined $result && !$@);
	}

	if($conf->{stash_cache}) {
		$self->set($ident,$result);
	}

	return $result;
}

1;
__END__

=head1 NAME

Class::DBI::Template::Stash - Template::Stash subclass for Class::DBI::Template

=head1 SYNOPSIS

  package Music::DBI;
  use base 'Class::DBI';
  use Class::DBI::Template;

=head1 DESCRIPTION

There is nothing you need to do for this module, it is setup for you when you
use Class::DBI::Template.  It provides a subclass of Template::Stash that
overrides it's get() method.  The new method knows how to find the Class::DBI
object that we are rendering, and how to get information out of it for use by
the Template module for rendering your template.

=head1 EXPORT

Nothing is exported, it simply makes a Template::Stash subclass, which is used
when building the Template object which will render your data.

=head1 CONFIGURATION

There are a couple of configuration options for this module, which can be
passed either to template_configure() in the class being setup, or to
template_render() while rendering an object.

The only configuration this module has is -stash_order and -stash_preload
keys, which can be passed to template_configure in the class using
Class::DBI::Template (or to the template_render() method when rendering.)  
Both these options take an array reference as an argument.

=over 4

=item -stash_order

This determines what order the stash module uses in searching for data
for your object. The first option in the -stash_order search that returns a
defined value will cause the search to end and the value to be returned.
See 'SEARCH OPTIONS' below for a list of the items that can be passed to
-stash_order.

=item -stash_preload

This lists options that should have their data preloaded into the
stash object.  This saves you the time of having the stash search for their
values, at the expense of having to determine all their values up front.  It
is up to you to determine which way is faster based on your data.  Options
passed to -stash_preload will automatically be removed from -stash_order if
they are there.
See 'SEARCH OPTIONS' below for a list of the items that can be passed to
-stash_preload.

=item -stash_cache

By default, when this module is required to search for a variable, it adds
the item it found to the stash, to prevent having to search for it in the
future.  Set -stash_cache to a false value to prevent this caching.

=back

=head2 SEARCH OPTIONS

Options that you can pass to -stash_order or -stash_preload (except where
noted) are listed below.  Undefined values cause the search to continue
unless otherwise noted below.

=over 4

=item 'columns'

This option indicates to search the database columns associated with the
current object.  The column names returned by $object->columns will be used
to collect this data.  If this variable is included in STASH_ORDER, what is
actually given to the template are subroutines that will collect the data
only when the template actually uses it.  This can save you a lot of time as
it defers database accesses until needed.  If you preload columns, every
column in the database will be retrieved for each object, this might be slow.
If you really want to preload columns, you would do well to put all your
columns in one group, if you split them up into multiple column groups, then
preloading will result in multiple database calls until all the columns are
loaded.

=item 'template_data'

The template_data option searches for values that you previously set by
calling __PACKAGE__->template_data(something => 'some value').  This can
be preloaded fairly quickly, it's just preloading the has reference.

=item 'functions'

The functions option will check to see if your object has a method that it
can run with the name of the item being searched for.  If one is found, then
the method will be run as an instance method if template_render was called
as an instance method, or as a class method if template_render was called
as a class method, and it's return value used if defined.  Functions cannot
be preloaded, as there is no way to determine what functions are available
and can be safely called.  You can emulate preloading functions by using:

  for my $function (qw/function1 function2 function3/) {
    __PACKAGE__->template_data($function => sub { shift()->$function());
  }
  __PACKAGE__->template_configure(STASH_PRELOAD => [qw/template_data/],

=item 'environment'

The environment option will look for the search object in the %ENV hash.  It
can be preloaded quickly.

=item 'arguments'

The arguments option searches the hash of additional arguments that were
passed to the template_render call.  Preloading the arguments is rather quick,
and it is the only item that defaults to preloaded.

=item HASH REFERENCE

If the search order contains a hash reference, it will be checked to see if it
contains a key that matches the search term.  Obviously hash references cannot
be preloaded using STASH_PRELOAD, use template_data to preload them instead.

=item CODE REFERENCE

If the search order contains a code reference, it will be run and it's return
value used if defined.  When run it will be passed three arguments, the object
being rendered (a Class::DBI subclass), and the term and arguments from the
template.  Code references cannot be preloaded using STASH_PRELOAD, use
template_data to preload them.

=back

The default value for -stash_order is ['columns', 'template_data', 'functions'].
If no match is found in the -stash_order search for the term in question, then
it will be replaced in the template with an empty string.  If -stash_order
contains a lone + sign anywhere in the search order, it will be replaced with
the default -stash_order.  If the same option is specified more than once in
the search order, only the first one will actually be tested.

The default for -stash_preload is 'arguments'.

  __PACKAGE__->template_configure(-stash_order => ['environment']);
  # -stash_order is now: environment

  __PACKAGE__->template_configure(-stash_order => ['+', 'environment']);
  # -stash_order is now: columns template_data functions environment

  __PACKAGE__->template_configure(-stash_order => ['environment', '+']);
  # -stash_order is now: environment columns template_data functions

=head1 SEE ALSO

=over 4

=item Class::DBI::Template

The Hints and Tips section of the Class::DBI::Template documentation has some
tricks you can play with the -stash_order setting to make your life easier
when debugging.

=back

=head1 AUTHOR

Jason Kohles E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
