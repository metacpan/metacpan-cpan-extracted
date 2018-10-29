package Catmandu::Fix::xID;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::OCLC::xID;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has path    => (fix_arg => 1);
has type    => (fix_arg => 1);
has method  => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $path    = $fixer->split_path($self->path);
    my $key     = pop @$path;
    my $type    = $self->type;
    my $method  = $self->method;

    $fixer->emit_walk_path($fixer->var, $path, sub {
        my $var = shift;
        $fixer->emit_get_key($var, $key, sub {
            my $var = shift;
            "if (is_value(${var})) {"
                ."use Catmandu::OCLC::xID;"
                ."${var} = Catmandu::OCLC::xID::query(${var},'$type','$method');"
                ."}";
        });
    });
}

=head1 NAME

Catmandu::Fix::xID - query the OCLC xID service

=head1 SYNOPSIS

	marc_map('020a','my.isbn')
	marc_map('022a','my.issn')
	marc_map('001_','my.oclc')

 	# Query an ISBN number for metadata
	xID('my.isbn','xisbn','getMetadata')

	# Query an ISBN number for editions
	xID('my.isbn','xisbn','getEditions')

	# Transform an ISBN to 13 digits
	xID('my.isbn','xisbn','to13')

	# Transform an ISBN to 10 digits
	xID('my.isbn','xisbn','to10')

	# Re-calculates the checksum digit of the request ISBN number
	xID('my.isbn','xisbn','fixCheckSum')

	# Add '-' (hyphen) character to an ISBN number.
	xID('my.isbn','xisbn','hyphen')

	# Retrieve metadata about an ISSN
	xID('my.issn','xissn','getMetadata')

	# Retrieve a list of ISSNs in same group as the requested ISSN.
	xID('my.issn','xissn','getEditions')

	# Retrieve a list of ISSNs in same group as the requested ISSN,
	# as well as preceding/succeeding groups
	xID('my.issn','xissn','getHistory')

	# Retrieve a list of ISSNs and its production form information
	# in same group as the requested ISSN.
	xID('my.issn','xissn','getForms')

	# Get metadata about a Standard Number
	xID('my.oclc','xstandardNumber','getMetadata')

	# Retrieve all edition information
	xID('my.oclc','xstandardNumber','getEditions')

	# Retrieve different variant OCLC numbers
	xID('my.oclc','xstandardNumber','getVariants')

=head1 DESCRIPTION

**WARNING** : This OCLC service has been taken offline on 2018-08-23

Submit an identifer such as an ISBN, ISSN, or OCLC Number to the OCLC xID service, and
it returns a list of related identifiers and selected metadata.

Access of 1000 queries/day is available to anyone.

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::MARC>

=cut

1;
