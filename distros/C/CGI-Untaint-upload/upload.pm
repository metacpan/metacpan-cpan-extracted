package CGI::Untaint::upload;
use strict;
use base 'CGI::Untaint::object';

sub _untaint {
    my $self = shift;
    my $fh = $self->value;
    local $/; 
    my $file = {
        filename => $fh,
        payload  => <$fh>
    };
    {
        no strict 'refs';
        for my $field (qw(filename payload)) {
            my $meth = "_untaint_${field}_re";
            unless ($file->{$field} =~ $self->$meth()) {
                $self->{_ERR} = "Untaint failed";
                return;
            }
            $file->{$field} = $1;
         }
    }
    $self->value($file);
}

sub _untaint_filename_re { qr/(.*)/  }
sub _untaint_payload_re  { qr/(.*)/s }

our $VERSION = '1.0';

1;
__END__

=head1 NAME

CGI::Untaint::upload - receive a file upload

=head1 SYNOPSIS

    my $handler = CGI::Untaint->new( map { $_ => $cgi->param($_) } $cgi->param);
    # NOT my $handler = CGI::Untaint->new( $cgi->Vars ); !

    $file = $handler->extract(-as_upload => "uploaded");
    print "File name was ", $file->{filename}, "\n";
    print "File contents: \n";
    print $file->{payload};

=head1 DESCRIPTION

This L<CGI::Untaint> handler receives a file from an upload field,
returning its filename and contents. This may be used as a base class
for validating that a file upload conforms to certain properties.

It's important that you use C<< CGI->param >> rather than C<< CGI->Vars >>
as the latter only returns the uploaded file's name and not its
contents.

=head1 SUBCLASSING

By default, the class does no taint checking, blindly untainting both
the filename and the contents; this may not be what you want. You can
subclass this module and override the C<_untaint_filename_re> and
C<_untaint_payload_re> methods to control the regular expression used
to untaint these data. In addition, the usual L<CGI::Untaint::object>
C<is_valid> method can be overriden to perform more checks on the data.

=head1 AUTHOR

Simon Cozens, C<simon@kasei.com>

=head1 SEE ALSO

L<CGI::Untaint>.

=cut
