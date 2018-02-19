package App::CopyrightImage;

use 5.006;
use warnings;
use strict;

use Exporter qw(import);
use File::Basename;
use File::Copy;
use File::Find::Rule;
use Image::ExifTool qw(:Public);

our @EXPORT = qw(imgcopyright);

our $VERSION = '1.01';

sub imgcopyright {
    my (%data) = @_;

    die "need to supply the 'image' argument!\n" if ! $data{src};
    if (! $data{name} && (! $data{check} && ! $data{remove})){
        die "need to supply the 'name' argument\n";
    }
    $data{year} = (localtime(time))[5] + 1900;

    if ($data{dst} && -d $data{dst}){
        $data{basename} = $data{dst};
    }
    elsif (-d $data{src})
    {
        $data{basename} = $data{src};
    }
    else {
        $data{basename} = dirname $data{src};
    }

    if (-d $data{src}){
        @{ $data{images} } = File::Find::Rule->file()
                                     ->name('*.jpg', '*.jpeg')
                                     ->maxdepth(1)
                                     ->in($data{src});
    }
    else {
        push @{ $data{images} }, $data{src};
    }

    if ($data{check}){
        return _check(\%data);
    }
    else {
        _exif(\%data);
    }
}
sub _exif {
    my $data = shift; 

    my $dst = $data->{dst} 
        ? $data->{dst} 
        : "$data->{basename}/ci";
    
    if (! -d $dst){
        mkdir $dst
          or die "can't create the destination image directory $dst!: $!";
    }

    my $et = Image::ExifTool->new;
    my %errors;

    for my $img (@{ $data->{images} }){

        # original
        
        $et->ExtractInfo($img);

        if ($data->{remove}){
            $et->SetNewValue('Copyright', '');
            $et->SetNewValue('Creator', '');
            $et->WriteInfo($img, "$img.tmp");
            move "$img.tmp", $img;
            next;
        }

        my $cp = $et->GetValue('Copyright');
        my $cr = $et->GetValue('Creator');

        if (! $data->{force} && ($cp || $cr)){
            my $set = "Copyright is already set;" if $cp;
            $set .= " Creator is already set;" if $cr;
            $errors{$img} = $set;
            next;
        }
        
        $et->SetNewValue('Copyright', "Copyright (C) $data->{year} by $data->{name}");
        my $creator_string = $data->{name};
        $creator_string .= " ($data->{email})" if $data->{email};

        $et->SetNewValue('Creator', $creator_string);

        my $ci_img = (fileparse($img))[0];
        $ci_img = "$dst/ci_$ci_img";
       
        # write out the new image

        $et->WriteInfo($img, $ci_img);

        # updated

        $et->ExtractInfo($ci_img);

        $errors{$img} = "failed to add Copyright; "
          if ! $et->GetValue('Copyright');

        $errors{$img} .= "failed to add Creator"
          if ! $et->GetValue('Creator');
    }
    return %errors;
}
sub _check {
    my $data = shift;

    my $et = Image::ExifTool->new;

    for (@{ $data->{images} }){
        $et->ExtractInfo($_);
        my $cp = $et->GetValue('Copyright');
        my $cr = $et->GetValue('Creator');

        my $err_str;
        $err_str .= " missing Copyright; " if ! $cp;
        $err_str .= " missing Creator; " if ! $cr;

        print "$_: $err_str\n" if $err_str;
    }
    return ();
}

1;
__END__

=head1 NAME

App::CopyrightImage - Easily add Copyright information to your images

=for html
<a href="http://travis-ci.org/stevieb9/p5-app-copyrightimage"><img src="https://secure.travis-ci.org/stevieb9/p5-app-copyrightimage.png"/></a>
<a href="https://ci.appveyor.com/project/stevieb9/p5-app-copyrightimage"><img src="https://ci.appveyor.com/api/projects/status/br01o72b3if3plsw/branch/master?svg=true"/></a>
<a href='https://coveralls.io/github/stevieb9/p5-app-copyrightimage?branch=master'><img src='https://coveralls.io/repos/stevieb9/p5-app-copyrightimage/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

Modified copy of images will be placed into a new C<ci> directory within the
directory you specify. If no directory is specified, we'll create it in the
current working directory. All new images will be prefixed with C<ci_>.

    # set copyright

    imgcopyright -i picture.jpg -n "Steve Bertrand" -e "steveb@cpan.org"

    # all pics in a directory

    imgcopyright -i /home/user/Pictures -n "Steve Bertrand"

    # find images without copyright info

    imgcopyright -i /home/user/Pictures -c

    # specify an alternate output directory

    imgcopyright -i /home/user/Pictures -n "steve" -d ~/mypics

    # replace a previous copyright

    imgcopyright -i picture.jpg -n "steve" -f

=head1 DESCRIPTION

This C<imgcopyright> application allows you to add copyright information to
the EXIF data within image files. It also allows you to check images for
missing copyright info and remove info.

It works on individual files, as well as recurses (top-level only) of a
supplied directory.

It does NOT modify the original file (except for C<remove>). We create a 
subdirectory named C<ci> in whatever path you specify (current working 
directory if a path is not sent in), and we then take a copy of each original
file, modify it, prefix the filename with a C<ci_>, and place it into the 
new C<ci> directory.

=head1 ARGUMENTS

=head2 -i, --image

Mandatory in all cases.

Name of a single image file, or a directory containing image files. In the case
of a directory, we'll iterate over the top level, and work on all image files
found.

=head2 -n, --name

Mandatory, unless using C<--check>.

This is the name that will be used in the copyright string for the C<Copyright>
EXIF tag, as well as the C<Creator> tag.

=head2 -e, --email

Optional.

This is appended to the C<--name> when populating the C<Creator> EXIF tag if
it is sent in.

=head2 -c, --check

Optional.

Checks for missing C<Copyright> and/or C<Creator> EXIF tags in the image(s)
sent in with the C<--image> option.

=head2 -d, --dst

Optional.

By default, we use the directory sent in with C<--image> (current working
directory if a path isn't provided), and put all modified images in a new C<ci>
directory under it. 

Send in a directory path with this option and we'll put the image files there
instead.

=head2 -r, --remove

Optional.

WARNING: This option DOES edit the original file, and does not make a copy
first.

Removes copyright EXIF information for files sent in with C<--image>.

=head2 -f, --force

By default, if an image already has EXIF copyright information, we skip
over it and do nothing. Set this option to overwrite any found copyright
info.

=head1 App::CopyrightImage API

=head2 EXPORTS

Exports C<imgcopyright> by default.

=head2 FUNCTIONS

=head3 imgcopyright(%opts)

Sets up various configurations, and then executes the EXIF changes to images
sent in.

We set the C<Copyright> EXIF tag to C<Copyright (C) YEAR by NAME>, where 
C<YEAR> is auto-generated, and C<NAME> is sent in as an option (see below).

We also set the C<Creator> EXIF tag to C<NAME (EMAIL)>. If C<EMAIL> is not
sent in as an option, it, and the parens around it will be omitted.

Returns a hash reference with the following keys: C<ok> and C<fail>. Each key
contains an array reference. The former contains a list of the image names
that succeeded, and the latter, a list of image names that failed.

Options:

=head4 image

A string containing either an image filename (including full path if not
local), or the name of a directory containing images. If the value is a
directory, we'll operate on all images in that dir.

We will, by default, create a new sub-directory named C<ci> in the directory 
found in the value, and if the directory is current working directory, we'll 
create the sub directory there.

All updated images will be copied into the new C<ci> directory with the same
filename, with a <C>ci_</c> prepended to it.

Eg: C<"/home/user/Pictures">

=head4 check

We won't make any changes, we'll simply check all images specified with the
C<image> option, and if they are missing either C<Copyright> or C<Creator>
EXIF data, we'll print this information to C<STDOUT>.

=head4 name

A string containing the name you want associated with the copyright notice. It
will be used in both the C<Copyright> and C<Creator> EXIF tags.

Eg: C<"Steve Bertrand">

=head4 email

A string containing the email address of the copyright holder. This will be
included in the C<Creator> EXIF tag if sent in.

Eg: C<"steveb@cpan.org">

=head4 dst

A string containing the name of a directory to be used to store the manipulated
images. By default, we use the path sent in with the C<image> option.

Eg: C<"/home/user/backup">

=head4 remove

Bool. If set, we'll remove all copyright information on the image(s).

=head4 force

Bool. If set, if an image already has copyright information set, we'll
overwrite it. By default we skip these files.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017,2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
