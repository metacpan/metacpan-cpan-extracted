package Data::Kramerius;

use strict;
use warnings;

use Data::Kramerius::Object;
use Text::DSV;
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	$self->{'kramerius'} = [];

	# Load data.
	$self->_load_data;

	# Object.
	return $self;
}

sub get {
	my ($self, $id) = @_;

	foreach my $obj (@{$self->{'kramerius'}}) {
		if ($obj->id eq $id) {
			return $obj;
		}
	}

	return;
}

# List of Kramerius systems.
sub list {
	my $self = shift;

	return @{$self->{'kramerius'}};
}

sub _load_data {
	my $self = shift;

	# Read data.
	my $kramerius_data;
	my $dsv = Text::DSV->new;
	while (my $data = <DATA>) {
		chomp $data;
		my ($version, $id, $name, $url) = $dsv->parse_line($data);
		push @{$self->{'kramerius'}}, Data::Kramerius::Object->new(
			'id' => $id,
			'name' => decode_utf8($name),
			'url' => $url,
			'version' => $version,
		);
	}

	return;
}

1;

=pod

=encoding utf8

=head1 NAME

Data::Kramerius - Information about all Kramerius systems.

=head1 SYNOPSIS

 use Data::Kramerius;

 my $obj = Data::Kramerius->new;
 my $kramerius_obj = $obj->get($kramerius_id);
 my @kramerius_objs = $obj->list;

=head1 DESCRIPTION

Kramerius is an open source software solution for accessing digital documents.
Homepage of project is in L<https://system-kramerius.cz/>.

=head1 METHODS

=head2 C<new>

 my $obj = Data::Kramerius->new;

Constructor.

Returns instance of object.

=head2 C<get>

 my $kramerius_obj = $obj->get($kramerius_id);

Get Kramerius object defined by id.

Returns Data::Kramerius::Object instance.

=head2 C<list>

 my @kramerius_objs = $obj->list;

List all kramerius systems.

Returns list of Data::Kramerius::Object instances.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Kramerius;
 use Unicode::UTF8 qw(encode_utf8);

 my $obj = Data::Kramerius->new;
 my $kramerius_mzk = $obj->get('mzk');

 # Print out.
 print 'Id: '.$kramerius_mzk->id."\n";
 print 'Name: '.encode_utf8($kramerius_mzk->name)."\n";
 print 'URL: '.$kramerius_mzk->url."\n";
 print 'Version: '.$kramerius_mzk->version."\n";

 # Output:
 # Id: mzk
 # Name: Moravská zemská knihovna
 # URL: http://kramerius.mzk.cz/
 # Version: 4

=head1 DEPENDENCIES

L<Data::Kramerius::Object>,
L<Text::DSV>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Kramerius>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut

__DATA__
version:code:name:url
3:ABA001:Národní knihovna:https\://kramerius.nkp.cz/
3:ABA013:Národní technická knihovna:http\://kramerius.stk.cz/
3:ABC135:Národní filmový archiv v Praze:http\://kramerius.nfa.cz/
3:ABE304:Institut umění – Divadelní ústav:http\://kramerius.divadlo.cz/
3:ABG001:Digitální knihovna Městské knihovny v Praze:http\://kramerius.mlp.cz/
3:BOD006:Mendelova univerzita v Brně:http\://kramerius.mendelu.cz
3:CBA001:Jihočeská vědecká knihovna v Českých Budějovicích:http\://kramerius.cbvk.cz
3:OLA001:Digitalní knihovna novin:http\://noviny.vkol.cz/
3:OSA001:Moravskoslezská vědecká knihovna v Ostravě:http\://camea.svkos.cz
3:PNA001:Studijní a vědecká knihovna Plzeňského kraje:http\://kramerius.svkpl.cz/
3:ULG001:Severočeská vědecká knihovna v Ústí nad Labem:http\://kramerius.svkul.cz
3:ZLG001b:Krajská knihovna Františka Bartoše ve Zlíně:http\://dlib.kfbz.cz
4:mzk:Moravská zemská knihovna:http\://kramerius.mzk.cz/
4:ndk:Národní digitální knihovna:http\://ndk.cz/
4:vkol:Vědecká knihovna v Olomouci:http\://kramerius.kr-olomoucky.cz/
4:svkhk:Studijní a vědecká knihovna v Hradci Králové:http\://kramerius4.svkhk.cz/
4:svkul:Severočeská vědecká knihovna v Ústí nad Labem:http\://kramerius.svkul.cz/
4:knav:Knihovna Akademie věd ČR:https\://kramerius.lib.cas.cz/
4:mkct:Městská knihovna Česká Třebová:http\://k5.digiknihovna.cz/
4:dsmo:Digitální studovna Ministerstva obrany ČR:https\://kramerius.army.cz/
4:mlp:Městská knihovna v Praze:http\://kramerius4.mlp.cz/
4:kkkv:Krajská knihovna Karlovy Vary:http\://k4.kr-karlovarsky.cz/
4:kvkli:Krajská vědecká knihovna Liberec:http\://kramerius.kvkli.cz/
4:svkpk:Studijní a vědecká knihovna Plzeňského kraje:http\://k4.svkpl.cz/
4:nfa:Národní filmový archiv:http\://library.nfa.cz/
4:zmp:Židovské muzeum v Praze:http\://kramerius4.jewishmuseum.cz/
4:nm:Národní muzeum:http\://kramerius.nm.cz/
4:zcm:Knihovna Západočeského muzea v Plzni:http\://kramerius.zcm.cz/
4:cbvk:Jihočeská vědecká knihovna v Českých Budějovicích:http\://kramerius.cbvk.cz/
4:kfbz:Krajská knihovna Františka Bartoše ve Zlíně:http\://dlib.kfbz.cz/
4:nkp:Národní knihovna:http\://kramerius5.nkp.cz/
4:cuni_fsv:Univerzita Karlova v Praze - Fakulta sociálních věd:http\://kramerius.fsv.cuni.cz/
4:ntk:Národní technická knihovna:http\://kramerius.techlib.cz/
4:svkkl:Středočeská vědecká knihovna v Kladně:http\://kramerius.svkkl.cz/
4:lmda:Lesnický a myslivecký digitální archiv:http\://lmda.silvarium.cz/
4:uzei:Knihovna Antonína Švehly:http\://kramerius.uzei.cz/
4:ukb:Univerzitná knižnica v Bratislave:http\://pc139.ulib.sk/
4:slu:Slezská univerzita v Opavě:http\://kramerius.slu.cz/
4:svkos:Moravskoslezská vědecká knihovna v Ostravě:http\://camea.svkos.cz/
4:vugtk:Výzkumný ústav geodetický, topografický a kartografický:http\://knihovna-test.vugtk.cz/
4:vse:Vysoká škola ekonomická v Praze:http\://kramerius.vse.cz/
4:nlk:Národní lékařská knihovna v Praze:http\://kramerius.medvik.cz/
4:mendelu:Mendelova univerzita v Brně:http\://kramerius4.mendelu.cz/
4:kkvhb:Krajská knihovna Vysočiny v Havlíčkově Brodě:http\://kramerius.kkvysociny.cz/
4:cdk:Česká Digitální knihovna:http\://cdk.lib.cas.cz/
4:nmzv:Národní muzeum - Zvuk:http\://kramerius.nm.cz/
4:npmk:Národní pedagogické muzeum J. A. Komenského:https\://kramerius.npmk.cz/
4:nulk:Národní ústav lidové kultury:https\://kramerius.nulk.cz/
4:hmt:Husitské muzeum v Táboře:http\://kramerius.husitskemuzeum.cz/
