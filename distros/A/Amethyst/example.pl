# sub POE::Kernel::TRACE_DEFAULT  () { 1 }
sub POE::Kernel::ASSERT_DEFAULT	() { 1 }
# sub POE::Kernel::TRACE_EVENTS  () { 1 }
# sub POE::Kernel::TRACE_QUEUE  () { 1 }
# sub POE::Kernel::TRACE_GARBAGE  () { 1 }
# sub POE::Kernel::TRACE_REFCOUNT  () { 1 }

# use lib qw/./;
use Data::Dumper;
use POE;
use Amethyst;

new Amethyst;

my %anarres = (
		# Amethyst variables
		Name		=> 'anarres',
		Brains		=> [ qw(infobot eliza) ],	# barwench markov
		Alias		=> 'anarres',	# For CNN module
		# Object specific variables
		Host		=> 'mudlib.anarres.org',
		Port		=> 5000,
		Login		=> q[(some valid login)],
		Password	=> q[(the password)],
		# Debug		=> 3,
		Channel		=> 'spam',	# Force output to one channel
			);
unless ($ENV{HOSTNAME} =~ /^pink/) {
	$anarres{Host} = 'localhost';
}
my %cnnchat = (
		# Amethyst variables
		Name		=> 'cnnchat',
		Brains		=> [ qw(cnn) ],
		# Object specific variables
		# Server		=> 'london.rhizomatic.net',
		# Channels	=> [ qw(amethyst) ],
		Server		=> 'chat.cnn.com',
		Nick		=> 'Amethyst',
		Channels	=> [ qw(CNN_Newsfeed) ],
		ClientAlias	=> 'cnn irc',
			);
my %rhizomatic = (
		# Amethyst variables
		Name		=> 'rhizomatic',
		Alias		=> 'rhizomatic',	# For CNN module
		Brains		=> [ qw(infobot) ],	# barwench
		# Object specific variables
		Server		=> 'london.rhizomatic.net',
		Nick		=> 'Amethyst',		# Replace this
		# Channels	=> [ qw(bblug) ],	# Put your channels here
			);

my %infobot = (
		# Amethyst variables
		Name		=> 'infobot',
		# Object specific variables
		# You can put any valid selection of
		# Amethyst::Brain::Infobot::Module names in this list. I have
		# taken some out as my personal preference.
		Modules		=> [ qw(
				Statement
				Google Nslookup
				Karma
				Fortune Excuse Insult
				Zippy Zappa
				Help Time Math
				BabyTime
					) ],
			# Readonly databases - build this using import.sh
		FactoidRead		=> [ qw(factpack) ],
			# The readwrite database
		FactoidWrite	=> q(statement),
			);
my %barwench = (
		Name		=> 'barwench',
			);
my %cnn = (
		Name		=> 'cnn',
		# Object specific
		Output		=> {
						# Connection name => Channel name
						# rhizomatic	=> 'amethyst',
						# anarres		=> 'cnn',
						},
			);
my %eliza = (
		Name		=> 'eliza',
			);
my %markov = (
		Name		=> 'markov',
			);

$poe_kernel->post('amethyst', 'add_brain',
				'Amethyst::Brain::Infobot', \%infobot);
$poe_kernel->post('amethyst', 'add_brain',
				'Amethyst::Brain::BarWench', \%barwench)
								if 0;
$poe_kernel->post('amethyst', 'add_brain',
				'Amethyst::Brain::CNN', \%cnn)
								if 0;
$poe_kernel->post('amethyst', 'add_brain',
				'Amethyst::Brain::Eliza', \%eliza);
$poe_kernel->post('amethyst', 'add_brain',
				'Amethyst::Brain::Markov', \%markov)
								if 0;

$poe_kernel->post('amethyst', 'add_connection',
				'Amethyst::Connection::Anarres', \%anarres)
								if 1;
$poe_kernel->post('amethyst', 'add_connection',
				'Amethyst::Connection::IRC', \%rhizomatic)
								if 0;
$poe_kernel->post('amethyst', 'add_connection',
				'Amethyst::Connection::IRC', \%cnnchat)
								if 0;

$poe_kernel->post('amethyst', 'connect');

$poe_kernel->run();
