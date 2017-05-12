package AnyEvent::Digest;

use strict;
use warnings;

# ABSTRACT: A tiny AnyEvent wrapper for Digest::*
our $VERSION = 'v0.0.5'; # VERSION

use Carp;
use AnyEvent;
use Scalar::Util qw(refaddr);

my $AIO_DISABLED;
eval 'use AnyEvent::AIO';
$AIO_DISABLED = 1 if $@;
eval 'use IO::AIO';
$AIO_DISABLED = 1 if $@;

# Most methods are falled back to Digest
our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    my $called = $AUTOLOAD;
    $called =~ s/.*:://;
    croak "AnyEvent::Digest: Unknown method `$called' is called for `".ref($self->{base})."'" unless $self->{base}->can($called);
    $self->{base}->$called(@_);
}

sub DESTROY {}

sub _by_idle
{
    my ($self, $cv, $work) = @_;
    my $call; $call = sub {
        if($work->()) {
            my $w; $w = AE::idle sub {
                undef $w;
                $call->();
            };
        } else {
            undef $call;
            $cv->send($self);
        }
    };
    $call->();
}

sub _file_by_idle
{
    my ($self, $cv, $fh, $work) = @_;
    $self->_by_idle($cv, sub {
        my $ret = read $fh, my $dat, $self->{unit};
        return $cv->croak("AnyEvent::Digest: Read error occurs") unless defined($ret);
        return $work->($dat);
    });
}

sub _file_by_aio
{
    my ($self, $cv, $fh, $work) = @_;
#    my $size = 0;
    my $call; $call = sub {
        my $dat = ''; # If not initialized, "Use of uninitialized value in subroutine entry" issued.
        IO::AIO::aio_read($fh, undef, $self->{unit}, $dat, 0, sub {
            return $cv->croak("AnyEvent::Digest: Read error occurs") if $_[0] < 0;
#            $size += $_[0];
            if($work->($dat)) {
#print STDERR "0: $size $_[0] ",length($dat),"\n";
                $call->();
            } else {
#print STDERR "1: $size $_[0] ",length($dat),"\n";
                undef $call;
                $cv->send($self);
            }
        });
    };
    $call->();
}

my %dispatch = (
    idle => \&_file_by_idle,
    aio => \&_file_by_aio,
);

sub _dispatch
{
    my $method = $dispatch{$_[0]->{backend}};
    croak "AnyEvent::Digest: Unknown backend `$_[0]->{backend}' is specified" unless defined $method;
    return $method->(@_);
}

sub new
{
    my ($class, $base, %args) = @_;
    $class = ref $class || $class;
    $args{unit} ||= 65536;
    $args{backend} = 'idle' unless defined $args{backend};
    croak "AnyEvent::Digest: `aio' backend requires `IO::AIO' and `AnyEvent::AIO'" if $args{backend} eq 'aio' && $AIO_DISABLED;
    croak "AnyEvent::Digest: Unknown backend `$args{backend}' is specified" unless exists $dispatch{$args{backend}};
    eval "require $base" or croak "AnyEvent::Digest: Unknown base digest module `$base' is specified";
    return bless {
        base => $base->new(@{$args{opts}}),
        map { $_, $args{$_} } qw(backend unit),
    }, $class;
}

sub add_async
{
    my $self = shift;
    my $cv = AE::cv;
    my (@dat) = @_;
    $self->_by_idle($cv, sub {
        my $dat = shift @dat;
        $self->{base}->add($dat);
        return scalar @dat;
    });
    return $cv;
}

sub addfile_async
{
    my ($self, $target, $mode) = @_;
    my $cv = AE::cv;
    my $fh;
    if(ref $target) {
        $fh = $target;
    } else {
        open $fh, '<:raw', $target or croak "AnyEvent::Digest: Open error occurs for `$target'";
    }
    $self->_dispatch($cv, $fh, sub {
        my $dat = shift;
        if(! length $dat) {
            close $fh;
            return;
        }
        $self->{base}->add($dat);
    });
    return $cv;
}

sub addfile
{
    return shift->addfile_async(@_)->recv;
}

sub addfile_base
{
    return shift->{base}->addfile(@_);
}

sub add_bits_async
{
    my $self = shift;
    my $cv = AE::cv;
    $self->{base}->add_bits(@_);
    $cv->send($self);
    return $cv;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Digest - A tiny AnyEvent wrapper for Digest::*

=head1 VERSION

version v0.0.5

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Digest;
  my $ctx = AnyEvent::Digest->new('Digest::SHA', opts => [1], unit => 65536, backend => 'aio');
  # In addition to that $ctx can be used as Digest::* object, you can call add*_async() methods
  $ctx->addfile_async($file)->cb(sub {
    # Do something like the followings
    my $ctx = shift->recv;
    print $ctx->hexdigest,"\n";
  });
  AE::cv->recv; # Wait

=head1 DESCRIPTION

To calculate message digest for large files may take several seconds.
It may block your program even if you use L<AnyEvent>.
This module is a tiny L<AnyEvent> wrapper for C<Digest::*> modules,
not to block your program during digest calculation.

Default backend is to use C<AnyEvent::idle>.
You can choose L<IO::AIO> backend. You need install L<IO::AIO> and L<AnyEvent::AIO> for L<IO::AIO> backend.

=head1 METHODS

In addition to the following methods, other methods are forwarded to the base module.
So, you can use an object of this module as if it is an object of base module.
However, C<addfile()> calls C<recv()> internally so that L<AnyEvent> backend you use SHOULD supprot blocking wait.
If you want to avoid blocking wait, you can use C<addfile_base()> instead.

=head2 C<new($base, %args)>

This is a constructor method.
C<$base> specifies a module name for base digest implementation, which is expected to be one of C<Digest::*> modules.
C<'require'> is called for the base module, so you don't have to do C<'require'> explicitly.

Available keys of C<%args> are as follows:

=over 4

=item C<opts>

passed to C<$base::new> as C<@{$args{opts}}>. It MUST be an array reference.

=item C<unit>

specifies an amount of read unit for addfile(). Default to 65536 = 64KiB.

=item C<backend>

specifies a backend module to handle asynchronous read. Available backends are C<'idle'> and C<'aio'>. Default to C<'idle'>.

=back

=head2 C<add_async(@dat)>

Each item in C<@dat> are added by C<add($dat)>.
Between the adjacent C<add()>, other L<AnyEvent> watchers have chances to run.
It returns a condition variable receiving this object itself.

=head2 C<addfile_async($filename)>

=head2 C<addfile_async(*handle)>

C<add()> is called repeatedly read from C<$filename> or C<*handle> by the specified unit.
Between the adjacent C<add()>, other L<AnyEvent> watchers have chances to run.
It returns a condition variable receiving this object itself.

=head2 C<add_bits_async()>

Same as C<add_bits()>, except it returns a condition variable receiving this object itself.

B<CAUTION:> Currerntly, other L<AnyEvent> watchers have B<NO> chance to run during this call.

=head2 C<addfile()>

This method uses blocking wait + C<addfile_async()>.

=head2 C<addfile_base()>

Forwarded to C<addfile()> in the base module. If you need to avoid blocking wait somewhere, this might be helpful.
However, during the call, other L<AnyEvent> watchers  are blocked.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent>

=item *

L<AnyEvent::AIO>

=item *

L<IO::AIO>

=item *

L<Digest>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
