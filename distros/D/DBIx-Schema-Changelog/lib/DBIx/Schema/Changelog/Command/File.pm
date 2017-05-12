package DBIx::Schema::Changelog::Command::File;

=head1 NAME

DBIx::Schema::Changelog::Command::File - Create a new file reader module from template for DBIx::Schema::Changelog!

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings FATAL => 'all';
use Moose;
use File::Path qw( mkpath );

with 'DBIx::Schema::Changelog::Command::Base';
############# End of encapsulated class data.      ########################

has file => (
    isa     => 'Str',
    is      => 'ro',
    default => q~package DBIx::Schema::Changelog::File::{0};

=head1 NAME

DBIx::Schema::Changelog::File::{0} - module for DBIx::Schema::Changelog::File to load changeset from {0} files.

=head1 VERSION

=over 4

Version 0.1.0

=cut

our $VERSION = '0.1.0';

use {4};
use strict;
use warnings FATAL => 'all';
use Moose;

with 'DBIx::Schema::Changelog::File';

has tpl_main => (
    isa => 'Str',
    is => 'ro',
    default => '',
);

has tpl_sub => (
    isa => 'Str',
    is => 'ro',
    default => '',
);

has ending => (
    is => 'ro',
    isa => 'Str',
    default => '.',
);

=back

=head1 SUBROUTINES/METHODS

=over 4

=item load

    Called to load defined Yaml files

=cut

sub load{}

no Moose;
__PACKAGE__->meta->make_immutable;

1;    # End of DBIx::Schema::Changelog::File::{0}

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-schema-changelog-driver-{0} at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Schema-Changelog-File-{0}>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Schema::Changelog::File::{0}


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Schema-Changelog-File-{0}>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Schema-Changelog-File-{0}>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Schema-Changelog-File-{0}>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Schema-Changelog-File-{0}/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

{1}, C<< <{2}> >>

~,
);

=head1 SUBROUTINES/METHODS

=head2 make

=cut

sub make {
    my ( $self, $config ) = @_;
    die "No author defined!"       unless $config->{author};
    die "No mail address defined!" unless $config->{email};
    die "No new type defined!"     unless $config->{type};
    my $dir = File::Spec->catfile( $config->{dir},
        "DBIx-Schema-Changelog-File-$config->{type}" );
    my $path =
      File::Spec->catfile( $dir, 'lib', 'DBIx', 'Schema', 'Changelog', 'File' );
    mkpath( $path, 0755 );
    $path = File::Spec->catfile( $dir, 't' );
    mkpath( $path, 0755 );

    #module
    $path =
      File::Spec->catfile( $dir, 'lib', 'DBIx', 'Schema', 'Changelog', 'File',
        "$config->{type}.pm" );
    _write_file(
        $path,
        _replace_spare(
            $self->file(),
            [
                $config->{type},  $config->{author},
                $config->{email}, $self->year(),
                '5.10.0'
            ]
        )
    );
    _write_file(
        $path,
        _replace_spare(
            $self->license(), [ $self->year(), $config->{author} ]
        )
    );
    _write_file( $path, qq~\n=cut\n~ );

    #AUXILIARY
    $path = File::Spec->catfile( $dir, 'README.md' );
    _write_file(
        $path,
        _replace_spare(
            $self->readme(),
            [ 'File', $config->{type}, $config->{author}, $config->{email} ]
        )
    );
    _write_file(
        $path,
        _replace_spare(
            $self->license(), [ $self->year(), $config->{author} ]
        )
    );

    _write_file( "$dir/MANIFEST",
        _replace_spare( $self->manifest(), [ 'File', $config->{type} ] ) );

    _write_file(
        "$dir/Makefile.PL",
        _replace_spare(
            $self->makefile(),
            [
                'File',           $config->{type}, $config->{author},
                $config->{email}, $VERSION
            ]
        )
    );
    _write_file(
        "$dir/Changes",
        _replace_spare(
            $self->changes(),
            [
                'File',  $config->{type},
                '0.1.0', '1970/01/01',
                $config->{author}
            ]
        )
    );

    #tests
    _write_file( "$dir/t/00-load.t",
        _replace_spare( $self->t_load(), [ 'File', $config->{type} ] ) );
    _write_file( "$dir/t/boilerplate.t",
        _replace_spare( $self->t_boilerplate(), [ 'File', $config->{type} ] ) );
    _write_file( "$dir/t/manifest.t",
        _replace_spare( $self->t_manifest(), [] ) );
    _write_file( "$dir/t/pod-coverage.t",
        _replace_spare( $self->t_pod_coverage(), [] ) );
    _write_file( "$dir/t/pod.t", _replace_spare( $self->t_pod(), [] ) );
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

1;

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
