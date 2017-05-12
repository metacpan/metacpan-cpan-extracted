package Catmandu::Importer::CPAN;

use Catmandu::Sane;
use MetaCPAN::API::Tiny;
use Moo;

with 'Catmandu::Importer';

our $VERSION = '0.03';

has prefix => (is => 'ro');
has author => (is => 'ro');

# http://api.metacpan.org/v0/release/_mapping
our $RELEASE_FIELDS = [qw(
    abstract archive author authorized date dependency distribution
    download_url first id license maturity name provides resources stat status
    tests version version_numified
)];

has fields => (
    is => 'ro', 
    default => sub { [ qw(id date distribution version abstract) ] },
    coerce => sub {
        ref $_[0] ? $_[0] 
                  : ($_[0] eq 'all' ? $RELEASE_FIELDS 
                                    : [ split /,/, $_[0] ]);
    }
);

has mcpan => (is => 'ro', builder => sub { MetaCPAN::API::Tiny->new });
has filter => (is => 'ro', lazy => 1, builder => 1);

sub _build_filter {
    my $self = $_[0];

    my @filter = { term => { status => 'latest' } };

    if ($self->prefix) {
        push @filter, { prefix => { archive => $self->prefix } };
    }

    if ($self->author) {
        push @filter, { term => { author => $self->author } };
    }
       
    if (@filter > 1) {
        return { and => \@filter };
    } else {
        return $filter[0];
    }
}

sub generator {
    my $self = $_[0];

    my $result = $self->mcpan->post( 
        release => {
            fields => $self->fields,
            filter => $self->filter,
            size   => 1024,
        }
    );
 
    my @hits = @{$result->{hits}->{hits}};

    return sub {
        my $hit = shift @hits;
        return undef unless $hit;
        return {
            map { $_ => $hit->{fields}->{$_} } @{$self->fields}
        }
    };
}

1;
__END__

=head1 NAME 

Catmandu::Importer::CPAN - get information about CPAN releases

=head1 SYNOPSIS

  use Catmandu::Importer::CPAN;
  my $importer = Catmandu::Importer::CPAN->new( prefix => 'Catmandu' );
 
  $importer->each(sub {
     my $module = shift;
     print $module->{distribution} , "\n";
     print $module->{version} , "\n";
     print $module->{date} , "\n";
  });
 
Or with the L<catmandu> command line client:

  $ catmandu convert CPAN --author NICS --fields distribution,date to CSV

=head1 DESCRIPTION

This L<Catmandu::Importer> retrieves information about CPAN releases via
MetaCPAN API.

=head1 CONFIGURATION

=over

=item prefix

Prefix that releases must start with, e.g. C<Catmandu>.

=item author

Selected author

=item fields

Array reference or comma separated list of fields to get.  The special value
C<all> will return all fields.  Set to C<id,date,distribution,version,abstract>
by default.

=back

=head1 CONTRIBUTORS

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Jakob Voss C<< <jakob.voss at gbv.de> >>

=cut
