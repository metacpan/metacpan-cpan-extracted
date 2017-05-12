package DBIx::Schema::Changelog::Role::Command;

=head1 NAME

DBIx::Schema::Changelog::Role::Command - Abstract file class.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings FATAL => 'all';
use Time::Piece;
use Moose::Role;

has year => (
    isa     => 'Int',
    is      => 'ro',
    default => sub {
        my $t = Time::Piece->new();
        return $t->year;
    }
);

has makefile => (
    isa     => 'Str',
    is      => 'ro',
    default => q~use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Schema::Changelog::{0}::{1}',
    AUTHOR           => q{{2} <{3}>},
    VERSION_FROM     => 'lib/DBIx/Schema/Changelog/{0}/{1}.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Schema/Changelog/{0}/{1}.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'strict'                     => 1.08,
        'Moose'                      => 2.1403,
        'warnings'                   => 1.23,
        'DBIx::Schema::Changelog'    => 'v{4}',
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Schema-Changelog-{0}-{1}-*' }
);~,
);

has manifest => (
    isa     => 'Str',
    is      => 'ro',
    default => q~Changes
Makefile.PL
MANIFEST
README.md
lib/DBIx/Schema/Changelog/{0}/{1}.pm
t/00-load.t
t/boilerplate.t
t/manifest.t
t/pod-coverage.t
t/pod.t
~,
);

has readme => (
    isa => 'Str',
    is  => 'ro',
    default =>
q~DBIx-Schema-Changelog-{0}-{1} - A new {0} module for DBIx-Schema-Changelog

MOTIVATION

Its a missing module which one has needed.

INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc DBIx::Schema::Changelog::{0}::{1}

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Schema-Changelog-{0}-{1}

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/DBIx-Schema-Changelog-{0}-{1}

    CPAN Ratings
        http://cpanratings.perl.org/d/DBIx-Schema-Changelog-{0}-{1}

    Search CPAN
        http://search.cpan.org/dist/DBIx-Schema-Changelog-{0}-{1}/
~,
);

has license => (
    isa     => 'Str',
    is      => 'ro',
    default => q~
LICENSE AND COPYRIGHT

Copyright (C) {0} {1}

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
mark, trade name, or logo of the Copyright Holder.

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
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

~,
);

has changes => (
    isa     => 'Str',
    is      => 'ro',
    default => q~Revision history for DBIx-Schema-Changelog-{0}-{1}

#========================================================================
# Version {2}  Date: {3} ({4})
#========================================================================

* First version, released on an unsuspecting world.
~,
);

has t_load => (
    isa     => 'Str',
    is      => 'ro',
    default => q~use Test::More tests => 2;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;

require_ok( 'DBIx::Schema::Changelog::{0}::{1}' );
use_ok 'DBIx::Schema::Changelog::{0}::{1}';~,
);

has t_boilerplate => (
    isa     => 'Str',
    is      => 'ro',
    default => q/#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        '$moduleNAME'   => qr~ - A new {0} for DBIx::Schema::Changelog ~,
        'boilerplate description'     => qr~Quick summary of what the module~,
        'stub function definition'    => qr~function[12]~,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok('README.md' =>
    "The README is used..."       => qr~The README is used~,
    "'version information here'"  => qr~to provide version information~,
  );

  not_in_file_ok(Changes =>
    "placeholder date\/time"       => qr(Date\/time)
  );

  module_boilerplate_ok('lib\/DBIx\/Schema\/Changelog\/{0}\/{1}.pm');


}/,
);

has t_manifest => (
    isa     => 'Str',
    is      => 'ro',
    default => q~#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tcm = 0.9;
eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if $@;

ok_manifest();~,
);

has t_pod_coverage => (
    isa     => 'Str',
    is      => 'ro',
    default => q~#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

use Test::Pod::Coverage 1.08;
use Pod::Coverage::TrustPod;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;
~,
);

has t_pod => (
    isa     => 'Str',
    is      => 'ro',
    default => q~#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}
 
# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;
 
all_pod_files_ok();~,
);

=head1 SUBROUTINES/METHODS

=head2 replace_spare

=cut

sub _replace_spare {
    my ( $string, $options ) = @_;
    $string =~ s/\{(\d+)\}/$options->[$1]/g;
    return $string;
}

=head2 write_file

=cut

sub _write_file {
    my ( $file, $text ) = @_;
    print " + $file\n";
    open( my $fh, '>>', $file );
    print $fh $text;
    close $fh;
}

1;    # End of DBIx::Schema::Changelog::Role::File

__END__

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

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
mark, trade name, or logo of the Copyright Holder.

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
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
