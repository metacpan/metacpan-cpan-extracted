use 5.008;
use strict;
use warnings;

package Class::Null;
BEGIN {
  $Class::Null::VERSION = '2.110730';
}
# ABSTRACT: Implements the Null Class design pattern
use overload
  'bool'   => sub { 0 },
  '""'     => sub { '' },
  '0+'     => sub { 0 },
  fallback => 1;
our $null = bless {}, __PACKAGE__;
sub AUTOLOAD { $null }
1;


__END__
=pod

=head1 NAME

Class::Null - Implements the Null Class design pattern

=head1 VERSION

version 2.110730

=head1 SYNOPSIS

  use Class::Null;

  # some class constructor and accessor declaration here

  sub init {
    my $self = shift;
    # ...
    $self->log(Class::Null->new);
    # ...
  }

  sub do_it {
    my $self = shift;
    $self->log->log(level => 'debug', message => 'starting to do it');
    # ...
    $self->log->log(level => 'debug', message => 'still doing it');
    # ...
    $self->log->log(level => 'debug', message => 'finished doing it');
  }

=head1 DESCRIPTION

This class implements the Null Class design pattern.

Suppose that methods in your object want to write log messages to a log
object. The log object is possibly stored in a slot in your object and
can be accessed using an accessor method:

  package MyObject;

  use base 'Class::Accessor';
  __PACKAGE__->mk_accessors(qw(log));

  sub do_it {
    my $self = shift;
    $self->log->log(level => 'debug', message => 'starting to do it');
    ...
    $self->log->log(level => 'debug', message => 'still doing it');
    ...
    $self->log->log(level => 'debug', message => 'finished doing it');
  }

The log object simply needs to have a C<log()> method that accepts
two named parameters. Any class defining such a method will do, and
C<Log::Dispatch> fulfills that requirement while providing a lot of
flexibility and reusability in handling the logged messages.

You might want to log messages to a file:

  use Log::Dispatch;

  my $dispatcher = Log::Dispatch->new;

  $dispatcher->add(Log::Dispatch::File->new(
    name      => 'file1',
    min_level => 'debug',
    filename  => 'logfile'));

  my $obj = MyObject->new(log => $dispatcher);
  $obj->do_it;

But what happens if we don't define a log object? Your object's methods
would have to check whether a log object is defined before calling the
C<log()> method. This leads to lots of unwieldy code like

  sub do_it {
    my $self = shift;
    if (defined (my $log = $self->log)) {
      $log->log(level => 'debug', message => 'starting to do it');
    }
    ...
    if (defined (my $log = $self->log)) {
      $log->log(level => 'debug', message => 'still doing it');
    }
    ...
    if (defined (my $log = $self->log)) {
      $log->log(level => 'debug', message => 'finished doing it');
    }
  }

The proliferation of if-statements really distracts from the actual call
to C<log()> and also distracts from the rest of the method code. There
is a better way. We can ensure that there is always a log object that we can
call C<log()> on, even if it doesn't do very much (or in fact, anything at
all).

This object with null functionality is what is called a null object. We can
create the object the usual way, using the C<new()> constructor, and call any
method on it, and all methods will do the same - nothing. (Actually, it
always returns the same C<Class::Null> singleton object, enabling method
chaining.) It's effectively a catch-all object. We can use this class with our
own object like this:

  package MyObject;

  use Class::Null;

  # some class constructor and accessor declaration here

  sub init {
    my $self = shift;
    ...
    $self->log(Class::Null->new);
    ...
  }

  sub do_it {
    my $self = shift;
    $self->log->log(level => 'debug', message => 'starting to do it');
    ...
    $self->log->log(level => 'debug', message => 'still doing it');
    ...
    $self->log->log(level => 'debug', message => 'finished doing it');
  }

This is only one example of using a null class, but it can be used whenever
you want to make an optional helper object into a mandatory helper object,
thereby avoiding unnecessarily complicated checks and preserving the
transparency of how your objects are related to each other and how they
call each other.

Although C<Class::Null> is exceedingly simple it has been made into a
distribution and put on CPAN to avoid further clutter and repetitive
definitions.

=head1 METHODS

=head2 new

Returns the singleton null object.

=head2 Any other method

Returns another singleton null object so method chaining works.

=head1 OVERLOADS

=over 4

=item Boolean context

In boolean context, a null object always evaluates to false.

=item Numeric context

When used as a number, a null object always evaluates to 0.

=item String context

When stringified, a null object always evaluates to the empty string.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Null>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Class-Null/>.

The development version lives at L<http://github.com/hanekomu/Class-Null>
and may be cloned from L<git://github.com/hanekomu/Class-Null.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

