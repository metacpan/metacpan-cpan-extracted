use strict;
use warnings;
package Data::Stream::Bulk::AnyEvent;

# ABSTRACT: AnyEvent-friendly Data::Stream::Bulk::Callback
our $VERSION = 'v0.0.2'; # VERSION:

use Moose;
use AnyEvent;
use Carp;

with qw(Data::Stream::Bulk);

has _cv => (
	is => 'rw',
	isa => 'Maybe[AnyEvent::CondVar]',
	default => undef,
);

has _done => (
	is => 'rw',
	isa => 'Bool', 
	default => 0
);

has cb => (
	is => 'rw',
	isa => 'Maybe[CodeRef]',
	trigger => \&_on_cb_set,
	default => undef,
);

has callback => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1
);

sub is_done
{
	my $self = shift;
	return $self->_done;
}

sub next
{
	my $self = shift;
	return if $self->is_done;
	$self->cb(undef) if $self->cb;
	$self->_cv($self->callback->()) if(! $self->_cv);
	my $ret = $self->_cv->recv;
	$self->_cv(undef);
	$self->_done(1) if ! defined $ret;
	return $ret;
}

sub _on_cb_set
{
	my ($self, $new, $old) = @_;
	return if !defined($new) && !defined($old);
	if(defined($new)) {
		my $sub; $sub = sub {
			my $ret = shift;
			$self->_cv(undef);
			$self->_done(1) if(! defined $ret->recv);
			if($new->($ret) && defined $ret->recv) {
				$self->_cv($self->callback->());
				$self->_cv->cb($sub);
			}
		};
		$self->_cv($self->callback->()) if(! $self->_cv);
		$self->_cv->cb($sub);
	} else {
		$self->_cv->croak(q{Callback `cb' was set as undef during active iteration}) if $self->_cv;
	}
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Stream::Bulk::AnyEvent - AnyEvent-friendly Data::Stream::Bulk::Callback

=head1 VERSION

version v0.0.2

=head1 SYNOPSIS

  # Default to blocking-mode
  my $stream = Data::Stream::Bulk::AnyEvent->new(
      # Producer callback has no arguments, and MUST return condition variable.
      # Items are sent via the condition variable as array ref.
      # If there are no more data, send undef.
      producer => sub {
          my $cv = AE::cv;
          my $w; $w = AE::timer 1, 0, sub { # Useless, just an example
              undef $w;
              my $entry = shift @data; # defined like my @data = ([1,2], [2,3], undef);
              $cv->send($entry);
          };
          return $cv;
      }
  );
  # In this mode, you can use this class like other Data::Stream::Bulk subclasses, at client side
  # NOTE that calling C<next> includes blocking wait AE::cv->recv() internally.
  $stream->next if ! $stream->is_done;

  # Callback-mode
  # This is natrual mode for asynchronous codes.
  # Callback is called for each producer call.
  # If you want to get more items, callback SHOULD return true. If not, return false.
  my $stream = Data::Stream::Bulk::AnyEvent->new(
      callback => sub { ... }, ...
  )->cb(sub { my $ref = shift->recv; ... return defined $ref; });

=head1 DESCRIPTION

This class is like L<Data::Stream::Bulk::Callback>, but there are some differences.

=over 4

=item *

Consumer side can use asynchronous callback style.

=item *

Producer callback does not return actual items but returns a condition variable. Items are sent via the condition variable.

=back

Primary purpose of this class is to make L<Net::Amazon::S3>, using L<Data::Stream::Bulk::Callback>, AnyEvent-friendly by using L<Module::AnyEvent::Helper::Filter>.

=head1 ATTRIBUTES

=head2 C<callback =E<gt> sub { my $cv = AE::CV; ... return $cv; }>

Same as L<Data::Stream::Bulk::Callback>.

Specify callback code reference called when data is requested.
This attribute is C<required>. Therefore, you need to specify in constructor argument.

There is no argument of the callback. Return value MUST be a condition variable that items are sent as an array reference.
If there is no more items, send C<undef>.

=head2 C<cb =E<gt> sub { my ($cv) = @_; }>

Specify callback code reference called for each producer call.
A parameter of the callback is an AnyEvent condition variable.
If the callback returns true, iteration is continued.
If false, iteration is suspended.
If you need to resume iteration, you should call C<next> or set C<cb> again even though the same C<cb> is used. 

If you do not need callback, call C<next> or set C<cb> as C<undef>.
Setting C<cb> as C<undef> is succeeded only when iteration is not active, which means suspended or not started.
To set C<callback> as not-C<undef> means this object goes into callback mode,
while to set C<callback> as C<undef> means this object goes into blocking mode.

You can change this value during lifetime of the object, except for the limitation described above.

=head1 METHODS

=head2 C<next()>

Same as L<Data::Stream::Callback>.
If called in callback mode, the object goes into blocking mode and callback is canceled.

=head2 C<is_done()>

Same as L<Data::Stream::Callback>.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
