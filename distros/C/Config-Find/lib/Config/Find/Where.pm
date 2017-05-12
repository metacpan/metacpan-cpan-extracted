package Config::Find::Where;

use strict;
use warnings;

use Carp;
use Config::Find;
our @ISA=@Config::Find::ISA;

sub temp_dir {
    my $class = shift;
    my ($name, $more_name, $create, $dn, $scope)=
    $class->parse_opts(scope=> 'user', @_);

    $class->create_dir_if( (defined $dn
                ? $dn
                : $class->_temp_dir($name, $more_name, $scope)),
               $create)
}

sub var_dir {
    my $class = shift;
    my ($name, $more_name, $create, $dn, $scope)=
    $class->parse_opts(scope => 'app', @_);

    $class->create_dir_if( (defined $dn
                ? $dn
                : $class->_var_dir($name, $more_name, $scope) ),
               $create)
}

sub bin_dir {
    my $class = shift;
    my ($name, $more_name, $create, $dn, $scope)=
    $class->parse_opts(scope=> 'app', @_);

    $class->create_dir_if( (defined $dn
                ? $dn
                : $class->_bin_dir($name, $more_name, $scope) ),
               $create);
}

sub lib_dir {
    my $class = shift;
    my ($name, $more_name, $create, $dn, $scope) =
        $class->parse_opts(scope => 'app', @_);

    $class->create_dir_if( (defined $dn
                            ? $dn
                            : $class->_lib_dir($name, $more_name, $scope) ),
                           $create);
}

sub application_dir {
    my $class=shift;
    my ($name, $more_name, $create, $dn, $scope)=
    $class->parse_opts(@_);

    $class->create_dir_if( (defined $dn
                ? $dn
                : $class->app_dir($name) ),
               $create)
}

sub create_dir_if {
    my ($class, $dir, $create)=@_;
    # warn ("$class->create_dir($dir, $create)");
    if ($create) {
        $class->create_dir($dir);
    }
    $dir;
}

sub create_dir {
    my ($class, $dir)=@_;
    $class->SUPER::create_dir(File::Spec->rel2abs($dir));
}

sub create_parent_dir {
    my ($class, $dir)=@_;
    $class->SUPER::create_parent_dir(File::Spec->rel2abs($dir));
}

sub script_full_path { shift->guess_full_script_name }

sub script_name { shift->guess_script_name }

sub script_dir { shift->guess_script_dir }

sub helper_path {
    my $class=shift;
    my $helper=shift;
    my $path=$class->bin_dir(@_);
    $class->look_for_helper($path, $helper);
}

sub parse_opts {
    my ($class, %opts)=@_;
    my ($name, $more_name, $create, $dn, $scope);
    $dn=$opts{dir};
    $create=$opts{create};

    if (defined $opts{name}) {
        $opts{name}=~m{^([^/]*)(?:/(.*))?$}
            or croak "invalid name '$opts{name}' specification";
        $name=$1;
        $more_name=$2;
    } else {
        $name=$class->guess_script_name;
    }

    if (defined $opts{scope}) {
        if ($opts{scope}=~/^u(ser)?$/i) {
            $scope='user'
        } elsif ($opts{scope}=~/^g(lobal)?$/i) {
            $scope='global'
        } elsif ($opts{scope}=~/^a(pp(lication)?)?$/i) {
            $scope='app'
        } elsif ($opts{scope}=~/^p(rocess)?$/i) {
            $scope='process'
        } else {
            croak "invalid option scope => '$opts{scope}'";
        }
    } else {
        $scope='global';
    }

    return ($name, $more_name, $create, $dn, $scope);
}

1;

__END__

=encoding latin1

=head1 NAME

Config::Find::Where - Find locations in the native OS fashion

=head1 SYNOPSIS

  use Config::Find::Where;

  my $temp_dir=Config::Find::Where->temp_dir( name => 'my_app',
                                              scope => 'process',
                                              create => 1 );

  my $path=Config::Find::Where->bin_dir( scope => 'app' );
  system $path."/app_helper.exe";

=head1 ABSTRACT

Config::Find searches for locations using OS dependant heuristics.

=head1 DESCRIPTION

After releasing L<Config::Find> I found much of its code could be
reused to also find other interesting things like temporary
directories, the script location, etc.

This module adds a public API to all the hidden functionality.

=head2 OPTIONS

As in L<Config::Find>, all the methods in this package accept a common
set of options:

=over 4

=item name => C<name> or C<name/more/names>

specifies the primary application name used to generate the location
paths or to search for them.

=item scope => C<user>, C<global>, C<app> or C<process>

-

=item create => 1

creates any nonexistent directory in the path returned

=back

=head2 METHODS

All the methods in this package are class methods (you don't need an
object to call them).

=over 4

=item $path=Config::Find::Where-E<gt>temp_dir(%opts)

returns a directory path inside a system temporary location. i.e.:

  Config::Find::Where->temp_dir( name =>'hello/world',
                                 scope => 'process',
                                 create => 1 )

returns something similar to

  '/tmp/jacks/hello/974/world/'

on unix like systems and

  'C:\Windows\Temp\jacks\hello\974\world'

on some Windows ones ('jacks' is supposed to be the current user name
and '974' the process number).

The default scope for this method is C<user>.

=item $path=Config::Find::Where-E<gt>bin_dir(%opts)

returns a place to find/place binary files. The default scope for this
method is C<app>.

i.e.

 Config::Find::Where->bin_dir()

returns the path to the directory where binaries are located.

Note that this directory is not necessarily the same as the one
containing the running script. See documentation for C<script_dir>
below.

=item $path=Config::Find::Where-E<gt>var_dir(%opts)

returns a place to find/place working files.

The default scope for this method is C<app>.

=item $path = Config::Find::Where-E<gt>lib_dir(%opts)

returns a place to find/place library files.

The default scope for this method is C<app>.

For instance:

  use lib => Config::Find::Where->lib_dir;

=item $path = Config::Find::Where-E<gt>application_dir(%opts)

returns the application root directory.

=item $name=Config::Find::Where-E<gt>script_name()

returns the name of the running script without any path information

=item $path=Config::Find::Where-E<gt>script_full_path()

returns the name of the script as the absolute full path to it.

=item $path=Config::Find::Where-E<gt>script_dir()

returns the name of the directory containing the current script

=item Config::Find::Where-E<gt>create_dir($dir)

creates directory C<$dir> and any needed parents

=item Config::Find::Where-E<gt>create_parent_dir($file)

recursively creates all the nonexistent parent directories for
C<$file>.

=item Config::Find::Where-E<gt>helper_path($file, %opts)

searches for a script, based on the directories given in %opts, which are the
same as bin_dir() method.

=back

=head1 BUGS

Some Win32 operating systems are not completely implemented and
default to inferior modes, but hey, this is a work in progress!!!

Contributions, bug reports, feedback and any kind of comments are
welcome.

=head1 SEE ALSO

L<Config::Find>

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
