package App::MonM::Notifier::Const; # $Id: Const.pm 59 2019-07-14 09:14:38Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Const - Interface for constants

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Notifier::Const qw/ :bits :functions :jobs /;

=head1 DESCRIPTION

This module provide interface for constants

=head1 VARIABLES

=head2 EXPIRES

The default "expires" value (30 days)

=head2 JOB_DONE

The "DONE" status

=head2 JOB_ERROR

The "ERROR" status

=head2 JOB_EXPIRED

The "EXPIRED" status

=head2 JOB_NEW

The "NEW" status

=head2 JOB_PROGRESS

The "PROGRESS" status

=head2 JOB_SENT

The "SENT" status

=head2 JOB_SKIP

The "SKIP" status

=head2 TIMEOUT

The default timeout value (300 secs)

=head1 FUNCTIONS

=head2 getErr

    my $errmsg = getErr(101);

Returns error mask for (s)printf by errorcode

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant {
        # General
        EXPIRES         => 30*24*60*60, # 30 days max (Time waiting for hold requests)
        TIMEOUT         => 300,

        # Job Statuses (JOB_*)
        JOB_NEW         => "NEW",       # New job
        JOB_PROGRESS    => "PROGRESS",  # In progress...
        JOB_EXPIRED     => "EXPIRED",   # Expired job. Closed status
        JOB_SKIP        => "SKIP",      # Temporary error status. Closed status
        JOB_SENT        => "SENT",      # Ok status. Message is sent
        JOB_DONE        => "DONE",      # Ok status. Job is closed
        JOB_ERROR       => "ERROR",     # Error status. Closed status

        # ERRORS
        ERRCODES    => {
            0   => "Ok",
            1   => "Unknown error",
            101 => "Can't calculate the period. Please check configuration section for user %s",
            102 => "Can't send message: %s",
        },
    };

use base qw/Exporter/;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use List::Util qw/ max /;
use Carp; # carp - warn; croak - die;

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.01';

# Named groups of exports
%EXPORT_TAGS = (
    'jobs'  => [qw/
        JOB_NEW
        JOB_PROGRESS
        JOB_EXPIRED
        JOB_SKIP
        JOB_SENT
        JOB_DONE
        JOB_ERROR
    /],
    'functions' => [qw/
        getErr
    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (qw/
        EXPIRES
        TIMEOUT
    /, @{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{jobs}});

# Other items we are prepared to export if requested
@EXPORT_OK = (qw/
        EXPIRES
        TIMEOUT
    /, map {@{$_}} values %EXPORT_TAGS);

sub getErr {
    my $code = shift;
    my %es = %{(ERRCODES)};
    do {carp("Incorrect error code"); return} unless defined($code) && exists($es{$code});
    return $es{$code};
}

1;
