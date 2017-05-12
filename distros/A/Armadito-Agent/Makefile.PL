use strict;
use warnings;
use inc::Module::Install;
use English qw(-no_match_vars);

name 'Armadito-Agent';
include 'Module::AutoInstall';
abstract 'Armadito Agent for Linux and Windows';
license 'gpl';
repository 'https://github.com/armadito/armadito-agent';
version_from 'lib/Armadito/Agent.pm';
perl_version '5.008';
authors 'Teclib';

requires 'UNIVERSAL::require'    => '0';
requires 'HTTP::Request::Common' => '0';
requires 'HTTP::Request'         => '0';
requires 'URI::Escape'           => '0';
requires 'URI'                   => '0';
requires 'JSON'                  => '0';
requires 'Encode'                => '0';
requires 'Getopt::Long'          => '0';
requires 'Pod::Usage'            => '0';
requires 'XML::LibXML'           => '0';
requires 'Readonly'              => '0';
requires 'Try::Tiny'             => '0';
requires 'Perl::Critic'          => '0';
requires 'Parse::Syslog'         => '0';
requires 'DBD::SQLite'           => '0';
requires 'Date::Calc'            => '0';
requires 'Time::Local'           => '0';
requires 'File::Stat'            => '0';
requires 'Time::Piece'           => '0';
requires 'IPC::System::Simple'   => '0';
requires 'File::Which'           => '0';
requires 'Memoize'               => '0';
requires 'LWP::UserAgent'        => '0';

if ( $OSNAME eq "MSWin32" ) {
	requires 'Win32::OLE' => '0';
}

test_requires 'XML::TreePP'        => '0';
test_requires 'Test::Compile'      => '0';
test_requires 'Test::More'         => '0';
test_requires 'Test::Perl::Critic' => '0';

install_script 'bin/armadito-agent';

resources
	homepage   => "http://www.teclib-edition.com/en/teclib-products/armadito-antivirus/",
	bugtracker => "https://github.com/armadito/armadito-agent/issues",
	repository => "https://github.com/armadito/armadito-agent",
	IRC        => "http://webchat.freenode.net/#armadito";

makemaker_args(
	test => {
		TESTS => join ' ',
		map {glob}
			qw(
			t/*.t
			t/*/*.t
			t/*/*/*.t
			t/*/*/*/*.t
			t/*/*/*/*/*.t
			)
	},
	INSTALLMAN3DIR => 'none'
);

WriteAll;

# substitute prefix everywhere
$MY::Variables{SYSCONFDIR} =~ s/\$\(PREFIX\)/$MY::Variables{PREFIX}/;
$MY::Variables{DATADIR} =~ s/\$\(PREFIX\)/$MY::Variables{PREFIX}/;
$MY::Variables{LOCALSTATEDIR} =~ s/\$\(PREFIX\)/$MY::Variables{PREFIX}/;

my $ConfigFileMessage
	= -f "$MY::Variables{SYSCONFDIR}/agent.cfg"
	? "previous configuration file found, new one will be installed as agent.cfg.new"
	: "no previous configuration file found, new one will be installed as agent.cfg";

print <<EOF;

Installation summary
--------------------
PREFIX : $MY::Variables{PREFIX}
Configuration installation directory: $MY::Variables{SYSCONFDIR}
Constant data installation directory: $MY::Variables{DATADIR}
Variable data installation directory: $MY::Variables{LOCALSTATEDIR}

$ConfigFileMessage
EOF

package MY;

use English qw(-no_match_vars);

our %Variables;

sub setWin32Variables {

	%Variables = (
		PREFIX               => 'C:\\Program Files\\Armadito-Agent',
		INSTALLSCRIPT        => '$(PREFIX)\\bin',
		INSTALLSITESCRIPT    => '$(PREFIX)\\bin',
		INSTALLVENDORSCRIPT  => '$(PREFIX)\\bin',
		INSTALLLIB           => '$(PREFIX)\\lib',
		INSTALLSITELIB       => '$(PREFIX)\\lib',
		INSTALLVENDORLIB     => '$(PREFIX)\\lib',
		INSTALLMAN1DIR       => '$(PREFIX)\\share\\man\\man1',
		INSTALLSITEMAN1DIR   => '$(PREFIX)\\share\\man\\man1',
		INSTALLVENDORMAN1DIR => '$(PREFIX)\\share\\man\\man1',
		INSTALLMAN3DIR       => '$(PREFIX)\\share\\man\\man3',
		INSTALLSITEMAN3DIR   => '$(PREFIX)\\share\\man\\man3',
		INSTALLVENDORMAN3DIR => '$(PREFIX)\\share\\man\\man3',
		SYSCONFDIR           => '$(PREFIX)\\etc',
		DATADIR              => '$(PREFIX)\\share',
		LOCALSTATEDIR        => '$(PREFIX)\\var',
	);
}

sub setLinuxVariables {

	%Variables = (
		DESTDIR              => '',
		PREFIX               => '/usr/local',
		INSTALLSCRIPT        => '$(PREFIX)/bin',
		INSTALLSITESCRIPT    => '$(PREFIX)/bin',
		INSTALLVENDORSCRIPT  => '$(PREFIX)/bin',
		INSTALLLIB           => '$(DATADIR)/lib',
		INSTALLSITELIB       => '$(DATADIR)/lib',
		INSTALLVENDORLIB     => '$(DATADIR)/lib',
		INSTALLMAN1DIR       => '$(DESTDIR)$(PREFIX)/share/man/man1',
		INSTALLSITEMAN1DIR   => '$(DESTDIR)$(PREFIX)/share/man/man1',
		INSTALLVENDORMAN1DIR => '$(DESTDIR)$(PREFIX)/share/man/man1',
		INSTALLMAN3DIR       => '$(DESTDIR)$(PREFIX)/share/man/man3',
		INSTALLSITEMAN3DIR   => '$(DESTDIR)$(PREFIX)/share/man/man3',
		INSTALLVENDORMAN3DIR => '$(DESTDIR)$(PREFIX)/share/man/man3',
		SYSCONFDIR           => '$(DESTDIR)$(PREFIX)/etc/armadito-agent',
		DATADIR              => '$(DESTDIR)$(PREFIX)/share/armadito-agent',
		LOCALSTATEDIR        => '$(DESTDIR)$(PREFIX)/var/armadito-agent',
	);
}

sub overrideVariablesWithArgs {
	my ($self) = @_;

	foreach my $name ( keys %Variables ) {
		$Variables{$name} = $self->{ARGS}->{$name} if $self->{ARGS}->{$name};
	}
}

sub parseConstantDefinition {
	my ($constant_definition) = @_;

	if ( $constant_definition =~ /^\s*#/ ) {
		return "";
	}

	if ( $constant_definition !~ /^([A-Z0-9_]+) =/ ) {
		return "";
	}

	return $1;
}

sub updateConstants {
	my ($self) = @_;

	my @constants = split( /\n/, $self->SUPER::constants(@_) );

	foreach my $constant_definition (@constants) {
		my $constant = parseConstantDefinition($constant_definition);

		if ( $constant ne ""
			&& defined( $Variables{$constant} ) )
		{
			$constant_definition = "$constant = $Variables{$constant}";
		}
	}

	foreach my $constant (qw/SYSCONFDIR DATADIR LOCALSTATEDIR/) {
		push @constants, "$constant = $Variables{$constant}";
	}

	return join( "\n", @constants );
}

sub constants {
	my ($self) = @_;

	if ( $OSNAME eq "MSWin32" ) {
		setWin32Variables();
	}
	else {
		setLinuxVariables();
	}

	overrideVariablesWithArgs($self);

	return updateConstants($self);
}

sub install {
	my ($self) = @_;
	my $install = $self->SUPER::install(@_);

	$install =~ s/install :: pure_install doc_install/install :: pure_install config_install data_install/;
	$install =~ s/install :: all pure_install doc_install/install :: all pure_install config_install data_install/;
	$install =~ s/.*\.packlist \\\n//g;

	if ( $OSNAME eq "MSWin32" ) {
		$install .= getWin32Install();
	}
	else {
		$install .= getLinuxInstall();
	}

	$install =~ s/[ ]{4}/\t/msg;

	return $install;
}

sub getLinuxInstall {

	return '
config_install :
    install -d -m 755 $(SYSCONFDIR)
' . installLinuxConfFile("agent.cfg") . '
' . installLinuxConfFile("scheduler-cron.cfg") . '

data_install :
	install -d -m 755 $(DATADIR)
	install -d -m 775 $(LOCALSTATEDIR)';
}

sub getWin32Install {

	return '
config_install :
    if not exist "$(SYSCONFDIR)" mkdir "$(SYSCONFDIR)"
' . installWin32ConfFile("agent.cfg") . '
' . installWin32ConfFile("scheduler-win32native.cfg") . '

data_install :
	if not exist "$(DATADIR)" mkdir "$(DATADIR)"
	if not exist "$(INSTALLSCRIPT)" mkdir "$(INSTALLSCRIPT)"
	if exist "$(INSTALLSCRIPT)\\armadito-agent" @erase "$(INSTALLSCRIPT)\\armadito-agent"
	copy "bin\\armadito-agent" "$(INSTALLSCRIPT)\\armadito-agent"';
}

sub installWin32ConfFile {
	my ($conf_file) = @_;

	return '
	if exist "$(SYSCONFDIR)\\' . $conf_file . '" ( \
	    copy "etc\\' . $conf_file . '" "$(SYSCONFDIR)\\' . $conf_file . '.new"; \
	) else ( \
	    copy "etc\\' . $conf_file . '" "$(SYSCONFDIR)\\' . $conf_file . '"; \
	)';
}

sub installLinuxConfFile {
	my ($conf_file) = @_;

	return '
	if [ -f $(SYSCONFDIR)/' . $conf_file . ' ]; then \
	    install -m 644 etc/' . $conf_file . ' $(SYSCONFDIR)/' . $conf_file . '.new; \
	else \
	    install -m 644 etc/' . $conf_file . ' $(SYSCONFDIR)/' . $conf_file . '; \
	fi';
}

# ensure binaries get modified to use configured directories (on Unix only)
sub installbin {
	my ($self) = @_;
	my $installbin = $self->SUPER::installbin(@_);

	return $installbin if $OSNAME eq 'MSWin32';

	$installbin =~ s|\t\$\(FIXIN\) (.*)\n|\t\$(FIXIN) $1\n\t\$(FINALIZE) $1\n|g;

	$installbin .= <<'EOF';
FINALIZE = $(ABSPERLRUN) -pi \
    -e 's|use lib .*|use lib "$(DATADIR)/lib";|;' \
    -e 's|confdir => .*|confdir => "$(SYSCONFDIR)",|;' \
    -e 's|datadir => .*|datadir => "$(DATADIR)",|;' \
    -e 's|libdir  => .*|libdir  => "$(DATADIR)/lib",|;' \
    -e 's|vardir  => .*|vardir  => "$(LOCALSTATEDIR)",|' \
    --
EOF
	return $installbin;
}
