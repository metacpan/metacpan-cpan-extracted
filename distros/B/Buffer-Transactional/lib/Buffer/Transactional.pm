package Buffer::Transactional;
use Moose;
use Moose::Util::TypeConstraints;

use Buffer::Transactional::Buffer::String;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

has 'out' => (
    is       => 'ro',
    isa      => duck_type( [ 'print' ] ),
    required => 1,
);

has '_buffers' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef[ Buffer::Transactional::Buffer ]',
    lazy    => 1,
    default => sub { [] },
    handles => {
        '_add_buffer'          => 'push',
        'clear_current_buffer' => 'pop',
        'has_current_buffer'   => 'count',
        'current_buffer'       => [ 'get', -1 ]
    }
);

has 'buffer_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    lazy    => 1,
    default => sub { 'Buffer::Transactional::Buffer::String' },
);

sub begin_work {
    my $self = shift;
    $self->_add_buffer( $self->buffer_class->new );
}

sub commit {
    my $self = shift;
    ($self->has_current_buffer)
        || confess "Not within transaction scope";

    my $current = $self->clear_current_buffer;

    if ($self->has_current_buffer) {
        $self->current_buffer->subsume( $current );
    }
    else {
        $self->out->print( $current->as_string );
    }
}

sub rollback {
    my $self = shift;
    ($self->has_current_buffer)
        || confess "Not within transaction scope";
    $self->clear_current_buffer;
}

sub _write_to_buffer {
    my $self = shift;
    ($self->has_current_buffer)
        || confess "Not within transaction scope";
    $self->current_buffer->put( @_ );
}

sub print {
    my ($self, @data) = @_;
    $self->_write_to_buffer( @data );
}

sub txn_do {
    my ($self, $body) = @_;
    $self->begin_work;
    $body->();
    $self->commit;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Buffer::Transactional - A transactional buffer for writing data

=head1 SYNOPSIS

  use IO::File;
  use Try::Tiny;
  use Buffer::Transactional;

  my $b = Buffer::Transactional->new( out => IO::File->new('my_novel.txt', 'w') );
  try {
      $b->begin_work;
      $b->print('It was the best of times, it was the worst of times ...');
      # ...
      die "Whoops!";
      # ...
      $b->commit;
  } catch {
      $b->rollback;
      warn "Transaction aborted because : $_";
  };

=head1 DESCRIPTION

Allow me to take you on a journey, into the distant past ...

So a year or so ago I got really into the O'Caml language and in exploring
the available libraries I stumbled onto OCamlnet. Ocamlnet is basically an
all things internet related module for O'Caml. Of particular interest to me
was their CGI module and one nice feature jumped out at me, which was the
fact they used a transactional buffer to print the output of the CGI. Now,
in a Modern Perl world few people probably call C<print> inside a CGI script
anymore, but instead use templating systems and the like. However I still
thought that a nice transactional buffer would be useful for other things
such as in the internals of such a templating system or the bowels of a web
framework.

Fast forward to 2009 ... and here you have it! We support several different
kind of buffer types as well as nested transactions. As this is the first
release, no doubt there is much room for improvement so feel free to suggest
away.

Use only as directed, be sure to check with your doctor to make sure
your healthy enough for transactional activity. If your transaction lasts
for more then 4 hours, consult a physician immediately.

=head1 ATTRIBUTES

=over 4

=item B<out>

This is an object which responds to the method C<print>, most often
it will be some kind of L<IO::File>, L<IO::String> or L<IO::Scalar>
varient. This attribute is required.

=item B<buffer_class>

This is a class name for the buffer subclass you wish to use, it
currently defaults to L<Buffer::Transactional::Buffer::String>.

=back

=head1 METHODS

=over 4

=item B<begin_work>

Declares the start of a transaction.

=item B<commit>

Commits the current transaction.

=item B<rollback>

Rollsback the current transaction.

=item B<print ( @strings )>

Print to the current buffer.

=item B<txn_do ( \&body )>

This is a convience wrapper around the C<begin_work> and C<commit>
methods. It takes a CODE ref and will execute it within the context
of a transaction. It does B<not> attempt to handle exceptions,
rollbacks or anything of the like, it simply wraps the transaction.

=back

=head1 SEE ALSO

OCamlnet - L<http://projects.camlcity.org/projects/ocamlnet.html>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
