# this is a dumb trick to work around GFF.pm's current inability to
# take data from memory.  It makes the in-memory data look like a filehandle.
package GFF::Filehandle;

sub TIEHANDLE {
    my ($package,$datalines) = @_;
    return bless $datalines,$package;
}

sub READLINE {
    my $self = shift;
    return shift @$self;
}

1;
