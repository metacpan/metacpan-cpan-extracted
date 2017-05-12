package Backup::Omni::Session::Messages;

our $VERSION = '0.01';

use Params::Validate ':all';

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Backup::Omni::Base',
  constants => 'OMNIDB',
  mutators  => 'cur_pos',
  constant => {
      COMMAND => '%s -session %s -report %s',
  },
  vars => {
      PARAMS => {
          -session => 1,
          -report  => { optional => 1, default => ' ', regex => qr/warning|minor|major|critical|\w/ },
      }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        Backup::Omni::Base::validation_exception($params, $class);
    }
);

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub all {
    my $self = shift;

    return $self->{results};

}

sub next {
    my $self = shift;

    my $pos = $self->cur_pos;
    my $end = scalar(@{$self->{results}}) - 1;

    $pos++;

    if ($pos <= $end) {

        $self->cur_pos($pos);
        return $self->{results}->[$pos];

    } else {

        $self->cur_pos($pos);
        return undef;

    }

}

sub prev {
    my $self = shift;

    my $pos = $self->cur_pos;

    $pos--;

    if ($pos < 0) {

        $self->cur_pos(0);
        return undef;

    } else {

        $self->cur_pos($pos);
        return $self->{results}->[$pos];

    }

}

sub first {
    my $self = shift;

    $self->cur_pos(0);

    return $self->{results}->[0];

}

sub last {
    my $self = shift;

    my $end = scalar(@{$self->{results}}) - 1;

    $self->cur_pos($end);
    
    return $self->{results}->[$end];

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $command = sprintf(COMMAND, OMNIDB, $self->session, $self->report);
    my @result = `$command`;
    my $rc = $?;

    unless (grep(/Normal/, @result)) {

        $self->throw_msg(
            'backup.omni.session.messages',
            'noresults',
            $self->session
        );

    }

    $self->{cur_pos} = 0;
    $self->{results} = \@result;
    
    return $self;

}

1;

__END__

=head1 NAME

Backup::Omni::Session::Messages - Returns the messages of a given session

=head1 SYNOPSIS

 use Backup::Omni::Session::Messages;

 my $messages = Backup::Omni::Session::Messages->new(
     -session => '2013/01/28-1'
 );

 while (my $message = $messaages->next) {

     printf("%s\n", $message);

 }

=head1 DESCRIPTION

This module will return the messages for a session id. It runs the omnidb 
command with the appropiate options. If any errors are encounterd, 
an exception is thrown.

=head1 METHODS

=head2 new

This method will initialze the object. It takes one mandatory parameter and
one optional parameter.

=over 4

=item B<-session>

The session id of the desired session.

=item B<-report>

Optional, returns the type of message. This can be one of the following:

  warning
  minor 
  major 
  critical

The default is to return all of them.

=back

=head2 all

This will return all the messages as an array.

=head2 first

Returns the first message.

=head2 next

Returns the next message.

=head2 prev

Returns the prvious message.

=head2 last

Returns the last message.

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Monitor
 Backup::Omni::Session::Results

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
