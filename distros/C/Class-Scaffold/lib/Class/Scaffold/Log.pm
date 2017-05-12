use 5.008;
use warnings;
use strict;

package Class::Scaffold::Log;
BEGIN {
  $Class::Scaffold::Log::VERSION = '1.102280';
}
# ABSTRACT: Logging utilities
use Carp;
use IO::File;
use Time::HiRes 'gettimeofday';
use parent 'Class::Scaffold::Base';
__PACKAGE__->mk_singleton(qw(instance))
  ->mk_scalar_accessors(qw(filename max_level))
  ->mk_boolean_accessors(qw(pid timestamp))->mk_concat_accessors(qw(output));
use constant DEFAULTS => (max_level => 1,);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->clear_pid;
    $self->set_timestamp;
}

sub precdate {
    my @hires = gettimeofday;
    return sub {
        sprintf "%04d%02d%02d.%02d%02d%02d",
          $_[5] + 1900, $_[4] + 1, @_[ 3, 2, 1, 0 ];
      }
      ->(localtime($hires[0])) . (@_ ? sprintf(".%06d", $hires[1]) : "");
}
sub logdate { substr(precdate(1), 0, 18) }

# like get_set_std, but also generate handle from filename unless defined
sub handle {
    my $self = shift;
    $self = Class::Scaffold::Log->instance unless ref $self;

    # in test mode, ignore what we're given - always log to STDOUT.
    if ($self->delegate->test_mode) {
        return $self->{handle} ||= IO::File->new(">&STDOUT")
          or die "can't open STDOUT: $!\n";
    }
    if (@_) {
        $self->{handle} = shift;
    } else {
        if ($self->filename) {
            $self->{handle} ||= IO::File->new(sprintf(">>%s", $self->filename))
              or die sprintf("can't append to %s: %s\n", $self->filename, $!);
        } else {
            $self->{handle} ||= IO::File->new(">&STDERR")
              or die "can't open STDERR: $!\n";
        }
        $self->{handle}->autoflush(1);
        return $self->{handle};
    }
}

# called like printf
sub __log {
    my ($self, $level, $format, @args) = @_;
    $self = Class::Scaffold::Log->instance unless ref $self;

    # Check for max_level before stringifying $format so we don't
    # unnecessarily trigger a potentially lazy string.
    return if $level > $self->max_level;

    # in case someone passes us an object that needs to be stringified so we
    # can compare it with 'ne' further down (e.g., an exception object):
    $format = "$format";
    return unless defined $format and $format ne '';

    # make sure there's exactly one newline at the end
    1 while chomp $format;
    $format .= "\n";
    $format = sprintf "(%08d) %s", $$, $format if $self->pid;
    $format = sprintf "%s %s", $self->logdate, $format if $self->timestamp;
    my $msg = sprintf $format => @args;

    # Open and close the file for each line that is logged. That doesn't cost
    # much and makes it possible to move the file away for backup, rotation
    # or whatver.
    my $fh;
    if ($self->delegate->test_mode) {
        print $msg;
    } elsif (defined($self->filename) && length($self->filename)) {
        open $fh, '>>', $self->filename
          or die sprintf "can't open %s for appending: %s", $self->filename, $!;
        print $fh $msg
          or die sprintf "can't print to %s: %s", $self->filename, $!;
        close $fh
          or die sprintf "can't close %s: %s", $self->filename, $!;
    } else {
        warn $msg;
    }
    $self->output($msg);
}

sub info {
    my $self = shift;
    $self->__log(1, @_);
}

sub debug {
    my $self = shift;
    $self->__log(2, @_);
}

sub deep_debug {
    my $self = shift;
    $self->__log(3, @_);
}

# log a final message, close the log and croak.
sub fatal {
    my ($self, $format, @args) = @_;
    my $message = sprintf($format, @args);
    $self->info($message);
    croak($message);
}
1;


__END__
=pod

=for stopwords logdate precdate

=head1 NAME

Class::Scaffold::Log - Logging utilities

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 debug

FIXME

=head2 deep_debug

FIXME

=head2 fatal

FIXME

=head2 handle

FIXME

=head2 info

FIXME

=head2 logdate

FIXME

=head2 precdate

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

