
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.7';

1;

__END__

=head1 NAME

Config::Manager - Configuration Manager

=head1 SYNOPSIS

You will usually

 use Config::Manager::Base;

and go from there.

See also the scripts

 listconf.pl   [listconf.bat]
 showchain.pl  [showchain.bat]
 showconf.pl   [showconf.bat]
 update_ini.pl [update_ini.bat]

(included in this distribution) for examples
on how to do this, and Config::Manager::Base(3)
for a tutorial.

You can also specify which symbols to import:

 use Config::Manager::Base
 qw(
     $SCOPE
     GetList
     GetOrDie
     ReportErrorAndExit
 );

 use Config::Manager::Conf
 qw(
     whoami
 );

 use Config::Manager::File
 qw(
     Normalize
     MakeDir
     UniqueTempFileName
     ConvertFromHost
     ConvertToHost
     CompareFiles
     CopyFile
     MoveByCopying
     MD5Checksum
     ReadFile
     WriteFile
     AppendFile
     ConvertFileWithCallback
     SerializeSimple
     Semaphore_Passeer
     Semaphore_Verlaat
     GetNextTicket
 );

 use Config::Manager::PUser
 qw(
     &current_user
     &current_conf
     &default_user
     &default_conf
 );

 use Config::Manager::Report
 qw(
     $USE_LEADIN
     $STACKTRACE
     $LEVEL_TRACE
     $LEVEL_INFO
     $LEVEL_WARN
     $LEVEL_ERROR
     $LEVEL_FATAL
     $TO_HLD
     $TO_OUT
     $TO_ERR
     $TO_LOG
     $FROM_HOLD
     $SHOW_ALL
     @TRACE
     @INFO
     @WARN
     @ERROR
     @FATAL
     end
     abort
 );

 use Config::Manager::SendMail
 qw(
     SendMail
     NotifyAdmin
 );

 use Config::Manager::User
 qw(
     user_id
     user_name
     user_conf
     host_id
     host_pw
     machine_id
 );

All modules also export the ":all" tag:

 use Config::Manager::Base     qw(:all);
 use Config::Manager::Conf     qw(:all);
 use Config::Manager::File     qw(:all);
 use Config::Manager::PUser    qw(:all);
 use Config::Manager::Report   qw(:all);
 use Config::Manager::SendMail qw(:all);
 use Config::Manager::User     qw(:all);

=head1 DESCRIPTION

This distribution comprehends the following modules
and scripts:

 Config::Manager::Base
 Config::Manager::Conf
 Config::Manager::File
 Config::Manager::PUser
 Config::Manager::Report
 Config::Manager::SendMail
 Config::Manager::User

 listconf.pl   [listconf.bat]
 showchain.pl  [showchain.bat]
 showconf.pl   [showconf.bat]
 update_ini.pl [update_ini.bat]

=head1 SEE ALSO

Config::Manager::Base(3),
Config::Manager::Conf(3),
Config::Manager::File(3),
Config::Manager::PUser(3),
Config::Manager::Report(3),
Config::Manager::SendMail(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager" version 1.7.

=head1 AUTHORS

 Steffen Beyer <sb@engelschall.com>
 http://www.engelschall.com/u/sb/download/
 Gerhard Albers

=head1 COPYRIGHT

 Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
 All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for more details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

