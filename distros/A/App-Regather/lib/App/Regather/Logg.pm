# -*- mode: cperl; mode: follow; -*-
#

package App::Regather::Logg;

use strict;
use warnings;
use diagnostics;
use Sys::Syslog qw(:standard :macros);
use Mail::Send;
use Sys::Hostname;
use Data::Printer caller_info => 1, class => { expand => 2 };

# https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
use constant dpc => { info    => 'ansi113',
		      err     => 'bold ansi255 on_ansi196',
		      debug   => 'ansi195', #grey18', #bright_yellow',
#		      warning => 'bold ansi237 on_ansi214', #bright_yellow',
		      warning => 'ansi214', #bright_yellow',
		    };

=pod

=encoding UTF-8

=head1 NAME

App::Regather::Logg - logging class

=head1 SYNOPSIS

    use App::Regather::Logg;
    my $log = new App::Regather::Logg( prognam    => 'MyAppName',
			          foreground => $foreground_or_syslog,
			          colors     => $wheather_to_use_term_colors );
    $log->cc( pr => 'info', fm => "App::Regather::Logg initialized ... (write to syslog)" );
    $log->cc( fg => 1, fm => "App::Regather::Logg initialized ... (write to STDOUT)" );
    ...
    my $mesg = $ldap->search( filter => "(objectClass=unsearchebleThing)");
    $log->logg_ldap_err( mesg => $mesg );

=head1 DESCRIPTION

This is a class to log messages.

=head1 CONSTRUCTOR

=over 4

=item B<new>

Creates a new B<App::Regather::Logg> object

=over 4

=item prognam =E<gt> 'MyAppName'

program name

=item foreground =E<gt> 1 | 0

STDOUT or syslog, default is: 0

=item colors =E<gt> 1 | 0

wheather to use terminal colors, default is: 0

if set, then priorities are colored this way:

=over 4

info    => 'ansi113'

err     => 'bold ansi255 on_ansi196'
debug   => 'ansi195'

warning => 'bold ansi237 on_ansi214'

=back

for reference look at L<Term::ANSIColor>

=item ts_fmt =E<gt> 'strftime(3) format string'

timestamp format string, default is: "%a %F %T %Z (%z)"

=back

=back

=cut

sub new {
  my ( $self, %args ) = @_;

  $args{colors}     = $args{colors}     // 0;
  $args{foreground} = $args{foreground} // 0;
  $args{prognam}    = $args{prognam}    // lc( (split(/:/, __PACKAGE__))[0] );
  $args{tsargsfmt}  = '%a %F %T %Z (%z)';

  eval { $args{hostname} = hostname };
  $args{hostname} = 'HOSTNAME_NOT_AVAILABLE' if $@;

  openlog($args{prognam}, "ndelay,pid") if ! $args{foreground};

  bless { %args }, $self;
}

sub colors     { shift->{colors} }
sub foreground { shift->{foreground} }
sub host_name  { shift->{hostname} }
sub prognam    { shift->{prognam} }
sub ts_fmt     { shift->{ts_fmt} }

=head1 METHODS

=over 4

=item B<conclude>

main method to do the job

=over 4

=item fg =E<gt> 1 | 0

foreground: stdin or syslog

=item pr =E<gt> 'level[|facility]'

priority

=item fm =E<gt> "... %s ... : %m"

sprintf format string, with the addition that %m is replaced with "$!"

=item ls =E<gt> [ $a, $b, ... ]

list of values to be passed to sprintf as arguments

=item nt =E<gt> 1 | 0

wheather to send (notify) you this message with I<notify> method

=back

=cut

sub conclude {
  my ( $self, %args ) = @_;
  my %arg = ( fg => $args{fg} // $self->{foreground},
	      pr => $args{pr} // 'info',
	      fm => $args{fm},
	      nt => $args{nt} // 0 );
  $arg{pr_s} = sprintf("%s|%s", $arg{pr}, $self->{facility} // 'local4');
  $arg{pr_f} = sprintf("%s: ", uc($arg{pr}) );

  if ( exists $args{ls} ) {
    @{$arg{ls}} = map { ref && ref ne 'SCALAR' ? np($_, caller_info => 0) : $_ } @{$args{ls}};
  } else {
    $arg{ls} = [];
  }

  $arg{msg} = sprintf $arg{pr_f} . $arg{fm}, @{$arg{ls}};
  if ( $arg{fg} ) {
    p($arg{msg},
      colored     => $self->{colors} && $self->{foreground},
      caller_info => 0,
      color       => { string => dpc->{$arg{pr}}},
      output      => 'stdout' );
  } else {
    syslog( $arg{pr_s}, $arg{pr_f} . $arg{fm}, @{$arg{ls}} );
  }

  $self->notify( msg => $arg{msg} ) if $arg{nt};
}

=item B<cc>

alias for I<conclude> method

=cut

sub cc { goto &conclude }

=item B<conclude_ldap_err>

method - wrapper around Net::LDAP::Message->error methods

=over 4

=item mesg =E<gt> Net::LDAP::Message object

=back

=cut

sub conclude_ldap_err {
  my ( $self, %args ) = @_;
  my %arg = ( mesg => $args{mesg},
	      nt   => $args{nt} // 0 );
  $self->cc( pr => 'err',
	     fm => "LDAP ERROR:\n% 13s%s\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
	     ls => [ 'ERROR: ',        $arg{mesg}->error_name,
		     'TEXT: ',         $arg{mesg}->error_text,
		     'DESCRIPTION: ',  $arg{mesg}->error_desc,
		     'SERVER ERROR: ', $arg{mesg}->server_error ] );

  $self->notify( msg => $arg{mesg}->error_desc ) if $arg{nt};
}

=item B<cc_ldap_err>

alias for I<conclude_ldap_err> method

=cut

sub cc_ldap_err { goto &conclude_ldap_err }

=item B<notify>

method to be used to send log message via email

=cut

sub notify {
  my ( $self, %args ) = @_;
  my $email = Mail::Send->new;
  $email->subject(sprintf("[regather @ %s] %s... (skipped)",
			  $self->{hostname},
			  substr( $args{msg}, 0, 50)));
  $email->to( @{$self->{notify_email}} );
  my $email_body = $email->open;
  print $email_body sprintf("host: %s\n\n", $self->{hostname});
  print $email_body $args{msg};
  $email_body->close ||
    $self->cc( pr => 'err', ls => [ $! ],
	       fm => "email sending error: %s", );
}

=item B<set_m>

setter to set options from config file

on input it expects App::Regather::Config object section for App::Regather::Logg

=cut

sub set_m {
  my ( $self, $cf ) = @_;
  if ( ref($cf) eq 'HASH' ) {
    while ( my ( $k, $v ) = each %$cf ) {
      next if exists $self->{$k};
      $self->{$k} = $v;
    }
  } else {
    $self->cc( pr => 'err',
	       fm => "Logg::set_m(): argument supplied is not HASH ..." );
    return 0;
  }
}

=item B<set>

setter to set one single pair key => value

=over 4

=item key =E<gt> value

=back

=cut

sub set {
  my ( $self, $k, $v ) = @_;
  $self->{$k} = $v;
}

=item B<get>

getter

=back

=cut

sub get {
  my ( $self, $k ) = @_;
  if ( exists $self->{$k} ) {
    $self->{$k};
  } else {
    $self->cc( pr => 'err',
	       fm => "attribute \"%s\" doesn't exist",
	       ls => [ $k ] );
    return;
  }
}

=head1 SEE ALSO

L<Sys::Syslog>,
L<Data::Printer>,
L<Term::ANSIColor>

=head1 AUTHOR

Zeus Panchenko E<lt>zeus@gnu.org.uaE<gt>

=head1 COPYRIGHT

Copyright 2019 Zeus Panchenko.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;

