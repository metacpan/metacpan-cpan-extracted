package Bio::CIPRES::Output;

use 5.012;
use strict;
use warnings;

use Carp;
use XML::LibXML;
use Scalar::Util qw/blessed weaken/;

use Bio::CIPRES::Error;

sub new {

    my ($class, %args) = @_;

    my $self = bless {}, $class;

    croak "Must define user agent" if (! defined $args{agent});
    croak "Agent must be an LWP::UserAgent object"
        if ( blessed($args{agent}) ne 'LWP::UserAgent' );
    $self->{agent} = $args{agent};
    weaken( $self->{agent} );

    croak "Must define initial status" if (! defined $args{dom});
    $self->_parse_dom( $args{dom} );

    return $self;


}

sub size  { return $_[0]->{length}       };
sub name  { return $_[0]->{filename}     };
sub group { return $_[0]->{group}        };

sub download {

    my ($self, %args) = @_;

    my @a = $self->{url_download};
    push @a, ':content_file', $args{out}
        if (defined $args{out});

    my $res = $self->{agent}->get(@a)
        or croak "LWP internal error: $@";
    croak "Error saving file to disk"
        if (defined $args{out} && ! -e $args{out});

    die Bio::CIPRES::Error->new( $res->content )
        if (! $res->is_success);

    return $res->decoded_content;

}

sub _parse_dom {

    my ($self, $dom) = @_;

    # remove outer tag if necessary
    my $c = $dom->firstChild;
    $dom = $c if ($c->nodeName eq 'jobfile');

    $self->{handle}       = $dom->findvalue('jobHandle');
    $self->{filename}     = $dom->findvalue('filename');
    $self->{length}       = $dom->findvalue('length');
    $self->{group}        = $dom->findvalue('parameterName');
    $self->{url_download} = $dom->findvalue('downloadUri/url');

    # check for missing values
    map {length $self->{$_} || croak "Missing value for $_\n"} keys %$self;

    return;

}

1;

__END__

=head1 NAME

Bio::CIPRES::Output - a single CIPRES job output file

=head1 SYNOPSIS

    for my $output ($job->outputs) {

        print "filename:", $output->name, "\n";
        print "BIG FILE!!\n" if ($output->size > 1024**3);
        print "group:", $output->group, "\n";

        # get content
        my $content = $output->download;

        # or save directly to disk
        $output->download( 'out' => $output_filename );

    }

=head1 DESCRIPTION

C<Bio::CIPRES::Output> objects represent single output files produced by a job
run. Methods allow for querying simple file attributes and downloading the
file to memory or disk.

Objects of this class should not be created directly - they are returned by
methods calls to L<Bio::CIPRES::Job> objects.

=head1 METHODS

=over 4

=item B<name>

    my $fn = $output->name;

Returns the filename of the output as provided by the API.

=item B<size>

    my $bytes = $output->size;

Returns the size of the output file in bytes.

=item B<group>

    my $group = $output->group;

Returns the output group that the file is a member of.

=item B<download>

    my $content = $output->download;
    my $res = $output->download( 'out' => $filename );

Attempts to download the output file, and either returns the contents (if no
arguments are given) or saves them to disk (if the 'out' argument is provided
with a valid output filename). Throws an exception on any error - this will be
an object of type L<Bio::CIPRES::Error> if the error occurs on the server
end.

=back

=head1 CAVEATS AND BUGS

Please report bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


