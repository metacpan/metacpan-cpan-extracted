package CTK::Skel::Extra;
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Skel::Extra - Extra project skeleton for CTK::Helper

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Extra project skeleton for CTK::Helper

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<CTK::Skel>, L<CTK::Helper>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "extra";

use vars qw($VERSION);
$VERSION = '1.02';

sub build {
    my $self = shift;
    my $rplc = $self->{rplc};
    $self->maybe::next::method();
    return 1;
}
sub dirs {
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'conf/conf.d',
            mode => 0755,
        },
        {
            path => 'inc',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool {
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;

__DATA__

-----BEGIN FILE-----
Name: README
File: conf/conf.d/README
Mode: 644

This directory holds extra project-specific configuration files;
any files in this directory which have the ".conf" extension will be
processed as main configuration file.
-----END FILE-----

-----BEGIN FILE-----
Name: %PROJECT_NAMEL%.conf
File: conf/%PROJECT_NAMEL%.conf
Mode: 644

#
# This file contains Your %PROJECT_NAME% configuration directives.
#
# NOTE!!
# All directives MUST BE written in Apache-config style!
# See https://metacpan.org/pod/Config::General#-ApacheCompatible
#

Include conf.d/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: extra-sendmail.conf
File: conf/conf.d/extra-sendmail.conf
Mode: 644

#
# SendMail section
#
# See https://metacpan.org/pod/CTK::Util#sendmail
#
<SendMail>
    to          to@example.com
    #cc          cc@example.com
    from        from@example.com
    type        text/plain
    smtp        192.168.0.1

    # The sendmail program and arguments
    #sendmail    /usr/sbin/sendmail -t

    # Authorization SMTP data (optional)
    #smtpuser user
    #smtppass password

    # Attach files
    #<Attach>
    #    Filename    doc1.txt
    #    Type        text/plain
    #    Disposition attachment
    #    Data        "Document 1. Content"
    #</Attach>
    #<Attach>
    #    Filename    README
    #    Type        text/plain
    #    Disposition attachment
    #    Path        README
    #</Attach>
</SendMail>
-----END FILE-----

-----BEGIN FILE-----
Name: extra-log.conf
File: conf/conf.d/extra-log.conf
Mode: 644

#
# Logging
#
# Activate or deactivate the logging: on/off (yes/no). Default: off
#
LogEnable on

#
# Loglevel: debug, info, notice, warning, error,
#              crit, alert, emerg, fatal, except
# Default: debug
#
LogLevel debug

#
# LogIdent string. Default: none
#
LogIdent "My test (%PROJECT_NAMEL%)"

#
# LogFile: path to log file
#
# Default: use syslog
#
#LogFile /var/log/%PROJECT_NAMEL%.log

-----END FILE-----

-----BEGIN FILE-----
Name: README
File: inc/README
Mode: 644

This directory holds extra project-specific .pm files for building
-----END FILE-----

-----BEGIN FILE-----
Name: MY.pm
File: inc/MY.pm
Mode: 644

package MY;
use CTK::Util qw/dformat/;

sub postamble {
my $section = <<'MAKE_FRAG';
INST_CONF = blib$(DFSEP)conf

CRLF = $(ABSPERLRUNINST) -MCTK::Command -e crlf --
MY_CONFIGURE = $(ABSPERLRUNINST) -Iinc -MPostConf -e configure --
MY_INSTALL = $(ABSPERLRUNINST) -Iinc -MPostConf -e install --

pure_all :: configured.tmp
[TAB]$(NOECHO) $(ECHO) "Configured."

# Configure
configured.tmp : conf$(DFSEP)$(PROJECT_NAMEL).conf $(INST_CONF)$(DFSEP).exists
[TAB]$(MY_CONFIGURE) conf $(INST_CONF)
[TAB]$(CRLF) $(INST_CONF)
[TAB]$(NOECHO) $(TOUCH) configured.tmp

# Creating directories
$(INST_CONF)$(DFSEP).exists :: Makefile.PL
[TAB]$(MKPATH) $(INST_CONF)
[TAB]$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_CONF)
[TAB]$(NOECHO) $(TOUCH) $(INST_CONF)$(DFSEP).exists

install :: installed.tmp
[TAB]$(NOECHO) $(ECHO) The $(PROJECT_NAME) project has been successfully installed.

installed.tmp : configured.tmp
[TAB]$(MKPATH) "$(PROJECT_CONFDIR)"
[TAB]$(NOECHO) $(CHMOD) $(PERM_DIR) "$(PROJECT_CONFDIR)"
[TAB]$(MY_INSTALL) $(INST_CONF) "$(PROJECT_CONFDIR)"
[TAB]$(NOECHO) $(TOUCH) installed.tmp
MAKE_FRAG

return dformat($section, {
        TAB => "\t",
    });
}

1;
-----END FILE-----

-----BEGIN FILE-----
Name: PostConf.pm
File: inc/PostConf.pm
Mode: 644

package PostConf;
use strict;
use utf8;

%PODSIG%encoding utf8

%PODSIG%head1 NAME

PostConf - Configuration your modules on phase Postamble.

%PODSIG%head1 VERSION

Version 1.02

%PODSIG%head1 SYNOPSIS

    perl -Iinc -MPostConf -e configure -- SOURCE_DIR DESTINATION_DIR

    perl -Iinc -MPostConf -e install -- SOURCE_DIR DESTINATION_DIR

%PODSIG%head1 DESCRIPTION

Configuration your modules on phase Postamble.

B<FOR INTERNAL USE ONLY!>

%PODSIG%head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

%PODSIG%head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

%PODSIG%head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

%PODSIG%cut

use vars qw/$VERSION @EXPORT/;
$VERSION = '1.02';

use Carp;
use File::Copy qw/cp/;
use File::Find;
use File::Spec;
use Cwd qw/getcwd/;
my $basedir = getcwd();

use base qw/Exporter/;
@EXPORT = qw/configure install/;

sub configure {
    my @srcs = @ARGV;
    my $dst = pop @srcs;
    croak "Source directories missing!" unless @srcs;
    croak "Target directory missing!" unless $dst;
    $dst = File::Spec->catdir($basedir, $dst) unless File::Spec->file_name_is_absolute($dst);

    foreach my $src (@srcs) {
        chdir($src) or do {
            print STDERR "Can't change directory: $!\n";
            return 0;
        };
        find({ wanted => sub {
            return if /^\.exists$/;
            my $dir = $File::Find::dir;
            if (-f $_) {
                my $src_f = $_;
                my $dst_f = File::Spec->catfile($dst, $dir, $src_f);
                printf "Copying file %s --> %s... ", $src_f, $dst_f;
                if (-e $dst_f) {
                    print "skipped. File already exists\n";
                    return;
                }
                cp($src_f, $dst_f) or do {
                    print "failed\n";
                    print STDERR "Can't create $dst_f: $!\n";
                };
                print "ok\n";
            } elsif (-d $_) {
                return if /^\.+$/;
                my $dst_d = File::Spec->catdir($dst, $dir, $_);
                my $perm = 0755 & 07777;
                print sprintf("Creating directory %s... ", $dst_d);
                if (-e $dst_d) {
                    print "skipped. Directory already exists\n";
                    return;
                }
                mkdir($dst_d) or do {
                    print "failed\n";
                    print STDERR "Can't create $dst_d: $!\n";
                };
                eval { chmod $perm, $dst_d; };
                if ($@) {
                    print STDERR $@, "\n";
                }
                print "ok\n";
            } else {
                print "Skipped: $_\n";
            }
        }}, ".");
        chdir($basedir) or do {
            print STDERR "Can't change directory: $!\n";
            return 0;
        }
    }

    return 1;
}
sub install { goto &configure }

1;
-----END FILE-----
