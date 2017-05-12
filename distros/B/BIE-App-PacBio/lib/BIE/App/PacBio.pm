package BIE::App::PacBio;
our $VERSION = '0.01';
use Moose;
use namespace::autoclean;
use v5.10;
use BIE::Data::HDF5::File;

has 'file' => (is => 'ro',
	       isa => 'Str',
	       required => 1
	      );

has 'h5' => (is => 'rw',
	     isa => 'BIE::Data::HDF5::File',
	    );

has 'content' => (is => 'ro',
		  isa => 'ArrayRef[Str]',
		  lazy => 1,
		  default => sub {
		    my $self = shift;
		    my $objs = $self->h5->list;
		    [grep { $objs->{$_} eq 'dataset' 
			  } keys %$objs]
		  },
		 );

has 'data' => (
	       is => 'ro',
	       lazy => 1,
	       default => sub {
		 my $self = shift;
		 return {map {$_ => $self->h5->pwd->openData($_) } @{$self->content}}; 
},
);

has 'lens' => (
	       is => 'rw',
	       isa => 'ArrayRef[Int]',
);

has 'hitIdx' => (
		 is => 'ro',
		 isa => 'ArrayRef[Int]',
		 writer => 'getHitIdx',
);

around 'lens' => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig unless @_;
  my $d = shift;
  $self->getHitIdx([grep {$d->[$_]>0} 0..$#$d]);
  my @lens = @{$d}[@{$self->hitIdx}];
  $self->$orig(\@lens);
};

sub read {
  my $self = shift;
  return undef unless @_;
  my $data = $self->h5->pwd->openData($_[0]);
  return $data->read;
}

sub split {
  my $self = shift;
  my $ori = $self->read($_[0]);
  my $p = 0;
  return [map {my $r=[@{$ori}[$p .. ($p+$_-1)]]; 
	       $p+=$_; 
	       $r} @{$self->lens}];
}

sub BUILD {
  my $self = shift;
  $self->h5(BIE::Data::HDF5::File->new(h5File => $self->file));
}

__PACKAGE__->meta->make_immutable;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

BIE::App::PacBio - An application for QC of PacBio CCS sequencing data.

=head1 SYNOPSIS

It is very easy to use.
After installation, just call "CCSQC.pl" followed by path of bas.h5 file.

	CCSQC.pl pacbio.bas.h5

=head1 DESCRIPTION

This module installs an application (or more in future) to check sequencing data quality produced by PacBio RS system. 
PacBio RS is a 3rd-generation sequencing technology which presents novel exciting features.
Here this module summarizes our experiences in dealing with PacBio data.
Currently it diggs raw data and shows interesting figures for researchers to have ideas about data quality.
Besides the usage mentioned above, 
user could also utilize functions in this package in order to customize scripts for particular questions.

=head1 INSTALLATION

There are two ways to install BIE::App::PacBio.
User could install it in a working directory,
which is the usual way for many researchers who have no hardware rights;
another option is for administrator to install it for all users.

=head2 PREREQUISITES

Unfortunately, as every software,
there may be some annoying installations you must have prior to using this module.
They could all get installed with "cpan".

=over

=item *

Moose

=item * 

namespace::autoclean

=item *

PDL, PDL::Graphics::PLplot, Cairo

=back

=head2 FOR ORDINARY USER

=over

=item 1

Go to our website and download L<the zip file|http://david.abcc.ncifcrf.gov/manuscripts/PacBio/CCSQC.tar.gz>.

=item 2

Unzip the downloaded file and enter the created directory.

=item 3 

Type "make". A executable script will be here.
Remember to open another terminal to use it.
Ask your administrator for help if you unluckily get error about lacking some prerequisites.

=back

=head2 FOR POWER USER

Start a terminal, type "cpan" and press return, then type "install BIE::App::PacBio".
That's it.

=head2 ATTRIBUTES AND METHODS

Following is simple introduction of involved attributes and methods in this module.
Users don't have to know these unless tweaking is wanted.

=over

=item *

"file": The HDF5 file name. It is the only argument to construct a PacBio object.

=item *

"h5": A HDF5 object.

=item *

"content": A list of all datasets in HDF5 file.

=item *

"data": A hash contains all datasets in HDF5 file, which may occupy huge memories. Don't use it without a reasonable purpose.

=item *

"hitIdx": The index of hit smart cell holes.

=item *

"lens": The read lengths of sequencing data.

=item *

"read": Given a dataset, "read" return corresponding data.

=back

=head1 SEE ALSO

There is an example data L<here|http://david.abcc.ncifcrf.gov/manuscripts/PacBio_Data>.

=head1 AUTHOR

Xin Zheng, E<lt>zhengxin@mail.nih.govE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by LIB/SAIC-Frederick at Frederick National Laboratory for Cancer Research.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

By the way, B<FNL> has no responsibility for any unexpected result
related with BIE::App::PacBio.
The only one to be blamed is listed above.

=cut
