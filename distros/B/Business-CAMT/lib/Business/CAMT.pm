# Copyrights 2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Business::CAMT.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

# https://www.betaalvereniging.nl/wp-content/uploads/IG-Bank-to-Customer-Statement-CAMT-053-v1-1.pdf

package Business::CAMT;{
our $VERSION = '0.11';
}


use strict;
use warnings;
use utf8;

use Log::Report 'business-camt';

use Path::Class         ();
use XML::LibXML         ();
use XML::Compile::Cache ();
use Scalar::Util        qw(blessed);
use List::Util          qw(first);
use XML::Compile::Util  qw(pack_type);

use Business::CAMT::Message ();

my $urnbase = 'urn:iso:std:iso:20022:tech:xsd';
my $moddir  = Path::Class::File->new(__FILE__)->dir;
my $xsddir  = $moddir->subdir('CAMT', 'xsd');
my $tagdir  = $moddir->subdir('CAMT', 'tags');
sub _rootElement($) { pack_type $_[1], 'Document' }  # $ns parameter

# The XSD filename is like camt.052.001.12.xsd.  camt.052.001.* is expected
# to be incompatible tiwh camt.052.002.*, but *.12.xsd can parse *.11.xsd
my (%xsd_files, $tagtable);


sub new {
    my $class = shift;
    (bless {}, $class)->init( {@_} );
}

sub init($) {
	my ($self, $args) = @_;

	foreach my $f (grep !$_->is_dir && $_->basename =~ /\.xsd$/, $xsddir->children)
	{	$f->basename =~ /^camt\.([0-9]{3}\.[0-9]{3})\.([0-9]+)\.xsd$/ or panic $f;
		$xsd_files{$1}{$2} = $f->stringify;
	}

	$self->{BC_rule} = delete $args->{match_schema}  || 'NEWER';
	$self->{BC_big}  = delete $args->{big_numbers}   || 0;
	$self->{BC_long} = delete $args->{long_tagnames} || 0;
	$self->{RC_schemas} = XML::Compile::Cache->new;

    $self;
}

#-------------------------

sub schemas() { $_[0]->{RC_schemas} }

#-------------------------

sub read($%)
{	my ($self, $src, %args) = @_;

	my $dom = blessed $src ? $src : XML::LibXML->load_xml(location => $src);
	my $xml = $dom->isa('XML::LibXML::Document') ? $dom->documentElement : $dom;
	my $ns  = $xml->namespaceURI;
	my ($set, $version) = $ns =~ m!^\Q$urnbase\E:camt\.([0-9]{3}\.[0-9]{3})\.([0-9]+)$!
		or error __"Not a CAMT file.";

	my $versions = $xsd_files{$set}
		or error __"Not a supported CAMT message type.";

	my $xsd_version = $self->matchSchema($set, $version, rule => $args{match_schema})
		or error __"No compatible schema version available.";

	if($xsd_version != $version)
	{	# implement backwards compatibility
		trace "Using $set schema version $xsd_version to read a version $version message.";
		$ns = "$urnbase:camt.$set.$xsd_version";
		$xml->setNamespaceDeclURI('', $ns);
	}

	my $reader = $self->schemaReader($set, $xsd_version, $ns);

	Business::CAMT::Message->fromData(
		set     => $set,
		version => $xsd_version,
		data    => $reader->($xml),
		camt    => $self,
	);
}


sub create($$$)
{	my ($self, $set, $version, $data) = @_;
	Business::CAMT::Message->create(
		set     => $set,
		version => $version,
		data    => $data,
		camt    => $self,
	);
}


sub write($$%)
{	my ($self, $fn, $msg, %args) = @_;

	my $set      = $msg->set;
	my $versions = $xsd_files{$set}
		or error __x"Message set '{set}' is unsupported.", set => $set;

	my @versions = sort { $a <=> $b } keys %$versions;
	my $version  = $msg->version;
	grep $version eq $_, @versions
		or error __x"Schema version {version} is not available, pick from {versions}.",
			version => $version, versions => \@versions;

	my $ns     = "$urnbase:camt.$set.$version";
	my $writer = $self->schemaWriter($set, $version, $ns);

	my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $xml    = $writer->($doc, $msg);
	$doc->setDocumentElement($xml);
	$doc->toFile($fn, 1);
	$xml;
}

#-------------------------

sub _loadXsd($$)
{	my ($self, $set, $version) = @_;
	my $file = $xsd_files{$set}{$version};
	$self->{BC_loaded}{$file}++ or $self->schemas->importDefinitions($file);
}

my %msg_readers;
sub schemaReader($$$)
{	my ($self, $set, $version, $ns) = @_;
	my $r = $self->{BC_r} ||= {};
	return $r->{$ns} if $r->{$ns};

	$self->_loadXsd($set, $version);

	$r->{$ns} = $self->schemas->compile(
		READER        => $self->_rootElement($ns),
		sloppy_floats => !$self->{BC_big},
		key_rewrite   => $self->{BC_long} ? $self->tag2fullnameTable : undef,
	);
}


sub schemaWriter($$$)
{	my ($self, $set, $version, $ns) = @_;
	my $w = $self->{BC_w} ||= {};
	return $w->{$ns} if $w->{$ns};

	$self->_loadXsd($set, $version);
	$w->{$ns} = $self->schemas->compile(
		WRITER        => $self->_rootElement($ns),
		sloppy_floats => !$self->{BC_big},
		key_rewrite   => $self->{BC_long} ? $self->tag2fullnameTable : undef,
		ignore_unused_tags => qr/^_attrs$/,
		prefixes      => { $ns => '' },
	);
}



# called with ($set, $version, \@available_versions)
sub _exact { first { $_[1] eq $_ } @{$_[2]} }
my %rules = (
	EXACT  => \&_exact,
	NEWER  => sub { (grep $_ >= $_[1], @{$_[2]})[0] },
	NEWEST => sub { _exact(@_) || ($_[1] <= $_[2][-1] ? $_[2][-1] : undef) },
	ANY    => sub { _exact(@_) || $_[2][-1] },
);

sub matchSchema($$%)
{	my ($self, $set, $version, %args) = @_;
	my $versions = $xsd_files{$set} or panic "Unknown set $set";

	my $ruler = $args{rule} ||= $self->{BC_rule};
	my $rule  = ref $ruler eq 'CODE' ? $ruler : $rules{$ruler}
		or error __x"Unknown schema match rule '{rule}'.", rule => $ruler;
	
	$rule->($set, $version, [ sort { $a <=> $b } keys %$versions ]);
}


sub knownVersions(;$)
{	my ($self, $set) = @_;
	my @s;
	foreach my $s ($set ? $set : sort keys %xsd_files)
	{	push @s, map "camt.$s.$_", sort {$a <=> $b} keys %{$xsd_files{$s}};
	}
	@s;
}


sub fullname2tagTable()
{	my $self = shift;
	$self->{BC_toAbbr} ||= +{ reverse %{$self->tag2fullnameTable} };
}


sub tag2fullnameTable()
{	my $self = shift;
	$self->{BC_toLong} ||= +{
		map split(/,/, $_, 2), grep !/,$/, $tagdir->file('index.csv')->slurp(chomp => 1)
	};
}

#---------------

1;
