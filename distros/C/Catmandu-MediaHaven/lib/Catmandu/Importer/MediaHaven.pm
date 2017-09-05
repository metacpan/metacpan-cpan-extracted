package Catmandu::Importer::MediaHaven;

=head1 NAME

Catmandu::Importer::MediaHaven - Package that imports Zeticon MediaHaven records

=head1 SYNOPSIS

   # From the command line
   $ cat catmandu.yml
   ---
   importer:
        mh:
            package: MediaHaven
            options:
                url: https://archief.viaa.be/mediahaven-rest-api/resources/media
                username: ...
                password: ...
   $ catmandu convert mh to YAML

   use Catmandu

   my $importer = Catmandu->importer('BagIt',
                        url      => ... ,
                        username => ... ,
                        password => ... ,
                  );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });


=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> the importer can
be configured with the following parameters:

=over

=item url

Required. The URL to the MediaHaven REST endpoint.

=item username

Required. Username used to connect to MediaHaven.

=item password

Required. Password used to connect to MediaHaven.

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>,
L<Catmandu::MediaHaven>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the terms
of either: the GNU General Public License as published by the Free Software Foundation;
or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

use Catmandu::Sane;

our $VERSION = '0.02';

use Moo;
use Catmandu::MediaHaven;
use namespace::clean;

with 'Catmandu::Importer';

has 'url'          => (is => 'ro' , required => 1);
has 'username'     => (is => 'ro' , required => 1);
has 'password'     => (is => 'ro' , required => 1);

sub generator {
    my ($self) = @_;

    my $mh = Catmandu::MediaHaven->new(
        url      => $self->url,
        username     => $self->username,
        password     => $self->password,
    );

    my $res = $mh->search();

    sub {
        state $results = $res->{mediaDataList};
        state $total   = $res->{totalNrOfResults};
        state $index   = 0;

        $index++;

        if (@$results > 1) {
            return shift @$results;
        }
        elsif ($index < $total) {
            my $res = $mh->search(undef, start => $index+1);
            $results = $res->{mediaDataList};
            $index++;
            return shift @$results;
        }
        return undef;
    };
}

1;
