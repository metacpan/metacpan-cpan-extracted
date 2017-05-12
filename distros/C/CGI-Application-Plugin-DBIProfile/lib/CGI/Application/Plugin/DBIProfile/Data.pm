package CGI::Application::Plugin::DBIProfile::Data;
use strict;
use base 'DBI::ProfileData';

use vars qw($VERSION);
$VERSION = "1.0";

use Symbol;


# override _read_files
# this is only so that we can add support for filehandles, rather than just files.
sub _read_files {
    my $self = shift;
    my $files = $self->{Files};
    my $read_header = 0;

    foreach my $filename (@$files) {

        my $fh;
        if (!ref($filename) && ref(\$filename) ne 'GLOB') {
            # Assume $filename is a filename
            $fh = gensym;
            open($fh, $filename)
              or croak("Unable to read profile file '$filename': $!");
        } else {
            $fh = $filename;
            $filename = ref($fh).' object';
        }

        $self->_read_header($fh, $filename, $read_header ? 0 : 1);
        $read_header = 1;
        $self->_read_body($fh, $filename);
        close($fh);
    }

    # discard node_lookup now that all files are read
    delete $self->{_node_lookup};
}
