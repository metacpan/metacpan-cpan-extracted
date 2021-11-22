package Log::Dispatch::File;

use strict;
use warnings;

our $VERSION = '2.70';

use IO::Handle;
use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( openhandle );

use base qw( Log::Dispatch::Output );

# Prevents death later on if IO::File can't export this constant.
*O_APPEND = \&APPEND unless defined &O_APPEND;

sub APPEND {0}

{
    my $validator = validation_for(
        params => {
            filename => { type => t('NonEmptyStr') },
            mode     => {
                type    => t('Value'),
                default => '>',
            },
            binmode => {
                type     => t('Str'),
                optional => 1,
            },
            autoflush => {
                type    => t('Bool'),
                default => 1,
            },
            close_after_write => {
                type    => t('Bool'),
                default => 0,
            },
            lazy_open => {
                type    => t('Bool'),
                default => 0,
            },
            permissions => {
                type     => t('PositiveOrZeroInt'),
                optional => 1,
            },
            syswrite => {
                type    => t('Bool'),
                default => 0,
            },
        },
        slurpy => 1,
    );

    # We stick these in $self as-is without looking at them in new().
    my @self_p = qw(
        autoflush
        binmode
        close_after_write
        filename
        lazy_open
        permissions
        syswrite
    );

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless { map { $_ => delete $p{$_} } @self_p }, $class;

        if ( $self->{close_after_write} ) {
            $self->{mode} = '>>';
        }
        elsif (
            $p{mode} =~ /^(?:>>|append)$/
            || (   $p{mode} =~ /^\d+$/
                && $p{mode} == O_APPEND() )
        ) {
            $self->{mode} = '>>';
        }
        else {
            $self->{mode} = '>';
        }
        delete $p{mode};

        $self->_basic_init(%p);
        $self->_open_file()
            unless $self->{close_after_write} || $self->{lazy_open};

        return $self;
    }
}

sub _open_file {
    my $self = shift;

    ## no critic (InputOutput::RequireBriefOpen)
    open my $fh, $self->{mode}, $self->{filename}
        or die "Cannot write to '$self->{filename}': $!";

    if ( $self->{autoflush} ) {
        $fh->autoflush(1);
    }

    if ( $self->{permissions}
        && !$self->{chmodded} ) {
        ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
        my $current_mode = ( stat $self->{filename} )[2] & 07777;
        if ( $current_mode ne $self->{permissions} ) {
            chmod $self->{permissions}, $self->{filename}
                or die sprintf(
                'Cannot chmod %s to %04o: %s',
                $self->{filename}, $self->{permissions} & 07777, $!
                );
        }

        $self->{chmodded} = 1;
    }

    if ( $self->{binmode} ) {
        binmode $fh, $self->{binmode}
            or die "Cannot set binmode on filehandle: $!";
    }

    $self->{fh} = $fh;
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    if ( $self->{close_after_write} ) {
        $self->_open_file;
    }
    elsif ( $self->{lazy_open} ) {
        $self->_open_file;
        $self->{lazy_open} = 0;
    }

    my $fh = $self->{fh};

    if ( $self->{syswrite} ) {
        defined syswrite( $fh, $p{message} )
            or die "Cannot write to '$self->{filename}': $!";
    }
    else {
        print $fh $p{message}
            or die "Cannot write to '$self->{filename}': $!";
    }

    if ( $self->{close_after_write} ) {
        close $fh
            or die "Cannot close '$self->{filename}': $!";
        delete $self->{fh};
    }
}

sub DESTROY {
    my $self = shift;

    if ( $self->{fh} ) {
        my $fh = $self->{fh};
        ## no critic (InputOutput::RequireCheckedSyscalls)
        close $fh if openhandle($fh);
    }
}

1;

# ABSTRACT: Object for logging to files

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::File - Object for logging to files

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'File',
              min_level => 'info',
              filename  => 'Somefile.log',
              mode      => '>>',
              newline   => 1
          ]
      ],
  );

  $log->emerg("I've fallen and I can't get up");

=head1 DESCRIPTION

This module provides a simple object for logging to files under the
Log::Dispatch::* system.

Note that a newline will I<not> be added automatically at the end of a message
by default. To do that, pass C<< newline => 1 >>.

B<NOTE:> If you are writing to a single log file from multiple processes, the
log output may become interleaved and garbled. Use the
L<Log::Dispatch::File::Locked> output instead, which allows multiple processes
to safely share a single file.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * filename ($)

The filename to be opened for writing.

=item * mode ($)

The mode the file should be opened with. Valid options are 'write',
'>', 'append', '>>', or the relevant constants from Fcntl. The
default is 'write'.

=item * binmode ($)

A layer name to be passed to binmode, like ":encoding(UTF-8)" or ":raw".

=item * close_after_write ($)

Whether or not the file should be closed after each write. This
defaults to false.

If this is true, then the mode will always be append, so that the file is not
re-written for each new message.

=item * lazy_open ($)

Whether or not the file should be opened only on first write. This defaults to
false.

=item * autoflush ($)

Whether or not the file should be autoflushed. This defaults to true.

=item * syswrite ($)

Whether or not to perform the write using L<perlfunc/syswrite>(),
as opposed to L<perlfunc/print>(). This defaults to false.
The usual caveats and warnings as documented in L<perlfunc/syswrite> apply.

=item * permissions ($)

If the file does not already exist, the permissions that it should
be created with. Optional. The argument passed must be a valid
octal value, such as 0600 or the constants available from Fcntl, like
S_IRUSR|S_IWUSR.

See L<perlfunc/chmod> for more on potential traps when passing octal
values around. Most importantly, remember that if you pass a string
that looks like an octal value, like this:

 my $mode = '0644';

Then the resulting file will end up with permissions like this:

 --w----r-T

which is probably not what you want.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
