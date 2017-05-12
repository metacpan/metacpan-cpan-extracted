# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

=encoding utf8

=head1 NAME

Cv::BGCodeBookModel - Perl extension for OpenCV BGCodeBookModel

=head1 SYNOPSIS

 use Cv::BGCodeBookModel;

=cut

package Cv::BGCodeBookModel;

use 5.008008;
use strict;
use warnings;
use Cv ();

our $VERSION = '0.29';

require XSLoader;
XSLoader::load('Cv::BGCodeBookModel', $VERSION);

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = grep /^(IPL|CV|cv)/, (keys %Cv::BGCodeBookModel::);

our %EXPORT_TAGS = (
	'all' => \@EXPORT_OK,
	);

our @EXPORT = ( );

# { package Cv; Cv::BGCodeBookModel->import(qw(:all)); }
# push(@Cv::EXPORT_OK, @EXPORT_OK);

*AUTOLOAD = \&Cv::autoload;

# ============================================================
#  Background/foreground segmentation
# ============================================================

=head1 DESCRIPTION

=head2 METHOD

=over

=item new(), cvCreateBGCodeBookModel()

 my $model = Cv::BGCodeBookModel->new();

=item cvReleaseBGCodeBookModel();

=cut

sub Cv::cvCreateBGCodeBookModel { goto &cvCreateBGCodeBookModel }
push(@Cv::EXPORT_OK, 'cvCreateBGCodeBookModel');
sub Cv::CreateBGCodeBookModel { shift; goto &cvCreateBGCodeBookModel }
sub new { goto &Cv::CreateBGCodeBookModel }
sub DESTROY { goto &cvReleaseBGCodeBookModel }

=item BGCodeBookClearStale(), ClearStale(), cvBGCodeBookClearStale()

 $model->ClearStale($staleThresh, $roi, $mask);

=cut

sub ClearStale { goto &BGCodeBookClearStale }
sub BGCodeBookClearStale { goto &cvBGCodeBookClearStale }

=item BGCodeBookDiff(), Diff(), cvBGCodeBookDiff()

 $model->Diff($image, $mask, $roi);

=cut

sub Diff { goto &BGCodeBookDiff }
sub BGCodeBookDiff { goto &cvBGCodeBookDiff }

=item BGCodeBookUpdate(), Update(), cvBGCodeBookUpdate()

 $model->Update($image, $roi, $mask);

=cut

sub Update { goto &BGCodeBookUpdate }
sub BGCodeBookUpdate { goto &cvBGCodeBookUpdate }

=item SegmentFGMask(), cvSegmentFGMask()

=item cbBounds($value);

 my $value = $model->cbBounds;
 my $oldvalue = $model->cbBounds($value);

=item modMax

 my $value = $model->modMax;
 my $oldvalue = $model->modMax($value);

=item modMin

 my $value = $model->modMin;
 my $oldvalue = $model->modMin($value);

=item t

 my $t = $model->t;

=back

=cut

1;
__END__

=head2 EXPORT

None by default.


=head1 SEE ALSO

http://github.com/obuk/Cv-Olive

=head1 AUTHOR

MASUDA Yuta E<lt>yuta.cpan@gmail.comE<gt>


=head1 LICENCE

Copyright (c) 2013 by MASUDA Yuta.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
