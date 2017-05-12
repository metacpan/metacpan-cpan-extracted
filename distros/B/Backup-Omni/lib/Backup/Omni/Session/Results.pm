package Backup::Omni::Session::Results;

our $VERSION = '0.01';

use Params::Validate ':all';

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Backup::Omni::Base',
  utils     => 'omni2dt trim',
  constants => 'OMNIDB',
  constant => {
      COMMAND => '%s -rpt %s -detail',
  },
  vars => {
      PARAMS => {
          -session => 1,
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

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $command = sprintf(COMMAND, OMNIDB, $self->session);
    my @result = `$command`;
    my $rc = $?;

    unless (grep(/SessionID/, @result)) {

        $self->throw_msg(
            'backup.omni.session.results',
            'noresults',
            $self->session
        );

    }

    foreach my $line (@result) {

        chomp($line);
        next if ($line eq '');

        $line =~ m/^(.*): (.*)/;

        my $key = $1;
        my $value = $2;

        $key = trim($key);
        $key =~ s/ /_/g;
        $key = lc($key);

        $value = trim($value);
        $value = omni2dt($value) if ($value =~ /\w\w\w \d\d \w\w\w \d\d\d\d/);

        # order is important here. Don't change

        $self->class->accessors($key);    # may cause redefintaion errors
        $self->{$key} = $value;

    }

    return $self;

}

1;

__END__

=head1 NAME

Backup::Omni::Session::Results - Return the results of given session

=head1 SYNOPSIS

 use Backup::Omni::Session::Results;

 my $results = Backup::Omni::Session::Results->new(
     -session => '2013/01/28-1'
 );

 printf("status = %s\n", $results->status);

=head1 DESCRIPTION

This module will return the results of a session id. It runs the omnidb 
command with the appropiate options. If any errors are encounterd, 
an exception is thrown.

=head1 METHODS

=head2 new

This method will initialze the object. It takes one parameter.

=over 4

=item B<-session>

The session id of the desired session.

=back

=head2 Results Object

The results object consists of the following methods:

=over 4

=item B<sessionid>

This method returns the session id.

=item B<backup_specification>

The specifications for the backup.

=item B<session_type>

This method returns the session type.

=item B<started>

The datetime when the backup started.

=item B<finished>

The datetime when the backup finished.

=item B<status>

The status of session.

=item B<number_of_warnings>

The number of warning generated during this session.

=item B<number_of_errors>

The number of errors that were generated during this session.

=item B<user>

The user the session was ran under.

=item B<group>

The group the session was ran under.

=item B<session_size>

The size of this session.

=back

=head1 SEE ALSO

 Backup::Omni::Base
 Backup::Omni::Class
 Backup::Omni::Utils
 Backup::Omni::Constants
 Backup::Omni::Exception
 Backup::Omni::Restore::Filesystem::Single
 Backup::Omni::Session::Filesystem
 Backup::Omni::Session::Messages
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
