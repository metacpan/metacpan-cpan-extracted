package Apache::AxKit::Provider::PodSAX;
use strict;
use vars qw/@ISA $VERSION/;
@ISA = ('Apache::AxKit::Provider::File');
$VERSION = '1.00';

use Apache::AxKit::Provider::File;
use XML::SAX::Writer;
use Pod::SAX;

sub get_strref {
    my $self = shift;
    if ($self->_is_dir()) {
        throw Apache::AxKit::Exception::IO(
          -text => "$self->{file} is a directory - please overload File provider and use AxContentProvider option");
    }

    my $outie;
    my $w = XML::SAX::Writer->new( Output => \$outie );
    my $generator = Pod::SAX->new( Handler => $w) ;

    eval {
      $generator->parse_uri( $self->{file} );
        };

    if (my $error = $@) {
        throw Apache::AxKit::Exception::IO(
          -text => "PodSAX Generator Error: $error");
    }
    #warn "OUTIE $outie \n";
    return \$outie
}

sub process {
    my $self = shift;

    my $file = $self->{file};

    unless ($self->exists()) {
        AxKit::Debug(5, "file '$file' does not exist or is not readable");
        return 0;
    }

    if ( $self->_is_dir ) {
        if ($AxKit::Cfg->HandleDirs()) {
            return 1;
        }
        # else
        AxKit::Debug(5, "'$file' is a directory");
        return 0;
    }

    local $^W;
    if (($file =~ /\.pod$/i) ||
        ($self->{apache}->content_type() =~ /^text\/pod/)
        ) {
            return 1;
    }

    AxKit::Debug(5, "'$file' not recognised as POD");
    return 0;
}

sub get_fh {
    throw Apache::AxKit::Exception::IO(
          -text => "Can't get filehandles from POD"
    );
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::AxKit::Provider::PodSAX - Dynamically Serve POD Files as XML 

=head1 SYNOPSIS

  <FilesMatch "\.pod">
    AddHandler axkit .pod
    AxContentProvider Apache::AxKit::Provider::PodSAX
    # styling directives here...
  </FilesMatch>

=head1 DESCRIPTION

This module allows you to invisibly serve POD documents (embedded, or not)
as XML through AxKit. See the docs for Pod::SAX for the grammar that
it uses to markup the POD.

=head1 AUTHOR

Kip Hampton, E<lt>khampton@totalcinema.comE<gt>

=head1 SEE ALSO

L<Pod::SAX> L<AxKit>.

=cut

