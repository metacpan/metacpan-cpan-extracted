package Config::Find::Unix;

use strict;
use warnings;

use Carp;
use File::HomeDir;
use Config::Find::Any;

our @ISA=qw(Config::Find::Any);

sub app_dir {
    my ($class, $name)=@_;
    $name=$class->guess_script_name
    unless defined $name;

    my $ename = uc($name).'_HOME';
    return $ENV{$ename}     if (exists $ENV{$ename});

    $class->parent_dir($class->guess_script_dir);
}

sub _my_home {
    my $home = File::HomeDir->my_home;
    return $home            if defined $home;

    my ($user, $dir) = (getpwuid $>)[0, 7];

    return $dir             if defined $dir;
    return "/home/$user"    if defined $user;
    return "/"
};

sub system_temp { '/tmp' }

sub _var_dir {
    my ($class, $name, $more_name, $scope) = @_;

    if ($scope eq 'global') {
        $class->my_catfile('/var', $name, $more_name);
    } elsif ($scope eq 'user') {
        File::Spec->catfile(_my_home(), '.'.$name, 'var', $more_name);
    } elsif ($scope eq 'app') {
        $class->my_catfile($class->app_dir($name), 'var', $more_name);
    } else {
        croak "scope '$scope' is not valid for var_dir method";
    }
}

sub _bin_dir {
    my ($class, $name, $more_name, $scope) = @_;
    
    if ($scope eq 'global') {
        '/usr/bin';
    } elsif ($scope eq 'user') {
        File::Spec->catfile(_my_home(), 'bin');
    } elsif ($scope eq 'app') {
        File::Spec->catfile($class->app_dir($name), 'bin');
    } else {
        croak "scope '$scope' is not valid for bin_dir method";
    }
}

sub _lib_dir {
    my ($class, $name, $more_name, $scope) = @_;
    
    if ($scope eq 'global') {
        '/usr/lib';
    } elsif ($scope eq 'user') {
        File::Spec->catfile(_my_home(), 'lib');
    } elsif ($scope eq 'app') {
        File::Spec->catfile($class->app_dir($name), 'lib');
    } else {
        croak "scope '$scope' is not valid for lib_dir method";
    }
}

sub look_for_file {
    my ($class, $name, $write, $global)=@_;
    my $fn;
    
    if ($write) {
        if ($global) {
            my $fnwe=$class->add_extension($name, 'conf');

            unless ($class->is_one_liner) {
                my $etc=File::Spec->catfile($class->app_dir($name), 'etc');
                return File::Spec->catfile($etc, $fnwe) if -e $etc;

                $etc=File::Spec->catfile($class->app_dir($name), 'conf');
                return File::Spec->catfile($etc, $fnwe) if -e $etc;
            }

            return File::Spec->catfile('/etc', $fnwe);
        }

        return File::Spec->catfile(_my_home(), ".$name");

    } else {

        # looks in ~/.whatever
        unless ($global) {
            $fn=File::Spec->catfile(_my_home(), ".$name");
            return $fn if -f $fn;
            for my $ext (qw(conf cfg)) {
                return "$fn.$ext" if -f "$fn.$ext";
            }
        }

        for my $fnwe (map {$class->add_extension($name, $_)} qw(conf cfg)) {
            unless ($class->is_one_liner) {
                # looks in ./../etc/whatever.conf relative to the running script
                $fn=File::Spec->catfile($class->app_dir($name), 'etc', $fnwe);
                return $fn if -f $fn;
                
                # looks in ./../conf/whatever.conf relative to the running script
                $fn=File::Spec->catfile($class->app_dir($name), 'conf', $fnwe);
                return $fn if -f $fn;
            }

            # looks in /etc/whatever.conf
            $fn=File::Spec->catfile('/etc', $fnwe);
            return $fn if -f $fn;
        }
    }
    
    return;
}

sub look_for_helper {
    my ($class, $dir, $helper)=@_;
    my $path=File::Spec->catfile($dir, $helper);
    -e $path
        or croak "helper '$helper' not found";
    ((-f $path or -l $path) and -x $path)
        or croak "helper '$helper' found at '$path' but it is not executable";
    return $path
}

sub look_for_dir_file {
    my ($class, $dir, $name, $write, $global)=@_;
    my $fn;

    if ($write) {
        my $fnwe=$class->add_extension($name, 'conf');
        if ($global) {
            unless ($class->is_one_liner) {
                my $etc=File::Spec->catfile($class->app_dir($dir), 'etc');
                return File::Spec->catfile($etc, $dir, $fnwe) if -e $etc;

                $etc=File::Spec->catfile($class->app_dir($dir), 'conf');
                return File::Spec->catfile($etc, $dir, $fnwe) if -e $etc;
            }

            return File::Spec->catfile('/etc', $dir, $fnwe);
        }

        return File::Spec->catfile(_my_home(), ".$dir", $fnwe);

    } else {
        # looks in ~/.whatever
        for my $fnwe (map {$class->add_extension($name, $_)} qw(conf cfg)) {

            unless ($global) {
                my $fn=File::Spec->catfile(_my_home(), ".$dir", $fnwe);
                return $fn if -f $fn;
            }

            unless ($class->is_one_liner and not defined $dir) {
                # looks in ./../etc/whatever.conf relative to the running script
                $fn=File::Spec->catfile($class->app_dir($dir), 'etc', $dir, $fnwe);
                return $fn if -f $fn;

                # looks in ./../conf/whatever.conf relative to the running script
                $fn=File::Spec->catfile($class->app_dir($dir), 'conf', $dir, $fnwe);
                return $fn if -f $fn;
            }
        
            # looks in system /etc/whatever.conf
            $fn=File::Spec->catfile('/etc', $dir, $fnwe);
            return $fn if -f $fn;
        }
    }

    return;
}

1;

__END__

=encoding latin1

=head1 NAME

Config::Find::Unix - Config::Find plugin for Unixen

=head1 SYNOPSIS

  # don't use Config::Find::Unix directly
  use Config::Find;

=head1 ABSTRACT

Config::Find plugin for Unixen

=head1 DESCRIPTION

This module implements Config::Find for Unix

The order for searching the config files is:

  1  ~/.$name                             [user]
  1b ~/.$name.conf                        [user]
  2  /$path_to_script/../etc/$name.conf   [global]
  3  /$path_to_script/../conf/$name.conf  [global]
  4  /etc/$name.conf                      [global]

although if the environment variable C<$ENV{${name}_HOME}> is defined
it does

  1  ~/.$name                             [user]
  1b ~/.$name.conf                        [user]
  2  $ENV{${name}_HOME}/etc/$name.conf    [global]
  3  $ENV{${name}_HOME}/conf/$name.conf   [global]
  4  /etc/$name.conf                      [global]

instead.

When the "several configuration files in one directory" approach is
used, the order is somewhat different:

  1  ~/.$dir/$name.conf                        [user]
  2  /$path_to_script/../etc/$dir/$name.conf   [global]
  3  /$path_to_script/../conf/$dir/$name.conf  [global]
  4  /etc/$dir/$name.conf                      [global]

(also affected by C<$ENV{${name}_HOME}>)

=head1 SEE ALSO

L<Config::Find>, L<Config::Find::Any>.

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
