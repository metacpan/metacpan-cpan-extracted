#!/usr/bin/perl

# THIS IS A GENERATED MODULE -- DON'T EDIT!

use strict;
use warnings;

package App::Module::Setup::Templates::Default;

use File::Basename qw(dirname);

our $VERSION = "0.01";

my $sar = <<'EOD';
[% FILE Changes %]
Revision history for [% module.distname %]

[% module.version %]    Date/time
        First version, released on an unsuspecting world.

[% FILE MANIFEST %]
Changes
MANIFEST
Makefile.PL
README
lib/[% module.filename %]
t/00-load.t
[% FILE Makefile.PL %]
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '[% module.name %]',
    AUTHOR              => '[% author.name %] <[% author.email %]>',
    VERSION_FROM        => 'lib/[% module.filename %]',
    ABSTRACT_FROM       => 'lib/[% module.filename %]',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '[% module.distname %]-*' },
);
[% FILE README %]
[% module.distname %]

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the README
file from a module distribution so that people browsing the archive
can use it to get an idea of the module's uses. It is usually a good idea
to provide version information here so that people can decide whether
fixes for the module are worth downloading.


INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc [% module.name %]

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% module.distname %]

    Search CPAN
        http://search.cpan.org/dist/[% module.distname %]


COPYRIGHT AND LICENCE

Copyright (C) [% current.year %] [% author.name %]

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

[% FILE lib/_Module.pm %]
#! perl

package [% module.name %];

use warnings;
use strict;
use Carp qw( carp croak );


=head1 NAME

[% module.name %] - The great new [% module.name %]!

=cut

our $VERSION = '[% module.version %]';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use [% module.name %];

    my $foo = [% module.name %]->new();
    ...


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.


=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}


=head1 AUTHOR

[% author.name %], C<< <[% author.cpanid %] at CPAN dot org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-[% module.distnamelc %] at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=[% module.distname %]>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc [% module.name %]

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% module.distname %]>

=item * Search CPAN

L<http://search.cpan.org/dist/[% module.distname %]>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright [% current.year %] [% author.name %], all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of [% module.name %]
[% FILE t/00-load.t %]
#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( '[% module.name %]' );
}

diag( "Testing [% module.name %] $[% module.name %]::VERSION, Perl $], $^X" );
EOD

my @files;
my @dirs;
my %data;

sub load {
    my ( $self ) = ( @_ );

    return ( \@files, \@dirs, \%data ) if @files;

    open( my $fd, '<', \$sar );
    my $file;
    my %dirs;
    while ( <$fd> ) {
	if ( /\[\%\s*FILE\s+(.*?)\s*\%\]/ ) {
	    push( @files, $file = $1 );
	    $dirs{ dirname($file) }++ if dirname($file);
	}
	elsif ( $file ) {
	    $data{$file} .= $_;
	}
	else {
	    die("Internal error: Leading data in sar");
	}
    }
    @dirs = sort keys %dirs;
    ( \@files, \@dirs, \%data );
}

1;

