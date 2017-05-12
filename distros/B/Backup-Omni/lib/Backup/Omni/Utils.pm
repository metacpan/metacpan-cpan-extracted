package Backup::Omni::Utils;

our $VERSION = '0.01';

use Try::Tiny;
use Backup::Omni::Exception;
use Params::Validate ':all';
use DateTime::Format::Strptime;

use Backup::Omni::Class
  version   => $VERSION,
  base      => 'Badger::Utils',
  constants => 'HASH ARRAY OMNISTAT OMNIABORT',
  constant => {
      ABORT   => '%s -session %s',
      CONVERT => '%s -session %s -status_only',
      BADDATE => 'unable to perform date parsing, reason: %s',
      BADPARM => 'invalid parameters passed from %s at line %s',
      BADTEMP => 'bad temporary session id',
      NORESUL => 'unable to find any results for %s',
      NOABORT => 'unable to abort %s',
  },
  exports => {
      any => 'db2dt dt2db omni2dt trim ltrim rtrim convert_id abort_id',
      all => 'db2dt dt2db omni2dt trim ltrim rtrim convert_id abort_id',
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

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;

}

# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;

    $string =~ s/^\s+//;

    return $string;

}

# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;

    $string =~ s/\s+$//;

    return $string;

}

sub db2dt {
    my ($p) = shift;

    my $dt;
    my $parser;

    if ($p =~ m/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/) {

        $parser = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S',
            time_zone => 'local',
            on_error => sub {
                my ($obj, $err) = @_;
                my $ex = Backup::Omni::Exception->new(
                    type => 'backup.omni.utils.db2dt',
                    info => sprintf(BADDATE, $err)
                );
                $ex->throw;
            }
        );

        $dt = $parser->parse_datetime($p);

    } else {

        my ($package, $file, $line) = caller;
        my $ex = Backup::Omni::Exception->new(
            type => 'backup.omni.utils.db2dt',
            info => sprintf(BADPARM, $package, $line)
        );

        $ex->throw;

    }

    return $dt;

}

sub dt2db {
    my ($p) = shift;

    my $ft;
    my $parser;

    my $ref = ref($p);

    if ($ref && $p->isa('DateTime')) {

        $parser = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S',
            time_zone => 'local',
            on_error => sub {
                my ($obj, $err) = @_;
                my $ex = Backup::Omni::Exception->new(
                    type => 'backup.omni.utils.dt2db',
                    info => sprintf(BADDATE, $err)
                );
                $ex->throw;
            }
        );

        $ft = $parser->format_datetime($p);

    } else {

        my ($package, $file, $line) = caller;

        my $ex = Backup::Omni::Exception->new(
            type => 'backup.omni.utils.dt2db',
            info => sprintf(BADPARM, $package, $line)
        );

        $ex->throw;

    }

    return $ft;

}

sub omni2dt {
    my ($p) = shift;

    my $dt;
    my $parser;

    if ($p =~ m/\w{3} \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2} \w{2} \w{3}/) {

        $parser = DateTime::Format::Strptime->new(
            pattern   => '%a %d %b %Y %r',
            time_zone => 'local',
            on_error => sub {
                my ($obj, $err) = @_;
                my $ex = Backup::Omni::Exception->new(
                    type => 'backup.omni.utils.omni2dt',
                    info => sprintf(BADDATE, $err)
                );
                $ex->throw;
            }
        );

        $dt = $parser->parse_datetime($p);

    } else {

        my ($package, $file, $line) = caller;

        my $ex = Backup::Omni::Exception->new(
            type => 'backup.omni.utils.omni2dt',
            info => sprintf(BADPARM, $package, $line)
        );

        $ex->throw;

    }

    return $dt;

}

sub convert_id {
    my $session = shift;

    my $id;

    if ($session =~ m/^R-/) {

        my $command = sprintf(CONVERT, OMNISTAT, $session);
        my @result = `$command`;
        my $rc = $?;

        unless (grep(/SessionID/, @result)) {

            my $ex = Backp::Omni::Exception->new(
                type => 'backup.omni.utils.convert_id',
                info => sprintf(NORESUL, $session)
            );

            $ex->throw;

        }

        ($id) = split(' ', $result[2]);

    } else {

        my $ex = Backup::Omni::Exception->new(
            type => 'backup.omni.utils.convert_id',
            info => BADTEMP
        );

        $ex->throw;

    }

    return $id;

}

sub abort_id {
    my $session = shift;

    my $command = sprintf(ABORT, OMNIABORT, $session);
    my @result = `$command`;
    my $rc = $?;

    unless (grep(/$session/, @result)) {

        my $ex = Backp::Omni::Exception->new(
            type => 'backup.omni.utils.abort_id',
            info => sprintf(NOABORT, $session)
        );

        $ex->throw;

    }

}

1;

__END__

=head1 NAME

Backup::Omni::Utils - Utility functions for Backup::Omni

=head1 SYNOPSIS

 use Backup::Omni::Class
   version => '0.01',
   base    => 'Backup::Omni::Base',
   utils   => 'db2dt dt2db'
 ;

 ... or ...

 use Backup::Omni::Utils 'dt2db';

 printf("%s\n", dt2db($dt));

=head1 DESCRIPTION

This module provides utility routines that can by loaded into your current 
namespace. 

=head1 METHODS

=head2 db2dt($string)

This routine will take a date format of YYYY-MM-DD HH:MM:SS and convert it
into a DateTime object.

=head2 dt2db($datetime)

This routine will take a DateTime object and convert it into the following
string: YYYY-MM-DD HH:MM:SS

=head2 omni2dt($string)

This routine will take a date format of WWW DD MMM YYYY HH:MM:SS PM PST
and convert it into a DateTime object.

=head2 convert_id($session)

Convert a temporary session id into the permanent one.

=head2 abort_id($session)

Abort a running session.

=head2 trim($string)

Trim the whitespace from the beginning and end of a string.

=head2 ltrim($string)

Trim the whitespace from the end of a string.

=head2 rtrim($string)

Trim the whitespace from the beginning of a string.

=head1 SEE ALSO

 Badger::Utils

 Backup::Omni::Base
 Backup::Omni::Class
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
