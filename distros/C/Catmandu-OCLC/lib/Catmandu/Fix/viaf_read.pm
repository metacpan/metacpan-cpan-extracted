package Catmandu::Fix::viaf_read;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::OCLC::xID;
use Catmandu::OCLC::VIAFAuthorityCluster;
use Moo;
use Catmandu::Fix::Has;

has path    => (fix_arg => 1);

sub fix {
    my ($self, $data) = @_;
    my $path     	 = $self->path;
    my $identifier   = Catmandu::Util::data_at($path,$data);

    if (is_string($identifier)) {
    	my $authority = Catmandu::OCLC::VIAFAuthorityCluster::read($identifier);

    	return undef unless defined $authority;

    	$data->{record} = $authority->{record};
    }

  	$data;
}

=head1 NAME

Catmandu::Fix::viaf_read - query the OCLC VIAF service

=head1 SYNOPSIS

	add_field('number','102333412');
	do
	  maybe();
	  viaf_read('number');
	  marc_map('700','author.$append')
	  remove_field(record)
	end

=head1 DESCRIPTION

Search for an authority record by a VIAF control number. Will insert the parsed VIAF MARC
record into the document (overwriting the 'record' key if available). Returns undef on failure.
Use the maybe() Bind to secure against service failures undef return values

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::MARC>, L<Catmandu::Fix::Bind::maybe>

=cut

1;