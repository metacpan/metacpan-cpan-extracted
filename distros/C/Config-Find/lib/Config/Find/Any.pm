package Config::Find::Any;

use strict;
use warnings;

use Carp;
use File::Spec;
use File::Which;
use IO::File;

# private methods

sub _find {
    my ($class, $write, $global, @names)=@_;
    
    for my $n (@names) {
        my $fn;
        if ($n=~/^(.*?)\/(.*)$/) {
            my ($dir, $file)=($1, $2);
            $fn=$class->look_for_dir_file($dir, $file, $write, $global);
        } else {
            $fn=$class->look_for_file($n, $write, $global);
        }
        return $fn if defined $fn;
    }

    return undef;
}

sub _open {
    my ($class, $write, $global, $fn)=@_;
    
    if ($write) {
        $class->create_parent_dir($fn);
        return IO::File->new($fn, 'w');
    }

    defined($fn) ? IO::File->new($fn, 'r') : undef;
}

sub _install {
    my ($class, $orig, $write, $global, $fn)=@_;
    croak "install mode has to be 'write'" unless $write;

    my $oh=IO::File->new($orig, 'r')
        or croak "unable to open '$orig'";
    my $fh=$class->_open($write, $global, $fn)
        or croak "unable to create config file '$fn'";
    
    while(<$oh>) { $fh->print($_) }
    
    close $fh
        or die "unable to write config file '$fn'";
    close $oh
        or die "unable to read '$orig'";
    return $fn;
}

sub _temp_dir {
    my ($class, $name, $more_name, $scope)=@_;

    my $stemp=$class->system_temp;

    if ($scope eq 'global') {
        $class->my_catdir($stemp, $name, $more_name)
    } elsif ($scope eq 'user') {
        $class->my_catdir($stemp, $class->my_getlogin, $name, $more_name)
    } elsif ($scope eq 'app') {
        $class->my_catdir($class->app_dir($name), 'tmp', $more_name)
    } elsif ($scope eq 'process') {
        $class->my_catdir($stemp, $class->my_getlogin, $name, $$, $more_name)
    } else {
        croak "scope '$scope' is not valid for temp_dir method";
    }
}

# public methods, to be overridden

sub look_for_file {
    my $class=shift;
    die "unimplemented virtual method $class->look_for_file() called";
}

sub look_for_dir_file {
    my $class=shift;
    die "unimplemented virtual method $class->look_for_dir_file() called";
}

# public methods, inherited by sub-classes

sub guess_full_script_name {
    my $path = (File::Spec->splitpath($0))[1];
    if ($path eq '') {
        if (my $script = File::Which::which($0)) {
            return File::Spec->rel2abs($script);
        }
    }

    return File::Spec->rel2abs($0) if -e $0;

    carp "unable to determine script '$0' location";
}

sub guess_script_name {
    my $name;
    (undef, undef, $name)=File::Spec->splitpath($0);
    $name=~/^(.+)\..*$/ and return $1;
    return undef if $name eq '';
    return $name;
}

sub guess_script_dir {
    my $class=shift;
    my $script=$class->guess_full_script_name;
    my ($unit, $dir)=File::Spec->splitpath($script, 0);
    File::Spec->catpath($unit, $dir, '');
}

sub is_one_liner { return $0 eq '-e' }

sub add_extension {
    my ($class, $name, $ext)=@_;
    return $name if ($name=~/\./);
    return $name.'.'.$ext;
}

sub create_parent_dir {
    my ($class, $fn)=@_;
    my $parent=$class->parent_dir($fn);
    if (-e $parent) {
        -d $parent
            or croak "'$parent' exists but is not a directory";
        -W $parent
            or croak "not allowed to write on directory '$parent'";
    } else {
        $class->create_parent_dir($parent);
        mkdir $parent
            or die "unable to create directory '$parent' ($!)";
    }
}

sub parent_dir {
    my ($class, $dir)=@_;
    # print "creating dir $dir\n";
    my @dirs=File::Spec->splitdir($dir);
    pop(@dirs) eq '' and pop(@dirs);
    File::Spec->catfile(@dirs ? @dirs : File::Spec->rootdir);
}

sub create_dir {
    my ($class, $dir)=@_;
    if (-e $dir) {
        -d $dir or croak "'$dir' exists but is not a directory";
    } else {
        $class->create_parent_dir($dir);
        mkdir $dir
            or die "unable to create directory '$dir' ($!)";
    }
    $dir;
}

sub my_catfile {
    my $class=shift;
    pop @_ unless defined $_[-1];
    File::Spec->catfile(@_);
}

sub my_catdir {
    my $class=shift;
    pop @_ unless defined $_[-1];
    File::Spec->catdir(@_);
}

sub my_getlogin {
    my $login=getlogin();
    $login = '_UNKNOW_' unless defined $login;
    $login;
}

1;

__END__

=encoding latin1

=head1 NAME

Config::Find::Any - Perl base class for Config::Find

=head1 SYNOPSIS

  # don't use Config::Find::Any;
  use Config::Find;

=head1 ABSTRACT

This module implements basic methods for L<Config::Find>.

=head1 DESCRIPTION

Every L<Config::Find> class has to be derived from this one and two
methods have to be redefined, while the remainder can be utilized by the
class as required.

=head2 OVERRIDE METHODS

=over 4

=item $class->look_for_file($name, $write, $global)

=item $class->look_for_dir_file($dir, $name, $write, $global)

=back

=head2 CLASS METHODS

=over 4

=item $class->guess_full_script_name($file)

=item $class->guess_script_name($file)

=item $class->guess_script_dir($file)

=item $class->is_one_liner($file)

=item $class->add_extension($name, $extension)

=item $class->create_parent_dir($file)

=item $class->parent_dir($dir)

=item $class->create_dir($dir)

=item $class->my_catfile($path,$to,$file,...)

=item $class->my_catdir($path,$to,$dir,...)

=item $class->my_getlogin()

=back

=head1 SEE ALSO

L<Config::Find>, L<Config::Find::Unix>, L<Config::Find::Win32>.

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
