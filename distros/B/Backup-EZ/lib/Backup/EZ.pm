package Backup::EZ;

use strict;
use warnings;
use warnings FATAL => 'all';
use Config::General;
use Carp;
use Devel::Confess 'color';
use Time::localtime;
use Unix::Syslog qw(:macros :subs);
use Data::UUID;
use Sys::Hostname;
use File::Slurp qw(slurp read_dir);
use File::Spec;
use Backup::EZ::Dir;

#use Data::Printer use_prototypes => 0;
use Data::Printer alias => 'pdump';
use Data::Dumper;

#
# CONSTANTS
#
use constant EXCLUDE_FILE            => '/etc/ezbackup/ezbackup_exclude.rsync';
use constant CONF                    => '/etc/ezbackup/ezbackup.conf';
use constant COPIES                  => 30;
use constant DEST_HOSTNAME           => 'localhost';
use constant DEST_APPEND_MACH_ID     => 0;
use constant USE_SUDO                => 0;
use constant DEFAULT_ARCHIVE_OPTS    => '-az';
use constant ARCHIVE_NO_RECURSE_OPTS => '-dlptgoDz';

=head1 NAME

Backup::EZ - Simple backups based on rsync

=head1 VERSION

Version 0.34

=cut

our $VERSION = '0.39';

=head1 SYNOPSIS

  use Backup::EZ;

  my $ez = Backup::EZ->new;
  $ez->backup;

=head1 DESCRIPTION

Backup::EZ is backup software that is designed to be as easy to use
as possible, yet provide a robust solution

If you only want to run backups, see the included command line utility 
"ezbackup".  See the README for configuration instructions. 

=head1 SUBROUTINES/METHODS

=head2 new

optional args:
    conf         => $config_file      
    dryrun       => $bool,            
    exclude_file => $rsync_excl_file  
  
=cut

sub new {
    my $class = shift;
    my %a     = @_;

    my $self = {};

    # uncoverable branch true
    if ( $ENV{VERBOSE} ) {
        setlogmask( LOG_UPTO(LOG_DEBUG) );
        $self->{syslog_option} = LOG_PID | LOG_PERROR;
    }
    else {
        setlogmask( LOG_UPTO(LOG_INFO) );
        $self->{syslog_option} = LOG_PID;
    }

    _read_conf( $self, @_ );

    if ( $a{dryrun} ) {
        $self->{dryrun} = 1;
    }

    if ( !defined $a{exclude_file} ) {
        $self->{exclude_file} = EXCLUDE_FILE;
    }
    else {
        $self->{exclude_file} = $a{exclude_file};
    }

    bless $self, $class;
    return $self;
}

sub _debug {
    my $self = shift;
    my $msg  = shift;

    my $line = (caller)[2];

    openlog "ezbackup", $self->{syslog_option}, LOG_SYSLOG;
    syslog LOG_DEBUG, "($line) $msg";
    closelog;
}

#sub _error {
#	my $self = shift;
#	my $msg  = shift;
#
#	openlog "ezbackup", $self->{syslog_option}, LOG_LOCAL7;
#	syslog LOG_ERR, $msg;
#	closelog;
#}

sub _info {
    my $self = shift;
    my $msg  = shift;

    openlog "ezbackup", $self->{syslog_option}, LOG_SYSLOG;
    syslog LOG_INFO, $msg;
    closelog;
}

sub _read_conf {
    my $self = shift;
    my %a    = @_;

    # uncoverable branch false
    my $conf = $a{conf} ? $a{conf} : CONF;

    my $config = Config::General->new(
        -ConfigFile     => $conf,
        -ForceArray     => 1,
        -LowerCaseNames => 1,
        -AutoTrue       => 1,

    );

    my %conf = $config->getall;
    _debug( $self, Dumper \%conf );

    foreach my $key ( keys %conf ) {

        if ( !defined $conf{backup_host} ) {
            $conf{backup_host} = DEST_HOSTNAME;
        }

        if ( !defined $conf{copies} ) {
            $conf{copies} = COPIES;
        }

        if ( !defined $conf{append_machine_id} ) {
            $conf{append_machine_id} = DEST_APPEND_MACH_ID;
        }

        if ( !defined $conf{use_sudo} ) {
            $conf{use_sudo} = USE_SUDO;
        }
    }

    if ( ref( $conf{dir} ) ne 'ARRAY' ) {
        $conf{dir} = [ $conf{dir} ];
    }

    $self->{conf} = \%conf;
}

sub _get_dirs {
    my $self = shift;

    my @dirs;

    foreach my $dir ( @{ $self->{conf}->{dir} } ) {
        push( @dirs, Backup::EZ::Dir->new($dir) );
    }

    $self->_debug( Dumper \@dirs );
    return @dirs;
}

=head2 get_conf_dirs

Returns a list Backup::EZ::Dir objects as read from the conf file.

=cut

sub get_conf_dirs {
    my $self = shift;
    return $self->_get_dirs;        
}

sub _ssh {
    my $self   = shift;
    my $cmd    = shift;
    my $dryrun = shift;

    my $sshcmd;
    my $login = $self->_get_dest_login;

    # uncoverable branch false
    if ( $self->_is_unit_test ) {

        # unit testing
        $sshcmd = "$cmd";
    }
    else {
        $sshcmd = sprintf( 'ssh %s %s', $login, $cmd );
    }

    $self->_debug($sshcmd);
    return undef if $dryrun;

    my @out = `$sshcmd`;

    # uncoverable branch true
    confess if $?;

    return @out;
}

sub _get_dest_username {
    my $self = shift;

    if ( $self->{conf}->{backup_user} ) {
        return $self->{conf}->{backup_user};
    }

    if ( $ENV{USER} ) {
        return $ENV{USER};
    }

    my $whoami = `whoami`;
    chomp $whoami;

    return $whoami;
}

sub _get_dest_hostname {
    my $self = shift;

    return $self->{conf}->{backup_host};
}

sub _get_dest_tmp_dir {
    my $self = shift;

    return sprintf( "%s/%s", $self->get_dest_dir, ".tmp" );
}

sub _get_dest_backup_dir {
    my $self = shift;

    return sprintf( "%s/%s", $self->get_dest_dir, $self->{datestamp} );
}

sub _is_unit_test {
    my $self = shift;

    # uncoverable branch false
    if ( $0 =~ /\.t$/ ) {
        return 1;
    }

    return 0;
}

sub _get_dest_login {
    my $self = shift;

    my $username = $self->_get_dest_username;
    my $hostname = $self->_get_dest_hostname;

    return sprintf( '%s@%s', $username, $hostname );
}

sub _rsync_no_recursion {
    my $self          = shift;
    my $dir           = shift;
    my @extra_options = @_;

    my $rsync_opts = '-dlptgoD';
    my $cmd;
    my $login;

    if ( $self->{dryrun} ) {
        push( @extra_options, '--dry-run' );
    }

    $self->_mk_dest_dir( sprintf( "%s%s", $self->_get_dest_tmp_dir, $dir ) );
    $login = $self->_get_dest_login;

    # uncoverable branch false
    if ( $self->_is_unit_test ) {
        $cmd = sprintf(
            "rsync %s $rsync_opts %s/ %s%s",
            join( ' ', @extra_options ), $dir,
            $self->_get_dest_tmp_dir, $dir
        );
    }
    else {
        $cmd = sprintf(
            "rsync %s $rsync_opts -e ssh %s/ %s:%s%s",
            join( ' ', @extra_options ),
            $dir, $login, $self->_get_dest_tmp_dir, $dir
        );
    }

    $cmd .= " --exclude-from " . $self->{exclude_file};

    $self->_debug($cmd);
    system($cmd);

    # uncoverable branch true
    confess if $?;
}

sub _rsync2 {
    my $self = shift;
    my %a    = @_;
    
    my $dir          = $a{dir} or confess "missing dir arg";
    my $link_dest    = $a{link_dest};
    my $archive_opts = $a{archive_opts} || '-az';
    my $extra_opts   = $a{extra_opts} || [];
    
    my $cmd;
    my $login;

    if ( $self->{dryrun} ) {
        push @$extra_opts, '--dry-run';
    }

    if ($link_dest) {
        push @$extra_opts, sprintf '--link-dest "%s"', $link_dest;
    }

    if ( $self->{exclude_file} ) {
        push @$extra_opts, sprintf '--exclude-from "%s"', $self->{exclude_file};
    }

    $self->_mk_dest_dir( sprintf( "%s%s", $self->_get_dest_tmp_dir, $dir ) );
    $login = $self->_get_dest_login;

    # uncoverable branch false
    if ( $self->_is_unit_test ) {
        $cmd = sprintf(
            'rsync -s %s %s "%s/" "%s%s"',
            join(' ', @$extra_opts),
            $archive_opts,               # archive options
            $dir,                        # src dir
            $self->_get_dest_tmp_dir,    # dest tmp dir
            $dir,                        # dest sub dir
        );
    }
    else {
        $cmd = sprintf(
            'rsync -s %s %s -e ssh "%s/" %s:"%s%s"',
            join( ' ', @{$extra_opts} ),    # extra rsync options
            $archive_opts,                  # archive options
            $dir,                           # src dir
            $login,                         # login
            $self->_get_dest_tmp_dir,       # dest tmp dir
            $dir,                           # dest sub dir
        );
    }
   
    #
    # fail safe bailout in case of bug
    # 
    my @cmd = split(/\s+/, $cmd);
    my $link_cnt = 0;
    foreach my $c (@cmd) {
        if ($c =~ /link-dest/) {
            $link_cnt++    
        }    
    }
    
    if ($link_cnt > 1) {
        confess "too many link-dest args: $cmd";     
    }
   
    #
    # ok execute 
    # 
    $self->_debug($cmd);
    system($cmd);
    
    # uncoverable branch true
    confess if $?;
}

sub _rsync {
    my $self          = shift;
    my $dir           = shift;
    my @extra_options = @_;

    my $cmd;
    my $login;

    if ( $self->{dryrun} ) {
        push( @extra_options, '--dry-run' );
    }

    $self->_mk_dest_dir( sprintf( "%s%s", $self->_get_dest_tmp_dir, $dir ) );
    $login = $self->_get_dest_login;

    # uncoverable branch false
    if ( $self->_is_unit_test ) {
        $cmd = sprintf(
            "rsync %s -a %s/ %s%s",
            join( ' ', @extra_options ), $dir,
            $self->_get_dest_tmp_dir, $dir
        );
    }
    else {
        $cmd = sprintf(
            "rsync %s -aze ssh %s/ %s:%s%s",
            join( ' ', @extra_options ),
            $dir, $login, $self->_get_dest_tmp_dir, $dir
        );
    }

    $cmd .= " --exclude-from " . $self->{exclude_file};

    $self->_debug($cmd);
    system($cmd);

    # uncoverable branch true
    confess if $?;
}

sub _full_backup_chunked {
    my $self = shift;
    my $dir  = shift;

    $self->_rsync2(
        dir          => $dir->dirname,
        archive_opts => ARCHIVE_NO_RECURSE_OPTS,
        extra_opts   => $dir->excludes(),
    );

    my @entries = read_dir( $dir->dirname, prefix => 1 );

    foreach my $entry (@entries) {
        if ( -d $entry ) {
            $self->_rsync2(
                dir          => $entry,
                archive_opts => DEFAULT_ARCHIVE_OPTS,
                extra_opts   => $dir->excludes(),
            );
        }
    }
}

sub _full_backup {
    my $self = shift;
    my $dir  = shift;

    if ( $dir->chunked ) {
        $self->_full_backup_chunked($dir);
    }
    else {
        $self->_rsync2(
            dir          => $dir->dirname,
            archive_opts => DEFAULT_ARCHIVE_OPTS,
            extra_opts   => $dir->excludes(),
        );
    }
}

sub _inc_backup_chunked {
    my $self            = shift;
    my $dir             = shift;
    my $last_backup_dir = shift;
    my $link_dest       = shift;
   
    $self->_rsync2(
        dir          => $dir->dirname,
        archive_opts => ARCHIVE_NO_RECURSE_OPTS,
        extra_opts   => $dir->excludes(),
        link_dest    => $link_dest,
    );

    my @entries = read_dir( $dir->dirname, prefix => 0 );
    
    foreach my $entry (@entries) {
        
        my $abs_entry = sprintf( '%s/%s', $dir->dirname, $entry );

        if ( -d $abs_entry ) {
            $self->_rsync2(
                dir          => $abs_entry,
                archive_opts => DEFAULT_ARCHIVE_OPTS,
                extra_opts   => $dir->excludes(),
                link_dest    => sprintf( '%s/%s', $link_dest, $entry ),
            );
        }
    }
}

sub _inc_backup {
    my $self            = shift;
    my $dir             = shift;
    my $last_backup_dir = shift;

    my $link_dest = sprintf(
        "%s/%s/%s",
        $self->get_dest_dir,    #
        $last_backup_dir,       #
        $dir->dirname,          #
    );

    if ( $dir->chunked ) {
        $self->_inc_backup_chunked( $dir, $last_backup_dir, $link_dest );
    }
    else {
        $self->_rsync2(
            dir          => $dir->dirname,
            archive_opts => DEFAULT_ARCHIVE_OPTS,
            extra_opts   => $dir->excludes(),
            link_dest    => $link_dest,
        );
    }
}

sub _mk_dest_dir {
    my $self   = shift;
    my $dir    = shift;
    my $dryrun = shift;

    my $cmd = sprintf( "mkdir -p %s", $dir );
    $self->_ssh( $cmd, $dryrun );
}

sub _set_datestamp {
    my $self = shift;

    my $t = localtime;
    $self->{datestamp} = sprintf(
        "%04d-%02d-%02d_%02d:%02d:%02d",
        $t->year + 1900,
        $t->mon + 1,
        $t->mday, $t->hour, $t->min, $t->sec
    );
}

=head2 dump_conf

Does what it says.

=cut

sub dump_conf {
    my $self = shift;

    pdump $self->{conf};
}

=head2 backup

Invokes the backup process.  Takes no args.

=cut

sub backup {
    my $self = shift;

    $self->_mk_dest_dir( $self->get_dest_dir );
    my @backups = $self->get_list_of_backups;
    $self->_set_datestamp;
    $self->_mk_dest_dir( $self->_get_dest_tmp_dir, $self->{dryrun} );

    foreach my $dir ( $self->_get_dirs ) {
        
        my $dirname = $dir->dirname();
        if ( -d $dirname ) {

            $self->_info("backing up $dirname");

            if ( !@backups ) {

                # full
                $self->_full_backup($dir);
            }
            else {
                # incremental
                $self->_inc_backup( $dir, $backups[$#backups] );
            }
        }
        else {
            $self->_info("skipping $dirname because it does not exist");
        }

    }

    $self->_ssh(
        sprintf( "mv %s %s",
            $self->_get_dest_tmp_dir, $self->_get_dest_backup_dir ),
        $self->{dryrun}
    );

    $self->expire();

    return 1;
}

=head2 expire

Expire backups.  Gets a list of current backups and removes old ones that are 
beyond the cutoff (see "copies" in the conf file).

=cut

sub expire {
    my $self = shift;

    my @list = $self->get_list_of_backups;

    while ( scalar(@list) > $self->{conf}->{copies} ) {

        my $subdir = shift @list;
        my $del_dir = sprintf( "%s/%s", $self->get_dest_dir, $subdir );

        my $cmd = sprintf( "%s rm -rf $del_dir",
            $self->{conf}->{use_sudo} ? 'sudo' : '' );

        $self->_ssh($cmd);
    }
}

=head2 get_backup_host

Returns the backup_host name.

=cut

sub get_backup_host {
    my $self = shift;
    return $self->{conf}->{backup_host};
}

=head2 get_dest_dir

Returns the dest_dir.

=cut

sub get_dest_dir {
    my $self = shift;

    my $hostname = hostname();
    $hostname =~ s/\..+$//;

    if ( $self->{conf}->{append_machine_id} ) {

        # uncoverable branch true
        if ( !-f '/etc/machine-id' ) {

            # uncoverable statement count:2
            my $data_uuid = Data::UUID->new;
            my $uuid      = $data_uuid->create_str();

            # uncoverable statement count:3
            open my $fh, ">/etc/machine-id"
              or confess "failed to open /etc/machine-id: $!";
            print $fh "$uuid\n";
            close($fh);
        }

        my $uuid = slurp("/etc/machine-id");
        chomp $uuid;

        $hostname = "$hostname-$uuid";
    }

    return sprintf( "%s/%s", $self->{conf}->{dest_dir}, $hostname );
}

=head2 get_list_of_backups

Returns an array of backups.  They are in the format of "YYYY-MM-DD_HH:MM:SS".
=cut

sub get_list_of_backups {
    my $self = shift;

    my @backups;

    my @list = $self->_ssh( sprintf( "ls %s", $self->get_dest_dir ) );

    foreach my $e (@list) {
        chomp $e;

        if ( $e =~ /^\d\d\d\d-\d\d-\d\d_\d\d:\d\d:\d\d$/ ) {
            push( @backups, $e );
        }
    }

    return @backups;
}

=head1 AUTHOR

John Gravatt, C<< <john at gravatt.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-backup-ez at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Backup-EZ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Backup::EZ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Backup-EZ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Backup-EZ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Backup-EZ>

=item * Search CPAN

L<http://search.cpan.org/dist/Backup-EZ/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 John Gravatt.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Backup::EZ
