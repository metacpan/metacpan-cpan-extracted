package Config::Find;

our $VERSION = '0.31';

use strict;
use warnings;

use Carp;

# selects implementation module:
our @ISA;
BEGIN {
    if ($^O=~/Win32/) {
        require Win32;
        my $OS = uc Win32::GetOSName();

        if ($OS=~/^WIN95/) {
            require Config::Find::Win95;
            @ISA=qw(Config::Find::Win95);
        } elsif ($OS=~/^WIN98/) {
            require Config::Find::Win98;
            @ISA=qw(Config::Find::Win98);
        } elsif ($OS=~/^WINME/) {
            require Config::Find::WinME;
            @ISA=qw(Config::Find::WinME);
        } elsif ($OS=~/^WINNT/) {
            require Config::Find::WinNT;
            @ISA=qw(Config::Find::WinNT);
        } elsif ($OS=~/^WIN2000/) {
            require Config::Find::Win2k;
            @ISA=qw(Config::Find::Win2k);
        } elsif ($OS=~/^WIN2003/) {
            require Config::Find::Win2k3;
            @ISA=qw(Config::Find::Win2k3);
        } elsif ($OS=~/^WINXP/) {
            require Config::Find::WinXP;
            @ISA=qw(Config::Find::WinXP);
        } elsif ($OS=~/^WINCE/) {
            require Config::Find::WinCE;
            @ISA=qw(Config::Find::WinCE);
        } elsif ($OS=~/^WIN7/) {
            require Config::Find::Win7;
            @ISA=qw(Config::Find::Win7);
        } else {
            # default to WinAny, and separate exceptions
            require Config::Find::WinAny;
            @ISA=qw(Config::Find::WinAny);
            #croak "Unknown MSWin32 OS '$OS'";
        }
    } else {
        require Config::Find::Unix;
        @ISA=qw(Config::Find::Unix);
    }
}

sub find {
    my $class=shift;
    my ($write, $global, $fn, @names)=$class->parse_opts(@_);
    if (defined $fn) {
        return ($write or -f $fn) ? $fn : undef;
    }
    $class->_find($write, $global, @names);
}

sub open {
    my $class=shift;
    my ($write, $global, $fn, @names)=$class->parse_opts(@_);
    defined($fn) or $fn=$class->_find($write, $global, @names);
    $class->_open($write, $global, $fn);
}

sub install {
    my $class=shift;
    my $orig=shift;
    my ($write, $global, $fn, @names)=$class->parse_opts( mode => 'w', @_);
    defined($fn) or $fn=$class->_find($write, $global, @names);
    $class->_install($orig, $write, $global, $fn);
}

sub parse_opts {
    my ($class, %opts)=@_;
    my $fn=$opts{file};
    my @names;
    if (exists $opts{name}) {
        @names=$opts{name};
    } elsif (exists $opts{names}) {
        UNIVERSAL::isa($opts{names}, 'ARRAY')
            or croak "invalid argument for 'names', expecting an array ref";
        @names=@{$opts{names}}
    } else {
        @names=$class->guess_script_name();
    }
    
    my $write;
    if (exists $opts{mode}) {
        if ($opts{mode}=~/^r(ead)?$/i) {
            # yes, do nothing!
        } elsif ($opts{mode}=~/w(rite)?$/i) {
            $write=1;
        } else {
            croak "invalid option mode => '$opts{mode}'";
        }
    }

    my $global;
    if (exists $opts{scope}) {
        if ($opts{scope}=~/^u(ser)?$/i) {
            # yes, do nothing!
        } elsif ($opts{scope}=~/g(lobal)?$/i) {
            $global=1;
        } else {
            croak "invalid option scope => '$opts{scope}'";
        }
    }
    return ($write, $global, $fn, @names)
}

1;

__END__

=encoding latin1

=head1 NAME

Config::Find - Find configuration files in the native OS fashion

=head1 SYNOPSIS

  use Config::Find;

  my $filename=Config::Find->find;

  ...

  my $fn_foo=Config::Find->find( name => 'my_app/foo',
                                 mode => 'write',
                                 scope => 'user' );

  my $fn_bar=Config::Find->find( names => [qw(my_app/bar appbar)] );

  my $fh=Config::Find->open( name => 'foo',
                             scope => 'global',
                             mode => 'w' )


  my $fn=Config::Find->install( 'original/config/file.conf',
                                name => 'foo' );

  my $fn=Config::Find->find( file => $opt_c,
                             name => foo );

=head1 ABSTRACT

Config::Find searches for configuration files using OS dependant
heuristics.

=head1 DESCRIPTION

Every OS has different rules for configuration files placement, this
module allows one to easily find and create your app configuration files
following those rules.

Config::Find references configuration files by the application name or
by the application name and the configuration file name when the app
uses several application files, i.e C<emacs>, C<profile>,
C<apache/httpd>, C<apache/ssl>.

By default the $0 value is used to generate the configuration file
name. To define it explicitly the keywords C<name> or C<names> have to
be used:

=over 4

=item name => C<name> or C<app/file>

picks the first configuration file matching that name.

=item names => [qw(foo bar foo/bar)]

picks the first configuration file matching any of the names passed.

=back

Alternatively, the exact position for the file can be specified with
the C<file> keyword:

=over 4

=item file => C</config/file/name.conf>

explicit position of the configuration file.

If undef is passed this entry is ignored and the search for the
configuration file continues with the appropriate OS rules. This allows
for:

  use Config::Find;
  use Getopt::Std;

  our $opt_c;
  getopts('c:');

  my $fn=Config::Find->find(file => $opt_c)

=back

Methods in this package also accept the optional arguments C<scope>
and C<mode>:

=over 4

=item scope => C<user> or C<global>

Configuration files can be private to the application user or global
to the OS, i.e. in unix there is the global C</etc/profile> and the
user C<~/.profile>.

=item mode => C<read> or C<write>

In C<read> mode already existent file names are returned, in C<write>
mode the file names point to where the configuration file has to be
stored.

=back

=head2 METHODS

All the methods in this package are class methods (you don't need an
object to call them).

=over 4

=item $fn=Config::Find-E<gt>find(%opts)

returns the name of the configuration file.

=item $fh=Config::Find-E<gt>open(%opts)

returns a open file handle for the configuration file. In write mode,
the file and any nonexistent parent directories are created.

=item $fn=Config::Find-E<gt>install($original, %opts)

copies a configuration file to a convenient place.

=back

=head1 BUGS

Some Win32 operating systems are not completely implemented and
default to inferior modes, but hey, this is a work in progress!!!

Contributions, bug reports, feedback and any kind of comments are welcome.

=head1 SEE ALSO

L<Config::Find::Unix>, L<Config::Find::Win32> for descriptions of the
heuristics used to find the configuration files.

L<Config::Find::Any> for information about adding support for a new
OS.

L<Config::Auto> give me the idea for this module.

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
