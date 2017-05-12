use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

my %pkg_info = ExtUtils::PkgConfig->find('xmms2-client');

WriteMakefile(
		NAME			=> 'Audio::XMMSClient',
		VERSION_FROM	=> 'pm/XMMSClient.pm',
		ABSTRACT     	=> 'Interface to the xmms2 music player',
		XSPROTOARG		=> '-noprototypes',
		MAN3PODS		=> {
			'pm/XMMSClient.pm'	                => '$(INST_MAN3DIR)/Audio::XMMSClient.$(MAN3EXT)',
			'pm/XMMSClient/Glib.pm'	            => '$(INST_MAN3DIR)/Audio::XMMSClient::Glib.$(MAN3EXT)',
		},
		PM				=> {
			'pm/XMMSClient.pm'	                => '$(INST_LIBDIR)/XMMSClient.pm',
			'pm/XMMSClient/Glib.pm'	            => '$(INST_LIBDIR)/XMMSClient/Glib.pm',
		},
		INC				=> '-Wall -Werror -I. '.$pkg_info{cflags},
		LIBS			=> $pkg_info{libs},
		do {
			my @clean;
			my @OBJECT;
			my %XS;

			for my $xs (<*.xs>) {
				(my $c = $xs) =~ s/\.xs$/\.c/i;
				(my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;

				$XS{$xs} = $c;
				push @OBJECT, $o;
				push @clean, $o;
			}

			for my $c (<perl_xmmsclient*.c>) {
				(my $o = $c) =~ s/\.c/\$(OBJ_EXT)/i;

				push @OBJECT, $o;
				push @clean, $o;
			}

			clean   => { FILES => join(' ', @clean) },
			OBJECT  => join(' ', @OBJECT),
			XS      => \%XS

		}
);

package MY;

use strict;
use warnings;

sub postamble {
    return <<"EOP"
PODS = XMMSClient.pod XMMSClientResult.pod XMMSClientPlaylist.pod

.xs.pod :
\tperldoc -u \$< > \$@

docs: \$(PODS)
\t\$(PERL) -e'for my \$\$pod (qw{\$^}) { (my \$\$new_name = \$\$pod) =~ s!(XMMSClient)([^\\.]+)!\$\$1/\$\$2!; rename \$\$pod, "pm/\$\$new_name" }'

.SUFFIXES: .pod
EOP
}
