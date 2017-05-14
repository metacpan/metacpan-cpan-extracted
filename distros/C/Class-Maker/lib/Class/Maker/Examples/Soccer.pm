
use	5.006; use strict; use warnings;

use modules qw(

	Object::Serializable::XML
	Object::Serializable::HTML
	Object::Bouncer
	Object::Auth
	Object::Trustee

);

use Alias qw(attr);

use IO::Extended qw(:all);

Class::Maker::class 'Serializable',
{
	isa => [qw( Object::Serializable::XML Object::Serializable::HTML )],
};

Class::Maker::class 'Spiel',
{
	isa => [qw( Serializable )],

	public =>
	{
		ref =>
		{
			schiedsrichter => 'Spiel::Schiedsrichter',

			spielort => 'Spiel::Ort',

			termin => 'Spiel::Termin',

			dauer => 'Spiel::Dauer',

			ergebnis => 'Spiel::Ergebnis',
		},

		array =>
		{
			mannschaften => 'Spiel::Mannschaft',

			tore => 'Spiel::Tor',

			uebertragungen => 'Spiel::Uebertragung',
		},

		bool => [qw( elfmeter )],
	},
};

sub Spiel::_preinit
{
	my $this = attr shift;

		$this->dauer( new Spiel::Dauer( minuten => "90 Minuten" ) );
}

sub Spiel::printout : method
{
	my $this = attr shift;

		printfln '[%s gegen %s] mit Schiri %s (Elfmeter: %s).',

			$this->mannschaften->[0]->name,

			$this->mannschaften->[1]->name,

			$this->schiedsrichter->name,

			$this->elfmeter;

		#printfln 'Ein Spiel dauert %s.', $this->dauer->minuten;
}

Class::Maker::class 'Spiel::Mannschaft',
{
	isa => [qw( Gruppe )],

	public =>
	{
		string => [qw( wappen )],

		ref => { trainer => 'Spiel::Mannschaft::Trainer' },
	},
};

Class::Maker::class 'Spiel::Mannschaft::Spieler',
{
	public =>
	{
		bool => [qw( torwart )],

		int => [qw( nummer )],

		ref => { gruppe => 'Gruppe' },

		array => { karten => 'Spiel::Schiedsrichter::Karte' },
	},
};

Class::Maker::class 'Spiel::Mannschaft::Trainer',
{
	isa => [qw(Mensch)],
};

Class::Maker::class 'Spiel::Schiedsrichter',
{
	isa => [qw(Mensch)],
};

Class::Maker::class 'Spiel::Schiedsrichter::Karte',
{
	public =>
	{
		string => [qw( uhrzeit grund typ )],
	},
};

Class::Maker::class 'Spiel::Tor',
{
	public =>
	{
		ref => { spieler => 'Spiel::Mannschaft::Spieler' },

		string => [qw( uhrzeit )],
	},

};

Class::Maker::class 'Spiel::Ort',
{
	public =>
	{
		 string => [qw( name land stadt )],

		 int => [qw( zuschauerzahl )],
	},
};

Class::Maker::class 'Spiel::Termin',
{
	public =>
	{
		 bool =>[qw( verschoben )],

		 string => [qw(	uhrzeit )],

		 ref => { ort => 'Spiel::Ort' },
	},
};

Class::Maker::class 'Spiel::Dauer',
{
	public =>
	{
		string => [qw( minuten )],

		ref => { verlaengerung => 'Spiel::Verlaengerung' },
	},
};

Class::Maker::class 'Spiel::Verlaengerung',
{
	public =>
	{
		bool => [qw( goldengoal )],
	},
};

Class::Maker::class 'Spiel::Uebertragung',
{
	public =>
	{
		string => [qw( typ )],

		ref => { termin => 'Spiel::Termin' },
	},
};

Class::Maker::class 'Spiel::Ergebnis',
{
	public =>
	{
		array => { tore => 'Spiel::Tor' },
	},
};

Class::Maker::class 'Anschrift',
{
	public =>
	{
		string => [qw( name vorname ort plz strasse )],
	},
};

Class::Maker::class 'Mensch',
{
	public =>
	{
		string => [qw( name vorname titel geburtsort geburtsdatum geschlecht nationalitaet email )],

		ref => { anschrift => 'Anschrift' },

		array => { freunde => 'Mensch' },
	},
};

class 'Gruppe',
{
	public =>
	{
		string => [qw( name descr )],
	},
};

Class::Maker::class 'Mitglied',
{
	isa => [qw( Mensch )],

	public =>
	{
		ref => { leiter => 'Spielleiter' },

		array => { tips => 'Spiel::Ergebnis' },
	},
};

Class::Maker::class 'Administrator',
{
	public =>
	{
	},
};

	# COMMENT: Spielleiter isa => [qw( Object::Bouncer )],

Class::Maker::class 'Spielleiter',
{
	isa => [qw( Mitglied )],
};

sub Spielleiter::akzeptiert : method
{
	my $this = attr shift;

	my $anwaerter = shift;

			# Wir inkarnieren ein Mitglied aus dem simplen Menschen
			#
			#	# Wir muessen das Mitglied per "new" erzeugen, damit der constructor aufgerufen werden kann

		my $mitglied = bless { %$anwaerter, %{ new Mitglied } }, 'Mitglied';

			# TODO: Ein Login-Vergeber ( Ticket-verkaeufer der das Login+Pw vergibt und eine Tabelle
			# führt um später Anfragen beantworten zu können wer das Login+Pw bekommen hatte.
			#
			# # ACHTUNG: Dieser Ticketverkäufer ist nahezu identisch mit dem Schatzmeister, denn anstatt
			# # Zahlungen verwaltet er einfach nur akzeptierte Formular::Antrag::Anmeldung Objekte.

		$mitglied->userid( 'bla' );

		$mitglied->passwd( 'blubb' );

		$mitglied->leiter( $this );

return $mitglied;
}

Class::Maker::class 'Schatzmeister',
{
	isa => [qw( Mensch Object::Trustee )],

	public =>
	{
		array => [qw( zahlungen => 'Schatzmeister::Zahlung' )],
	},
};

sub Schatzmeister::annehmen : method
{
	my $this = attr shift;

	my ( $zahlender, $betrag, $grund ) = @_;

		my $zahlung = new Schatzmeister::Zahlung( betrag => $betrag, grund => $grund, zahlender => $zahlender );

		push @{ $this->zahlungen }, $zahlung;

return $zahlung;
}

sub Schatzmeister::hatbezahlt : method
{
	my $this = attr shift;

	my $zahlender = shift;

		foreach my $zahlung ( @{ $this->zahlungen } )
		{
			return $zahlung if $zahlung->zahlender == $zahlender;
		}
}

Class::Maker::class 'Schatzmeister::Zahlung',
{
	public =>
	{
		real => [qw( betrag )],

		string => [qw( grund )],

		ref => { zahlender => 'Mensch' },
	},
};

Class::Maker::class 'Formular::Antrag',
{
	public =>
	{
		string =>  [qw( zeit )],

		ref => { antragsteller => 'Mensch', empfaenger => 'Mensch' },

		hash => [qw(kapitel)],
	},
};

Class::Maker::class 'Formular::Antrag::Anmeldung',
{
	isa => [qw( Formular::Antrag )],
};

sub Formular::Antrag::Anmeldung::_preinit : method
{
	my $this = attr shift;

		$this->empfaenger( Spielleiter->new( name => 'Firat', email => 'finalan@gmx.de', userid => 'test', passwd => 'testpw' ) );

		$this->kapitel(

			Antragsteller => Mensch->new(),

		);
}

	# Nimmt die ausgefüllten Formulare entgegen und
	# kümmert sich um: Fehlerkontrolle, Weiterleitung, etc.

Class::Maker::class 'Formular::Automat',
{
};

	# Zum Thema Waechter
	#
	# # - Waechter können lasch streng oder noch strenger sein (lasch und lascher gibt es nicht).
	# # - Waechter können verschiedene Kriterien untersuchen (Haarfarbe, Kleidung, Authentifizierung, etc.).
	# #   - Vererbung: Ein Waechter der von mehreren Waechtern entspringt wird am strengsten sein und die
	# #     und die meisten Kriterien untersuchen.

Class::Maker::class 'Sicherheit::Waechter',
{
	isa => [qw(Object::Bouncer)],
};

	# Waechter überprüft die Anmeldeinformationen

Class::Maker::class 'Sicherheit::Waechter::Anmeldung',
{
	isa => [qw(Sicherheit::Waechter)],
};

sub Sicherheit::Waechter::Anmeldung::_preinit
{
	my $this = attr shift;

			# Testtypen 'type' werden im Modul 'Verify' definiert.

		$this->addtest(

			new Object::Bouncer::Test( field => 'name', type => 'name' ),

			new Object::Bouncer::Test( field => 'vorname', type => 'name' ),

			new Object::Bouncer::Test( field => 'email', type => 'email' ),
		);
}

Class::Maker::class 'Sicherheit::Waechter::Raeume',
{
	isa => [qw(Object::Bouncer)],

	public =>
	{
		ref => { eintreten => 'Gruppe' },
	},
};

sub Sicherheit::Waechter::Raeume::_preinit
{
	my $this = attr shift;

			# Testtypen 'type' werden im Modul 'Verify' definiert.

		push @{ $this->tests },

			new Object::Bouncer::Test( field => 'name', type => 'name' ),

			new Object::Bouncer::Test( field => 'vorname', type => 'name' ),

			new Object::Bouncer::Test( field => 'email', type => 'email' );
}

	# TODO: Ein Login-Vergeber ( Ticket-verkaeufer der das Login+Pw vergibt und eine Tabelle
	# führt um später Anfragen beantworten zu können wer das Login+Pw bekommen hatte.
	#
	# PS: Zum ersetzen von Object::Auth

Class::Maker::class 'Sicherheit::Raum',
{
	isa => [qw(Object::Auth)],

	public =>
	{
		#int => [qw( groesse )],

		array => { besucher => 'Mensch', waechter => 'Sicherheit::Waechter::Raeume' },
	},
};

Class::Maker::class 'Sicherheit::Raum::Bewacht',
{
	isa => [qw( Sicherheit::Raum )],

	public =>
	{
		array => { waechter => 'Sicherheit::Waechter::Raeume' },
	},
};

Class::Maker::class 'Raum::Tippen',
{
	isa => [qw(Sicherheit::Raum)],
}

1;

__END__

	my @vereine = qw( Hertha München Bayern Rostock Bremen Dortmund Stuttgart );

	my @schiris = qw( Murat Firat Mehmet Elias Sülo Hans Franz Horst );

	for (1..10)
	{
		my $spiel = new Spiel(

			elfmeter => "ja",

			schiedsrichter => new Spiel::Schiedsrichter( name => $schiris[ rand(@schiris-1) ] ),

			mannschaften =>
			[
				new Spiel::Mannschaft( name => $vereine[ rand(@vereine-1) ] ),

				new Spiel::Mannschaft( name => $vereine[ rand(@vereine-1) ] ),
			],

			);

		$spiel->printout();

		#print $spiel->to_html( type => 'FILE', source => 'spiel.tmpl' );
	}

	my $formular = new Formular::Antrag::Anmeldung();

		# wir simulieren ein ausgefülltes formular

	$formular->antragsteller( new Mensch( name => 'Horst', email => 'horsttappert@web.de' ) );

		# Wir brauchen einen Waechter (Object::Bouncer) der:
		#	- die Formulare auf ihre Rightigkeit überprüft.
		#
		# )=> 'Sicherheit::Waechter::Anmeldung'

		# Beim Login:
		#	- den Schatzmeister fragt ob dieser User eintreten darf, wenn nicht
		#   ihn darauf hinweist zu zahlen.
		#
		# )=> 'Sicherheit::Waechter::Anmeldung'

		# Wir testen die Registrierung
		#
		# 	# 1. Der Mensch begleicht beim Schatzmeister seinen Eintritt
		#	# 	a) Falls der Schatzmeister bestätigt dass der Mensch bezahlt hat.
		#	#		- Akzeptiert der Spielleiter den Menschen zum Mitglied
		#	#		- Schicken wir dem glücklichen Mitglied eine email
		#	#	b) Fall noch nicht bezahlt
		#	#		- Weisen wir Ihn darauf hin und lehnen ein einloggen des Menschen noch ab

	my $schatzmeister = new Schatzmeister( name => 'Dagobert' );

		# dummy Zahlung

	$schatzmeister->annehmen( $formular->antragsteller, 100, 'Eintritt' );

	if( $schatzmeister->hatbezahlt( $formular->antragsteller ) )
	{
			# Voila ...Antrag akzeptiert ! der "antragsteller" wird zum mitgleid

		my $mitglied = $spielleiter->akzeptiert( $formular->antragsteller );

		printfln "\nHallo Herr %s, ihr Mitgliedname lautet %s und Passwort lautet %s. Herzliche Grüsse %s",

			$mitglied->name, $mitglied->userid, $mitglied->passwd, $spielleiter->name;

				# Und nun loggt sich das Mitglied ein

			if( $mitglied->login( 'blubb' ) )
			{
				printfln "Login successfull for '%s'", $mitglied->userid;

				$mitglied->debugDump();

				$mitglied->logout();
			}

			print "after the login...";

			$mitglied->debugDump();
	}
	else
	{
		# Mensch wurde abgelehnt

		printfln "Hallo Herr %s, leider können wir sie noch nicht in unser Spiel aufnehmen. Sie müssen erst ihre Gebühr bezahlen. Herzliche Grüsse %s", $mensch->name, $spielleiter->name;
	}
