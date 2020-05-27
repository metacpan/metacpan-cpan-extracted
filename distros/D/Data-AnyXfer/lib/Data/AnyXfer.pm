package Data::AnyXfer;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use File::Temp qw/ tempdir /;
use Clone qw/ clone /;
use Path::Class qw( dir );

use Data::AnyXfer::Log4perl qw/ get_logger /;

our $VERSION = '0.1';

=head1 NAME

Data::AnyXfer - data transfer base class

=head1 DESCRIPTION

This is a base class for data transfers. It does nothing on it's own
except log calls to methods for tracing.

=head1 ATTRIBUTES

=head2 C<callback>

This is an optional callback on the hashref returned by
L</transform>. It should be a subroutine that takes a
L<Data::AnyXfer> object and a hash reference as
arguments, e.g.

  use Intranet::MGReports::Import::Lettings;

  sub debug {
    my ( $import, $data ) = @_;
    $import->log->debug( Dumper($data) );
    return 1;
  }

  my $import = Intranet::MGReports::Import:Lettings->new(
     callback => \&debug,    #
  );

If the callback returns a false value, then the run will stop.

Note that the callback is passed a copy of the record, and any
modifications will not be saved.

Generally this will only be used for testing and debugging.

=cut

has 'callback' => (
    is  => 'ro',
    isa => Maybe[CodeRef],
);

=head2 C<log>

This is an optional L<Log::Log4perl::Logger> object.  It defaults to
the logger returned by L<Core::Log4perl>, and can be used
for logging events during a script, e.g.

  $self->log->warn("Fnorjd!");

=cut

has 'log' => (
    is      => 'ro',
    isa     => InstanceOf['Log::Log4perl::Logger'],
    lazy    => 1,
    default => sub { get_logger() },
);

=head1 METHODS

=head2 test

  Data::AnyXfer->test(1);

Sets or retreives the testing flag to trigger different behaviour.

=cut

my $DATA_ANYXFER_TEST = 0;

sub test {
  my ($self, $value) = @_;

  return defined $value ? $DATA_ANYXFER_TEST = $value : $DATA_ANYXFER_TEST;
}

=head2 tmp_dir

    my $tmp_dir = Data::AnyXfer->tmp_dir;
    say $tmp_dir; # --> /tmp/tmp_dir-user-pid-random_chars

Or...

    my $tmp_dir = Data::AnyXfer->tmp_dir({
      name    => 'my-project',
      cleanup => 0,  # don't delete dir
    });
    say $tmp_dir' # --> /tmp/my-project-user-pid-random_chars

Returns a L<Path::Class::Dir> object representing a recently created
directory. The directory will have the user and pid embedded in it and will
be deleted when the program exits, unless 'cleanup' argument set to false
or the C<TMP_NO_CLEANUP> environment variable is set to true.

=cut

sub tmp_dir {
    my ( $class, $args ) = @_;

    $args->{name} ||= 'tmp_dir';
    $args->{cleanup} = 1 unless defined $args->{cleanup};
    $args->{cleanup} = 0 if $ENV{TMP_NO_CLEANUP};
    my $template = sprintf( "%s-%s-%s-XXXXXX", $args->{name}, $ENV{USER}, $$ );

    my $tmp = tempdir( $template, CLEANUP => $args->{cleanup}, TMPDIR => 1, );
    return dir($tmp);
}

=head2 C<run>

  $self->run();

This method populates the data needed to run reports, by doing the following:

It runs the L</initialize> method. If that returns false value, it
stops. Otherwise, it calls the L</fetch_next> method until it returns
false.

If L</fetch_next> returns an object, then it calls the L</transform>
method on that object, expecting a hashref in return.

If there is a L</callback> defined, that is called with the hashref.

If the hashref is defined and has keys, then it calls the L</store>
method to save the data.

=cut

sub run {
    my ($self) = @_;
    my $log = $self->log;

    if ( $self->initialize ) {

        my $cb = $self->callback;
        while ( my $res = $self->fetch_next ) {

            if ( my $rec = $self->transform($res) ) {

                $self->store($rec)
                    or $log->logdie("store failed");

                if ( $cb && !$cb->( $self, clone $rec ) ) {
                    $log->trace("callback returned false")
                      if $log->is_trace;
                    last;
                }
            }
        }
        $self->finalize;
    } else {
        $log->trace("initialize returned false")
          if $log->is_trace;
    }
    return 1;
}

=head2 C<initialize>

  if ($self->initialize) { ... }

This method initializes the system for the data transfer. This may
involve opening files, connecting to databases, initialising objects,
etc.

It returns false on failure. Any wrappers around this method should
check for false in the original method before continuing, e.g.

  around 'initialize' => sub {
    my ($orig, $self) = @_;
    $self->$orig() or return;

    ...
  };


=cut

sub initialize {
    my ($self) = @_;
    my $log = $self->log;
    $log->trace( ( caller(0) )[3] =~ m/::(\w+)$/ ) if $log->is_trace;
    return 1;
}

=head2 C<fetch_next>

  while (my $res = $self->fetch_next) { ... }

This method provides an iterator for the data source.  It should
return an object that can be processed by the L</transform> method, or
C<undef> when there is no more data.

An example iterator for a L<DBIx::Class::ResultSet> might be

  around 'fetch_next' => sub {
    my ( $orig, $self ) = @_;
    $self->$orig or return;
    $self->rs->next;
  };

=cut

sub fetch_next {
    my ($self) = @_;
    my $log = $self->log;
    $log->trace( ( caller(0) )[3] =~ m/::(\w+)$/ ) if $log->is_trace;
    return 1;
}

=head2 C<transform>

  my $rec = $self->transform($res);

This method should transform the object returns by L</fetch_next> into a
hash reference.

The transform method should return either a hash reference, or
C<undef>.

If C<undef> is returned, the L</store> and L</callback> methods will
not be called.

=cut

sub transform {
    my ($self) = @_;
    my $log = $self->log;
    $log->trace( ( caller(0) )[3] =~ m/::(\w+)$/ ) if $log->is_trace;
    return {};
}

=head2 C<store>

  $self->store($rec);

This method stores the record returned by L</transform>.  It returns a
false value on failure.

=cut

sub store {
    my ( $self, $rec ) = @_;
    my $log = $self->log;
    $log->trace( ( caller(0) )[3] =~ m/::(\w+)$/ ) if $log->is_trace;
    return 1;
}

=head2 C<finalize>

  $self->finalize();

This method finalizes any data after all records have been saved. It
returns a false value on faulure.

=cut

sub finalize {
    my ($self) = @_;
    my $log = $self->log;
    $log->trace( ( caller(0) )[3] =~ m/::(\w+)$/ ) if $log->is_trace;
    return 1;
}

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
