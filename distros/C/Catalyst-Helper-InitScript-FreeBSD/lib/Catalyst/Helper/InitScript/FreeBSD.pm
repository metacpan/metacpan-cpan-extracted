package Catalyst::Helper::InitScript::FreeBSD;

use warnings;
use strict;

use English;
use File::Spec::Functions;
use Term::Prompt;
use Getopt::Long;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Helper::InitScript::FreeBSD - /usr/local/etc/rc.d/yourapp.sh generator.

=head1 SYNOPSIS

    % ./script/yourapp_create.pl InitScript::FreeBSD -- --help
    usage: ./script/yourapp_create.pl
        -? -help       display this help and exits.
           -user       The real uid of fastcgi process. [default is USERNAME]
           -group      The real gid of fastcgi process. [default is GROUP]
        -p -pidfile    specify filename for pid file.
                       [default is /var/run/yourapp.pid]
        -l -listen     Socket path to listen on can be HOST:PORT, :PORT or a filesystem path.
                       [default is /var/run/yourapp.sockets]
        -n -nproc      specify number of processes to keep to serve requests.
                       [default is 4]
           -mysql      run after init mysql. [default is no]
           -postgresql run after init postgresql. [default is no]

    % ./script/yourapp_create.pl InitScript::FreeBSD -- -nproc 2 -mysql 
    /usr/home/bokutin/svk/YourApp/trunk/script/../yourapp.sh.sample is exist.
            overwrite? (y or n) [default n] y
    /usr/home/bokutin/svk/YourApp/trunk/script/../yourapp.sh.sample was created.

    The following commands were needed to complete setting up.
    % sudo cp /usr/home/bokutin/svk/YourApp/trunk/script/../yourapp.sh.sample /usr/local/etc/rc.d/yourapp.sh
    % sudo chmod 755 /usr/local/etc/rc.d/yourapp.sh
    % sudo touch /var/run/yourapp.pid
    % sudo touch /var/run/yourapp.sockets

=cut

=head2 mk_stuff

=cut

sub mk_stuff {
    my ( $class, $helper, @args ) = @_;

    # vars 
    my $vars = {
        app   => lc($helper->{app}) || die,
        base  => $helper->{base},
        user  => getpwuid($UID) || "",
        group => getgrgid($GID) || "",
        nproc => 4,
        use_socket => 1,
    };
    $vars->{pidfile} = "/var/run/$vars->{app}.pid";
    $vars->{listen}  = "/var/run/$vars->{app}.sockets";
    my $output  = canonpath(catfile($vars->{base}, "$vars->{app}.sh.sample"));

    # parse args
    {
        no warnings 'uninitialized';
        my $opts = {};
        local @ARGV = @args;
        my $ret = GetOptions(
            'help|?'      => \$opts->{help},
            'user=s'      => \$opts->{user},
            'group=s'     => \$opts->{group},
            'pidfile|p=s' => \$opts->{pidfile},
            'listen|l=s'  => \$opts->{listen},
            'nproc|n=i'   => \$opts->{nproc},
            'mysql'       => \$opts->{mysql},
            'postgresql'  => \$opts->{postgresql},
        );
        if (!$ret or $opts->{help}) {
            $class->_usage($vars);
            return 0;
        }
        if ($opts->{listen} =~ m/:\d+$/) {
            $opts->{use_socket} = 0;
        }
        delete $opts->{$_} for (grep { ! length $opts->{$_} } keys %$opts);
        $vars = { %$vars, %$opts };
    }
 
    # processing
    if (-f $output and !$class->_ask_overwite($vars, $output)) {
        print "cancelled.\n";
        return 0;
    }
    else {
        $class->_render_file($helper, $vars, $output);

        my @msgs;
        push @msgs, "$output was created.";
        push @msgs, "";
        push @msgs, "The following commands were needed to complete setting up.";
        push @msgs, "% sudo cp $output /usr/local/etc/rc.d/$vars->{app}.sh";
        push @msgs, "% sudo chmod 755 /usr/local/etc/rc.d/$vars->{app}.sh";
        push @msgs, "% sudo touch $vars->{pidfile}";
        push @msgs, "% sudo touch $vars->{listen}" if $vars->{use_socket};

        print join("\n", @msgs), "\n";
    }

    return 1;
}

sub _usage {
    my ($class, $vars) = @_;

    print <<USAGE;
usage: $0
    -? -help       display this help and exits.
       -user       The real uid of fastcgi process. [default is $vars->{user}]
       -group      The real gid of fastcgi process. [default is $vars->{group}]
    -p -pidfile    specify filename for pid file. 
                   [default is $vars->{pidfile}]
    -l -listen     Socket path to listen on can be HOST:PORT, :PORT or a filesystem path. 
                   [default is $vars->{listen}]
    -n -nproc      specify number of processes to keep to serve requests. 
                   [default is $vars->{nproc}]
       -mysql      run after init mysql. [default is no]
       -postgresql run after init postgresql. [default is no]
USAGE
}

sub _ask_overwite {
    my ($class, $vars, $output) = @_;

    prompt('y', "$output is exist. overwrite?", "", "");
}

sub _render_file {
    my ($class, $helper, $vars, $output) = @_;

    my $file = 'init_script';

    my $t = Template->new;
    my $template = $helper->get_file( __PACKAGE__, $file );
    return 0 unless $template;
    $t->process( \$template, $vars, $output )
    || Catalyst::Exception->throw(
        message => qq/Couldn't process "$file", / . $t->error() );

    return 1;
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Helper::InitScript::FreeBSD

__DATA__

__init_script__
#!/bin/sh

# PROVIDE: [% app %]
# REQUIRE: DAEMON[% mysql ? ' mysql' : '' %][% postgresql ? ' postgresql': '' %]
# KEYWORD: shutdown

[% app %]_enable=${[% app %]_enable-"NO"}
[% app %]_flags=${[% app %]_flags-""}
[% app %]_pidfile="/var/run/[% app %].pid"
[% app %]_chdir="[% base %]"
[% app %]_user="[% user %]"
[% app %]_group="[% group %]"

[% IF use_socket %]
if [ ! -w $[% app %]_pidfile ]; then
	echo "ERROR: $[% app %]_pidfile is not writable."
	exit 1
fi
[% END %]

. /etc/rc.subr

name="[% app %]"
rcvar=`set_rcvar`
command="$[% app %]_chdir/script/[% app %]_fastcgi.pl"
command_args="-listen [% listen %] -nproc [% nproc %] -pidfile $[% app %]_pidfile -daemon"

load_rc_config $name

procname="perl-fcgi-pm"
pidfile="$[% app %]_pidfile"

run_rc_command "$1"
