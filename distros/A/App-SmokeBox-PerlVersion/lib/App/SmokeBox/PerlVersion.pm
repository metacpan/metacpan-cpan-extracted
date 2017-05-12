package App::SmokeBox::PerlVersion;
{
  $App::SmokeBox::PerlVersion::VERSION = '0.16';
}

#ABSTRACT: SmokeBox helper module to determine perl version

use strict;
use warnings;
use IPC::Cmd qw[can_run];
use POE qw[Wheel::Run];

sub version {
  my $package = shift;
  my %args    = @_;
  $args{ lc $_ } = delete $args{$_} for keys %args;
  $args{perl} = $^X unless $args{perl} and can_run( $args{perl} );

  SWITCH: {
    unless ( $args{session} ) {
      my $session = $poe_kernel->get_active_session();
      if ( $session == $poe_kernel ) {
        warn "Not called from another POE session and 'session' wasn't set\n";
        return;
      }
      $args{session} = $session->ID();
      last SWITCH;
    }
    if ( $args{session} and !$args{session}->isa('POE::Session::AnonEvent') ) {
      if ( my $session = $poe_kernel->alias_resolve( $args{session} ) ) {
        $args{session} = $session->ID();
        last SWITCH;
      }
      else {
        warn "Could not resolve 'session' to a valid POE Session\n";
        return;
      }
    }
  }

  unless ( $args{event} or $args{session}->isa('POE::Session::AnonEvent') ) {
     warn "You must provide response 'event' or a postback in 'session'\n";
     return;
  }

  my $self = bless \%args, $package;
  $self->{session_id} = POE::Session->create(
     object_states => [
        $self => [
            qw(_start _stdout _finished)
        ],
     ],
     heap => $self,
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $kernel->refcount_increment( $self->{session}, __PACKAGE__ )
    unless ref $self->{session} and $self->{session}->isa('POE::Session::AnonEvent');
  $self->{child} = POE::Wheel::Run->new(
    Program     => [ $self->{perl}, '-V:version', '-V:archname', '-V:osvers' ],
    StdoutEvent => '_stdout',
  );
  $self->{pid} = $self->{child}->PID;
  $kernel->sig_child( $self->{pid}, '_finished' );
  return;
}

sub _stdout {
  my ($self,$in,$pid) = @_[OBJECT,ARG0,ARG1];
  return unless my ($var,$value) = $in =~ m!^(version|archname|osvers)\s*\=\s*'(.+?)'!;
  $self->{$var} = $value;
  return;
}

sub _finished {
  my ($kernel,$self,$pid,$code) = @_[KERNEL,OBJECT,ARG1,ARG2];
  delete $self->{child};
  delete $self->{pid};
  my $return = { };
  $return->{exitcode} = $code;
  $return->{$_} = $self->{$_} for qw[version archname osvers context];
  if ( ref $self->{session} and $self->{session}->isa('POE::Session::AnonEvent') ) {
    $self->{session}->( $return );
  }
  else {
    $kernel->post( $self->{session}, $self->{event}, $return );
    $kernel->refcount_decrement( $self->{session}, __PACKAGE__ );
  }
  return;
}

q[This is true];

__END__

=pod

=head1 NAME

App::SmokeBox::PerlVersion - SmokeBox helper module to determine perl version

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE;
  use App::SmokeBox::PerlVersion;

  my $perl = shift || $^X;

  POE::Session->create(
    package_states => [
      main => [qw(_start _result)],
    ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    App::SmokeBox::PerlVersion->version(
      perl => $perl,
      event => '_result',
    );
    return;
  }

  sub _result {
    my $href = $_[ARG0];
    print "Perl version: ", $href->{version}, "\n";
    print "Built for:    ", $href->{archname}, "\n";
    print "OS Version:   ", $href->{osvers}, "\n";
    return;
  }

=head1 DESCRIPTION

App::SmokeBox::PerlVersion is a simple helper module for L<App::SmokeBox::Mini> and
L<minismokebox> that determines version, architecture and OS version of a given C<perl>
executable.

=head1 CONSTRUCTOR

=over

=item C<version>

Takes a number of arguments:

  'perl', the perl executable to query, defaults to $^X;
  'event', the event to trigger in the calling session on finish;
  'session', a POE Session, ID, alias or postback to send results to;
  'context', optional context data you want to provide;

C<event> is a mandatory argument unless C<session> is provided and is a L<POE> postback/callback.

=back

=head1 RESPONSE

An C<event> or C<postback> will be sent when the module has finished with a hashref of data.

For C<event> the hashref will be in C<ARG0>.

For C<postback> the hashref will be the first item in the arrayref of C<ARG1> in the C<postback>.

The hashref will contain the following keys:

  'exitcode', the exit code of the perl executable that was run;
  'version', the perl version string;
  'archname', the perl archname string;
  'osvers', the OS version string;
  'context', whatever was passed to version();

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
