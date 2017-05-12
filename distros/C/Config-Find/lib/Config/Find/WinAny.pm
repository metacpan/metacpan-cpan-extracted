package Config::Find::WinAny;

use strict;
use warnings;

use Carp;
use Config::Find::Any;
use Win32 qw(
        CSIDL_LOCAL_APPDATA
        CSIDL_APPDATA
        CSIDL_DESKTOPDIRECTORY);

our @ISA = qw(Config::Find::Any);

sub app_dir {
    my ($class, $name)=@_;

    $name=$class->guess_script_name
    unless defined $name;

    my $ename = uc($name).'_HOME';
    return $ENV{$ename} if (exists $ENV{$ename});
    $class->guess_script_dir;
}

my $winlocalappdir=Win32::GetFolderPath(CSIDL_LOCAL_APPDATA);
my $winappdir=Win32::GetFolderPath(CSIDL_APPDATA);

my $windesktop=Win32::GetFolderPath(CSIDL_DESKTOPDIRECTORY);

if (defined $windesktop and $windesktop ne '') {
    undef $winlocalappdir   if (defined($winlocalappdir) and index($winlocalappdir, $windesktop) == 0);
    undef $winappdir        if (defined($winappdir)      and index($winappdir, $windesktop) == 0);
}

sub app_user_dir {
    my ($class, $name)=@_;
    return ( (defined $winlocalappdir) && ($winlocalappdir ne "") ? $winlocalappdir :
         (defined $winappdir) && ($winappdir ne "") ? $winappdir :
         File::Spec->catdir($class->app_dir($name),
                'Users',
                $class->my_getlogin));
}

sub system_temp {
    my $class=shift;

    return $ENV{TEMP}   if defined $ENV{TEMP};
    return $ENV{TMP}    if defined $ENV{TMP};

    return File::Spec->catfile($ENV{windir}, 'Temp')    if defined $ENV{windir};

    return 'C:\Temp';
}

sub _var_dir {
    my ($class, $name, $more_name, $scope)=@_;
    if ($scope eq 'user') {
        File::Spec->catdir($class->app_user_dir($name), $name, 'Data', $more_name)
    } else {
        File::Spec->catdir($class->app_dir($name), 'Data', $more_name);
    }
}

sub _bin_dir {
    my ($class, $name, $more_name, $scope)=@_;
    if ($scope eq 'app') {
        $class->app_dir($name);
    } else {
        die "unimplemented option scope => $scope";
    }
}

sub look_for_helper {
    my ($class, $dir, $helper)=@_;

    my @ext=('', ( defined $ENV{PATHEXT}
           ? (split /;/, $ENV{PATHEXT})
           : qw(.COM .EXE .BAT .CMD)));

    for my $ext (@ext) {
        my $path=File::Spec->catfile($dir, $helper.$ext);
        -e $path and -x $path and return $path;
    }

    croak "helper '$helper' not found";
}

sub look_for_file {
    my ($class, $name, $write, $global)=@_;
    my $fn;
    my $fnwe=$class->add_extension($name, 'cfg');
    
    if ($write) {
        return File::Spec->catfile($class->app_dir($name), $fnwe)   if ($global);
        # my $login=getlogin();
        return File::Spec->catfile($class->app_user_dir($name), $fnwe );

    } else {
        unless ($global) {
            $fn=File::Spec->catfile($class->app_user_dir, $fnwe );
            return $fn if -f $fn;
        }

        $fn=File::Spec->catfile($class->app_dir($name), $fnwe);
        return $fn if -f $fn;
    }
    
    return;
}

sub look_for_dir_file {
    my ($class, $dir, $name, $write, $global)=@_;
    my $fn;
    my $fnwe=$class->add_extension($name, 'cfg');
    
    if ($write) {
        return File::Spec->catfile($class->app_dir($dir), $dir, $fnwe)  if ($global);

        # my $login=getlogin();
        return File::Spec->catfile($class->app_user_dir($dir), $dir, $fnwe );

    } else {
        unless ($global) {
            $fn=File::Spec->catfile($class->app_user_dir($name), $dir, $fnwe );
            return $fn if -f $fn;
        }
        $fn=File::Spec->catfile($class->app_dir($name), $fnwe);
        return $fn if -f $fn;
    }

    return;
}

1;

__END__

=encoding latin1

=head1 NAME

Config::Find::WinAny - Behaviours common to any Win32 OS for Config::Find

=head1 SYNOPSIS

  # don't use Config::Find::WinAny directly
  use Config::Find;

=head1 ABSTRACT

Implements features common to all the Win32 OS's

=head1 DESCRIPTION

This module implements Config::Find for Win32 OS's.

B<WARNING!!!> Configuration file placement has changed on version 0.15
to be more Windows friendly (see note below).

Order for config files searching is... (see note at the end for
entries marked as 1b and 2b)

  1  ${LOCAL_APPDATA}/$name.cfg                [user]
 (1b /$path_to_script/Users/$user/$name.cfg    [user])
  2  /$path_to_script/$name.cfg                [global]

unless when C<$ENV{${name}_HOME}> is defined. That changes the search
paths to...

 (1b $ENV{${name}_HOME}/Users/$user/$name.cfg  [user])
  2  $ENV{${name}_HOME}/$name.cfg              [global]


When the "several configuration files in one directory" approach is
used, the order is something different...

  1  ${LOCAL_APPDATA}/$dir/$name.cfg              [user]
 (1b /$path_to_script/Users/$user/$dir/$name.cfg  [user])
  2  /$path_to_script/$name.cfg                   [global]
 (2b /$path_to_script/$dir/$name.dfg              [global])

(it is also affected by C<$ENV{${name}_HOME}> variable)

Note: entries marked as 1b were the default behaviour for versions of
Config::Find until 0.14. New behaviour is to put user application
configuration data under ${LOCAL_APPDATA} as returned by
C<Win32::GetFolderPath(CSIDL_LOCAL_APPDATA)> (if this call fails, the
old approach is used).  Also, global configuration files were stored
under a new directory placed in the same directory as the script but
this is unnecessary because windows apps already go in their own
directory.

It seems that, sometimes, ${LOCAL_APPDATA} points to the user desktop
and placing configuration files there would be obviously wrong. As a
work around, the module will ignore ${LOCAL_APPDATA} or ${APPDATA} if
they point to any place below the desktop path.

=head1 SEE ALSO

L<Config::Find>, L<Config::Find::Any>

=head1 AUTHOR

Salvador FandiE<ntilde>o GarcE<iacute>a, E<lt>sfandino@yahoo.comE<gt>

=head1 CONTRIBUTORS

Barbie, E<lt>barbie@missbarbell.co.ukE<gt> (some bug fixes and documentation)

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2015 by Salvador FandiE<ntilde>o GarcE<iacute>a (sfandino@yahoo.com)
Copyright 2015 by Barbie (barbie@missbarbell.co.uk)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
