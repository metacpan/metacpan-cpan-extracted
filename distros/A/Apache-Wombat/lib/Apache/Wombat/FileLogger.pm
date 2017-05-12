# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat::FileLogger;

=pod

=head1 NAME

Apache::Wombat::FileLogger - Apache file logger class

=head1 SYNOPSIS

  my $logger = Apache::Wombat::FileLogger->new();
  $logger->setFileName("/var/log/wombat/wombat.log");
  $logger->log("this will show up in the log file");

=head1 DESCRIPTION

Logger class that uses B<Apache::LogFile> to write to a log file.

=cut

use base qw(Wombat::Logger::LoggerBase);
use fields qw(fh filename);
use strict;
use warnings;

use Apache::LogFile ();
use Wombat::Exception ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Logger::FileLogger> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{fh} = undef;
    $self->{filename} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getFilename()

Return the name of the file that is the log destination.

=cut

sub getFilename {
    my $self = shift;

    return $self->{filename};
}

=pod

=item setFilename($filename)

Set the name of the file that is the log destination.

B<Parameters:>

=over

=item $filename

the name of the file

=back

=cut

sub setFilename {
    my $self = shift;
    my $filename = shift;

    $self->{filename} = $filename;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item write($string)

Write the specified string to the log destination. The default
implementation does nothing. Subclasses must override this method.

B<Parameters:>

=over

=item $string

the string to write to the log destination

=back

=cut

sub write {
    my $self = shift;

    $self->{fh}->print("[$$] ", @_);

    return 1;
}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for the beginning of active use of this Logger by opening the
file.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the file cannot be opened

=back

=cut

sub start {
    my $self = shift;

    $self->SUPER::start();

    # ungh dum
    undef $self->{started};

    $self->{fh} = Apache::LogFile->new($self->{filename}) or do {
        my $msg = "cannot open $self->{filename}";
        throw Wombat::LifecycleException->new($msg, $!);
    };

    $self->{started} = 1;

    return 1;
}

=pod

=item stop()

Gracefully terminate the active use of this Logger by closing the
file.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the file cannot be closed

=back

=cut

#  sub stop {
#      my $self = shift;

#      $self->SUPER::stop();

#      $self->{fh}->close or do {
#          my $msg = "cannot close $self->{filename}";
#          throw Wombat::LifecycleException->new($msg, $!);
#      };

#      return 1;
#  }

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Apache::LogFile>,
L<Servlet::Util::Exception>,
L<Wombat::Logger::LoggerBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
