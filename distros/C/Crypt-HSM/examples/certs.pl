#! perl

use 5.012;
use warnings;

use Crypt::HSM;
use Data::Dumper;

my $path = shift || '/usr/lib/pkcs11/p11-kit-trust.so'; # '/usr/lib/libnssckbi.so';

my $provider = Crypt::HSM->load($path);

for my $slot ($provider->slots) {
	say Dumper($slot->info);

	my $session = $slot->open_session;

	my @objects = $session->find_objects({
		class                  => 'certificate',
		'certificate-type'     => 'x-509',
		'certificate-category' => 'authority',
		trusted                => 1,
	});

	my @object_info = map { $_->get_attributes([qw/subject/]) } @objects;
	# I should ASN.1 decode this
	say Dumper(\@object_info);
}
