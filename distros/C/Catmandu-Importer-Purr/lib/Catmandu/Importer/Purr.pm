package Catmandu::Importer::Purr;

use Catmandu::Sane;
use MetaCPAN::API::Tiny;
use Moo;

with 'Catmandu::Importer';

our $VERSION = '0.02';

has prefix => (is => 'ro' , default => sub { "Catmandu" });
has mcpan  => (is => 'ro' , lazy => 1, builder => '_build_mcpan');

sub _build_mcpan {
    my $self = $_[0];
    MetaCPAN::API::Tiny->new;
}

sub generator {
	my $self = $_[0];
	my $prefix = $self->prefix;
	my $result = $self->mcpan->post(
        'release',
        {   
            query  => {
        	  bool => {
            	should => [{
                	term => {
                    	"release.status" => "latest"
                	}
            	}]
              }
        	},
            fields => [ qw(id date distribution version abstract) ],
            size   => 1024,
            filter => { prefix => { archive => $prefix } },
        },
 	);

	my @hits = @{$result->{hits}->{hits}};

	return sub {
		my $hit = shift @hits;
		return undef unless $hit;
		return {
			id           => $hit->{fields}->{id} ,
 		    date         => $hit->{fields}->{date} ,
 			distribution => $hit->{fields}->{distribution} ,
 			version      => $hit->{fields}->{version} ,
 			abstract     => $hit->{fields}->{abstract} ,
		}
	};
}

=head1 NAME 

Catmandu::Importer::Purr - Perl Utility for Recent Releases

=head1 SYNOPSIS

 use Catmandu::Importer::Purr;

 my $importer = Catmandu::Importer::Purr->new(prefix => 'Catmandu');
 
 $importer->each(sub {
	my $module = shift;
	print $module->{id} , "\n";
	print $module->{date} , "\n";
	print $module->{distribution} , "\n";
	print $module->{version} , "\n";
	print $module->{abstract} , "\n";
 });
 
 # or

 $ catmandu convert Purr

=head1 AUTHORS

 Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer>

=cut

1;