# Copyrights 2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Business::CAMT.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

# https://www.betaalvereniging.nl/wp-content/uploads/IG-Bank-to-Customer-Statement-CAMT-053-v1-1.pdf

package Business::CAMT;{
our $VERSION = '0.10';
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

use Business::CAMT::Message ();

my $urnbase = 'urn:iso:std:iso:20022:tech:xsd';
my $moddir  = Path::Class::File->new(__FILE__)->dir;
my $xsddir  = $moddir->subdir('CAMT', 'xsd');
my $tagdir  = $moddir->subdir('CAMT', 'tags');

# The XSD filename is like camt.052.001.12.xsd.  camt.052.001.* is expected
# to be incompatible tiwh camt.052.002.*, but *.12.xsd can parse *.11.xsd
my (%xsd_files, $tagtable);
our $schemas;  # public for template generator


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

	$schemas = XML::Compile::Cache->new;
    $self;
}

#-------------------------

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
	my $data   = $reader->($xml);

	$data ? Business::CAMT::Message->fromData($set, $data) : undef;
}


my %msg_readers;
sub schemaReader($$$)
{	my ($self, $set, $version, $ns) = @_;
	return $msg_readers{$ns} if $msg_readers{$ns};

	$schemas->importDefinitions($xsd_files{$set}{$version});

	$msg_readers{$ns} = $schemas->compile(
		READER        => "{$ns}Document",
		sloppy_floats => !$self->{BC_big},
		key_rewrite   => $self->{BC_long} ? $self->tag2fullnameTable : undef,
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
