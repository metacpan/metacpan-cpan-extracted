package Catmandu::Importer::Z3950::Parser::UNIMARC;

use Catmandu::Sane;
use MARC::Parser::RAW;
use Moo;

our $VERSION = '0.06';

has 'id' => (is => 'ro' , default => sub { '001'} );

sub parse {
    my ($self,$str) = @_;
    my $sysid = undef;

    return undef unless defined $str;

    my $record = MARC::Parser::RAW->new(\$str)->next();

    foreach my $field (@$record) {
	if ($field->[0] eq '001') {
		$sysid = $field->[4];
	}
    }

    return { _id => $sysid , record => $record };
}

1;
