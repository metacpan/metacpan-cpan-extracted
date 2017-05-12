package CGI::UploadEasy;

use 5.006;
use strict;
use warnings;
use CGI 2.76;
use File::Spec;
use Carp;

$Carp::CarpLevel = 1;

our $VERSION = '1.00';
# $Id: UploadEasy.pm,v 1.8 2009/02/01 21:04:22 gunnarh Exp $

=head1 NAME

CGI::UploadEasy - Facilitate file uploads

=head1 SYNOPSIS

    use CGI::UploadEasy;
    my $ue = CGI::UploadEasy->new(-uploaddir => '/path/to/upload/dir');
    my $cgi = $ue->cgiobject;
    my $info = $ue->fileinfo;

=head1 DESCRIPTION

C<CGI::UploadEasy> is a wrapper around, and relies heavily on, L<CGI.pm|CGI>. Its
purpose is to provide a simple interface to the upload functionality of C<CGI.pm>.

At creation of the C<CGI::UploadEasy> object, the module saves one or more files
from a file upload request in the upload directory, and information about uploaded
files is made available via the B<fileinfo()> method. C<CGI::UploadEasy> performs
a number of tests, which limit the risk that you encounter difficulties when
developing a file upload application.

=head2 Methods

=cut

sub new {
    my $class = shift;
    my $self = {
        maxsize => 1000,
        &_argscheck,
    };

    $CGI::POST_MAX = $self->{maxsize} * 1024;
    $CGI::DISABLE_UPLOADS = 0;
    $CGITempFile::TMPDIRECTORY = $self->{tempdir} if $self->{tempdir};
    $self->{cgi} = CGI->new;
    if ( my $status = $self->{cgi}->cgi_error ) {
        _error($self, $status, "Post too large: Maxsize $self->{maxsize} KiB exceeded.");
    }

    if ( $ENV{REQUEST_METHOD} eq 'POST' and $ENV{CONTENT_TYPE} !~ /^multipart\/form-data\b/i ) {
        _error($self, '400 Bad Request', 'The content-type at file uploads shall be '
         . "'multipart/form-data'.<br />\nMake sure that the 'FORM' tag includes the "
         . 'attribute: enctype=&quot;multipart/form-data&quot;');
    }

    $self->{files} = _upload($self);

    bless $self, $class;
}

=over 4

=item B<my $ue = CGI::UploadEasy-E<gt>new( -uploaddir =E<gt> $dir [ , -maxsize =E<gt> $kibibytes, ... ] )>

The B<new()> constructor takes hash style arguments. The following arguments are
recognized:

=over 4

=item B<-uploaddir>

Specifying the upload directory is mandatory.

=item B<-tempdir>

To control which directory will be used for temporary files, set the -tempdir
argument.

=item B<-maxsize>

Specifies the maximum size in KiB (kibibytes) of a POST request data set.
Default limit is 1,000 KiB. To disable this ceiling for POST requests, set a
negative -maxsize value.

=back

=back

=cut

sub cgiobject {
    my $self = shift;
    $self->{cgi};
}

=over 4

=item B<$ue-E<gt>cgiobject>

Returns a reference to the C<CGI> object that C<CGI::UploadEasy> uses internally,
which gives access to all the L<CGI.pm|CGI> methods.

If you prefer the function-oriented style, you can import a set of methods
instead. Example:

    use CGI qw/:standard/;
    print header;

=back

=cut

sub fileinfo {
    my $self = shift;
    if ( @_ ) { croak "The 'fileinfo' method does not take arguments" }
    $self->{files};
}

=over 4

=item B<$ue-E<gt>fileinfo>

Returns a reference to a 'hash of hashes' with info about uploaded files. The info
may be of use for a result page and/or an email notification, and it lets you use
e.g. MIME type and file size as criteria for how to further process the files.

=back

=cut

sub otherparam {
    my $self = shift;
    if ( @_ ) { croak "The 'otherparam' method does not take arguments",
      "--use CGI.pm's 'param' method to access values" }
    my $cgi = $self->{cgi};
    grep ! ref $cgi->param($_), $cgi->param;
}

=over 4

=item B<$ue-E<gt>otherparam>

The B<otherparam()> method returns a list of parameter names besides the names
of the file select controls that were used for file uploads. To access the values,
use L<CGI.pm|CGI>'s B<param()> method.

=back

=cut

sub _argscheck {
    my %args;
    my %names = (
        -uploaddir => 'uploaddir',
        -tempdir   => 'tempdir',
        -maxsize   => 'maxsize',
    );
    local $Carp::CarpLevel = 2;

    @_ % 2 == 0 and @_ > 0 or croak 'One or more name=>argument pairs are ',
      'expected at the creation of the CGI::UploadEasy object';

    while ( my $arg = shift ) {
        my $name = lc $arg;
        $names{$name} or croak "Unknown argument: '$arg'";
        $args{ $names{$name} } = shift;
    }
    $args{uploaddir} or croak "The compulsory argument '-uploaddir' is missing";

    for my $dir ( @args{ grep exists $args{$_}, qw/uploaddir tempdir/ } ) {
        -d $dir or croak "Can't find any directory '$dir'";
        -r $dir and -w _ and -x _ or croak 'The user this script runs as ',
          "does not have write access to '$dir'";
    }
    $args{maxsize} and $args{maxsize} !~ /^-?\d+$/
      and croak "The '-maxsize' argument shall be an integer";

    %args;
}

sub _upload {
    my $self = shift;
    my $cgi = $self->{cgi};
    my %files;

    for my $TEMP ( map $cgi->upload($_), $cgi->param ) {
        ( my $name = $TEMP ) =~ s#.*[\]:\\/]##;
        $name =~ tr/ /_/ unless $^O eq 'MSWin32';
        $name =~ tr/-+@a-zA-Z0-9. /_/cs;
        ($name) = $name =~ /^([-+@\w. ]+)$/;
        my $path = File::Spec->catfile( $self->{uploaddir}, $name );

        # don't overwrite file with same name
        my $i = 2;
        while (1) {
            last unless -e $path;
            $name =~ s/([^.]+?)(?:_\d+)?(\.|$)/$1_$i$2/;
            $path = File::Spec->catfile( $self->{uploaddir}, $name );
            $i++;
        }

        my ($cntrname) = $cgi->uploadInfo($TEMP)->{'Content-Disposition'} =~ /\bname="([^"]+)"/;
        $files{$name} = {
            ctrlname => $cntrname,
            mimetype => $cgi->uploadInfo($TEMP)->{'Content-Type'},
        };

        open my $OUT, '>', $path or die "Couldn't open file: $!";
        if ( $files{$name}{mimetype} =~ /^text\b/ ) {
            binmode $TEMP, ':crlf';
            print $OUT $_ while <$TEMP>;
        } else {
            binmode $OUT, ':raw';
            while ( read $TEMP, my $buffer, 1024 ) {
                print $OUT $buffer;
            }
        }
        close $TEMP or die $!;  # so the temporary file gets deleted
        close $OUT or die $!;   # so file size can be grabbed below

        $files{$name}{bytes} = -s $path;
    }

    \%files;
}

sub _error {
    my ($self, $status, $msg) = @_;
    my $cgi = $self->{cgi};
    print $cgi->header(-status => $status),
          $cgi->start_html(-title => "Error $status"),
          $cgi->h1('Error'),
          $cgi->tt($msg),
          $cgi->end_html;
    exit 1;
}

1;

__END__

=head1 EXAMPLE

This script handles a file upload request by saving a number of files in the
upload directory and printing the related info:

    #!/usr/bin/perl -T
    use strict;
    use warnings;
    use CGI::UploadEasy;
    use Data::Dumper;
    my $ue = CGI::UploadEasy->new(-uploaddir => '/path/to/upload/dir');
    my $info = $ue->fileinfo;
    my $cgi = $ue->cgiobject;
    print $cgi->header('text/plain');
    print Dumper $info;

=head1 CAVEATS

Since C<CGI::UploadEasy> is meant for file uploads, it requires that the request
data is C<multipart/form-data> encoded. An C<application/x-www-form-urlencoded>
POST request will cause a fatal error.

No C<CGI> object may be created before the C<CGI::UploadEasy> object has been
created, or else the upload will fail. Likewise, if you import method names from
C<CGI.pm>, be careful not to call any C<CGI> functions before the creation of the
C<CGI::UploadEasy> object.

=head1 AUTHOR, COPYRIGHT AND LICENSE

  Copyright (c) 2005-2009 Gunnar Hjalmarsson
  http://www.gunnar.cc/cgi-bin/contact.pl

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI.pm|CGI>

=cut

