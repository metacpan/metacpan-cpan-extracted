package Adapter::Async::Model;
$Adapter::Async::Model::VERSION = '0.019';
use strict;
use warnings;

=head1 NAME

Adapter::Async::Model - helper class for defining models

=head1 VERSION

version 0.018

=head1 DESCRIPTION

Generates accessors and helpers for code which interacts with L<Adapter::Async>-related 
classes. Please read the warnings in L<Adapter::Async> before continuing.

All definitions are applied via the L</import> method:

 package Some::Class;
 use Adapter::Async::Model {
  some_thing => 'string',
  some_array => {
   collection => 'OrderedList',
   type => '::Thing',
  }
 };

Note that methods are applied via a UNITCHECK block by default.

=cut

use Log::Any qw($log);

use Future;

use Module::Load;
use Data::Dumper;
use Variable::Disposition qw(retain_future);

=head2 import

=over 4

=item * defer_methods - if true (default), this will delay creation of methods such as C<new> using a UNITCHECK block, pass defer_methods => 0 to disable this and create the methods immediately

=item * model_base - the base class to prepend when types are specified with a leading ::

=back

=cut

my %defined;

sub import {
	my ($class, $def, %args) = @_;
	my $pkg = caller;
	# No definition? Then we're probably just doing a module-load test, nothing
	# for us to do here
	return unless $def;

	$defined{$pkg} = 1;
	$args{defer_methods} = 1 unless exists $args{defer_methods};
	($args{model_base} = $pkg) =~ s/Model\K.*// unless exists $args{model_base};

	my $type_expand = sub {
		my ($type) = @_;
		return unless defined $type;
		$type = $args{model_base} . $type if substr($type, 0, 2) eq '::';
		$type
	};

	my %loader;

	my @methods;
	for my $k (keys %$def) {
		my $details = $def->{$k};
		$details = { type => $details } unless ref $details;
		my $code;
		my %collection_class_for = (
			UnorderedMap => 'Adapter::Async::UnorderedMap::Hash',
			OrderedList  => 'Adapter::Async::OrderedList::Array',
		);
		if(defined(my $from = $details->{from})) {
			$log->tracef("Should apply field %s from %s for %s", $k, $from, $pkg);
			++$loader{$_} for grep /::/, map $type_expand->($_), @{$details}{qw(type)};
		} else {
			no strict 'refs';
			no warnings 'once';
			push @{$pkg . '::attrs'}, $k unless $details->{collection}
		}

		if(my $type = $details->{collection}) {
			my $collection_class = $collection_class_for{$type} // die "unknown collection $type";
			++$loader{$collection_class};
			$log->tracef("%s->%s collection: %s", $pkg, $k, $type);
			++$loader{$_} for grep /::/, map $type_expand->($_), @{$details}{qw(key item)};
			$code = sub {
				my $self = shift;
				die "no args expected" if @_;
				$self->{$k} //= $collection_class->new;
			}
		} else {
			my $type = $type_expand->($details->{type} // die "unknown type in package $pkg - " . Dumper($def));
			++$loader{$type} if $type =~ /::/;

			$log->tracef("%s->%s scalar %s", $pkg, $k, $type);
			$code = sub {
				my ($self) = shift;
				return $self->{$k} unless @_;
				$self->{$k} = shift;
				return $self
			}
		}

		push @methods, $k => $code;
	}

	push @methods, new =>  sub {
		my ($class) = shift;
		my $self = bless { @_ }, $class;
		$self->init if $self->can('init');
		$self
	};
	push @methods, get_or_create => sub {
		my ($self, $type, $v, $create) = @_;
		return Future->done($v) if ref $v;
		retain_future(
			$self->$type->exists($v)->then(sub {
				return $self->$type->get_key($v) if shift;

				my $item = $create->($v);
				$log->tracef("Set %s on %s for %s to %s via %s", $v, $type, "$self", $item, ''.$self->$type);
				$self->$type->set_key(
					$v => $item
				)->transform(
					done => sub { $item }
				)
			})
		)
	};

	for(sort keys %loader) {
		$log->tracef("Loading %s for %s", $_, $pkg);
		Module::Load::load($_) unless exists($defined{$_}) || $_->can('new')
	}

	my $apply_methods = sub {
		while(my ($k, $code) = splice @methods, 0, 2) {
			no strict 'refs';
			if($pkg->can($k)) {
				$log->tracef("Not creating method %s for %s since it exists already", $k, $pkg);
			} else {
				*{$pkg . '::' . $k} = $code;
			}
		}
	};

	if($args{defer_methods}) {
		require Check::UnitCheck;
		Check::UnitCheck::unitcheckify($apply_methods);
	} else {
		$apply_methods->();
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
