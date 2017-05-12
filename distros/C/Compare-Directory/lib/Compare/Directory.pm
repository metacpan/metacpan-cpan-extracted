package Compare::Directory;

$Compare::Directory::VERSION   = '1.25';
$Compare::Directory::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Compare::Directory - Interface to compare directories.

=head1 VERSION

Version 1.25

=cut

use strict; use warnings;
use Data::Dumper;

use CAM::PDF;
use Test::Excel;
use Test::Deep ();
use File::Compare;
use File::Basename;
use XML::SemanticDiff;
use Scalar::Util 'blessed';
use File::Spec::Functions;
use File::Glob qw(bsd_glob);

=head1 DESCRIPTION

The only  objective of the module is compare two directory contents. Currently it
compare the following file types:

    +----------------------+------------+
    | File Type            | Extension  |
    +----------------------+------------+
    | TEXT File            |   .txt     |
    | COMMA Seperated File |   .csv     |
    | PDF File             |   .pdf     |
    | XML File             |   .xml     |
    | EXCEL File           |   .xls     |
    +----------------------+------------+

=head1 CONSTRUCTOR

The constructor expects the two directories name with complete path.

   use strict; use warnings;
   use Compare::Directory;

   my $directory = Compare::Directory->new("./got-1", "./exp-1");

=cut

sub new {
    my ($class, $dir1, $dir2) = @_;

    die ("ERROR: Please provide two directories to compare.\n") unless (defined($dir1) && defined($dir2));
    die ("ERROR: Invalid directory [$dir1].\n") unless (-d $dir1);
    die ("ERROR: Invalid directory [$dir2].\n") unless (-d $dir2);

    # Borrowed from DirCompare [http://search.cpan.org/~gavinc/File-DirCompare-0.6/DirCompare.pm]
    my $self = {};
    $self->{name1} = $dir1;
    $self->{name2} = $dir2;
    $self->{dir1}->{basename $_} = 1 foreach bsd_glob(catfile($dir1, ".*"));
    $self->{dir1}->{basename $_} = 1 foreach bsd_glob(catfile($dir1, "*"));
    $self->{dir2}->{basename $_} = 1 foreach bsd_glob(catfile($dir2, ".*"));
    $self->{dir2}->{basename $_} = 1 foreach bsd_glob(catfile($dir2, "*"));

    delete $self->{dir1}->{curdir()} if $self->{dir1}->{curdir()};
    delete $self->{dir1}->{updir()}  if $self->{dir1}->{updir()};
    delete $self->{dir2}->{curdir()} if $self->{dir2}->{curdir()};
    delete $self->{dir2}->{updir()}  if $self->{dir2}->{updir()};

    $self->{_status} = 1;
    map { $self->{entry}->{$_}++ == 0 ? $_ : () } sort(keys(%{$self->{dir1}}), keys(%{$self->{dir2}}));
    $self->{report} = sub {
        my ($a, $b) = @_;
        if (!$b) {
            printf("Only in [%s]: [%s].\n", dirname($a), basename($a));
            $self->{_status} = 0;
        }
        elsif (!$a) {
            printf("Only in [%s]: [%s].\n", dirname($b), basename($b));
            $self->{_status} = 0;
        }
        else {
            printf("Files [%s] and [%s] differ.\n", $a, $b);
            $self->{_status} = 0;
        }
    };

    bless $self, $class;

    return $self;
}

=head1 METHODS

=head2 cmp_directory()

This  is  the  public  method that initiates the actual directory comparison. You
simply  call  this  method  against the object. Returns 1 if directory comparison
succeed otherwise returns 0.

   use strict; use warnings;
   use Compare::Directory;

   my $directory = Compare::Directory->new("./got-1", "./exp-1");
   $directory->cmp_directory();

=cut

sub cmp_directory {
    my ($self) = @_;

    foreach my $entry (keys %{$self->{entry}}) {
        my $f1 = catfile($self->{name1}, $entry);
        my $f2 = catfile($self->{name2}, $entry);
        next if (-d $f1 && -d $f2);

        if (!$self->{dir1}->{$entry}) {
            $self->{report}->($f1, undef);
        }
        elsif (!$self->{dir2}->{$entry}) {
            $self->{report}->(undef, $f2);
        }
        else {
            $self->{report}->($f1, $f2) unless _cmp_directory($f1, $f2);
            # Very strict about the order of elements in XML.
            # $self->{report}->($f1, $f2) if File::Compare::compare($f1, $f2);
        }
    }

    return $self->{_status};
}

sub _cmp_directory($$) {
    my ($file1, $file2) = @_;

    croak("ERROR: Invalid file [$file1].\n") unless(defined($file1) && (-f $file1));
    croak("ERROR: Invalid file [$file2].\n") unless(defined($file2) && (-f $file2));

    my $do_FILEs_match = 0;
    if ($file1 =~ /\.txt|\.csv/i) {
        $do_FILEs_match = 1 unless compare($file1, $file2);
    }
    elsif ($file1 =~ /\.xml/i) {
        my $diff = XML::SemanticDiff->new();
        $do_FILEs_match = 1 unless $diff->compare($file1, $file2);
    }
    elsif ($file1 =~ /\.pdf/i) {
        $do_FILEs_match = 1 if _cmp_pdf($file1, $file2);
    }
    elsif ($file1 =~ /\.xls/i) {
        $do_FILEs_match = 1 if compare_excel($file1, $file2);
    }

    return $do_FILEs_match;
}

sub _cmp_pdf($$) {
    my ($got, $exp) = @_;

    unless (blessed($got) && $got->isa('CAM::PDF')) {
        $got = CAM::PDF->new($got)
            || croak("ERROR: Couldn't create CAM::PDF instance with: [$got]\n");
    }

    unless (blessed($exp) && $exp->isa('CAM::PDF')) {
        $exp = CAM::PDF->new($exp)
            || croak("ERROR: Couldn't create CAM::PDF instance with: [$exp]\n");
    }

    return 0 unless ($got->numPages() == $exp->numPages());

    my $do_PDFs_match = 0;
    foreach my $page_num (1 .. $got->numPages()) {
        my $tree1 = $got->getPageContentTree($page_num, "verbose");
        my $tree2 = $exp->getPageContentTree($page_num, "verbose");
        if (Test::Deep::eq_deeply($tree1->{blocks}, $tree2->{blocks})) {
            $do_PDFs_match = 1;
        }
        else {
            $do_PDFs_match = 0;
            last;
        }
    }

    return $do_PDFs_match;
}

=head1 AUTHOR

Mohammad S Anwar, E<lt>mohammad.anwar@yahoo.comE<gt>

=head1 REPOSITORY

L<https://github.com/manwar/Compare-Directory>

=head1 BUGS

Please report any bugs or feature requests to C<bug-compare-directory at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Compare-Directory>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<File::DirCompare>

=item * L<File::Dircmp>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Compare::Directory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Compare-Directory>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Compare-Directory>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Compare-Directory>

=item * Search CPAN

L<http://search.cpan.org/dist/Compare-Directory/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Compare::Directory
