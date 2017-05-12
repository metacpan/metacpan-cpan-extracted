
package Cz::Cstocs::Getopt;

use strict;
use Cz::Cstocs;
use Getopt::Long;

sub usage {
	print_version();
	print STDERR <<EOF;
Usage: cstocs [options] inputencoding outputencoding [ files ... ]
  where options can be
    -i[.ext]		In-place substitution; must be the first parameter.
    --dir=string	Alternate directory with encoding and accent files.
    --fillstring=str	String that will replace unconvertable characters,
			the default is one space.
    --null		Equivalent to --fillstring=""
    --nofillstring	Keep unconvertable unconverted.
    --onebymore		Use all entries from the accent file (the default).
    --onebyone		Use only one-by-one character rules from accent file.
    --nochange, --noaccent	Do not use accent file at all.
    --version		Print out the version information.
    --debug		Print out debugging info while processing.
Input and output encodings can also be specified using --inputencoding
and --outputencoding options. See man page for detailed description.
Available encodings are:
  @{[ &Cz::Cstocs::available_enc() ]}
EOF
	exit;
}

sub print_version {
	print STDERR "This is cstocs version $Cz::Cstocs::VERSION.\n";
}

sub process_argv {
	my $getopt_config_hashref = shift;
	my %options;
	my $options = \%options;

	$getopt_config_hashref = {} unless defined $getopt_config_hashref;
	for my $key (keys %$getopt_config_hashref) {
		my $value = $getopt_config_hashref->{$key};
		### print "Key $key -> $value\n";
		$getopt_config_hashref->{$key} = \$options{$value}
			unless ref $value;
	}
	my %getopt_config = (
		'null' =>	sub { $options{'fillstring'} = ''; },
		'fillstring=s' =>	\$options{'fillstring'},
		'nofillstring' =>	sub { $options{'nofillstring'} = 1 },
		'usefillstring' =>	sub { $options{'nofillstring'} = 0 },

		'onebyone' =>	sub { $options{'one_by_one'} = 1; },
		'onebymore' =>	sub { $options{'one_by_one'} = 0; },

		'noaccent',	sub { $options{'use_accent'} = 0; },
		'nochange',	sub { $options{'use_accent'} = 0; },

		'dir=s' =>	\$options{'cstocsdir'},

		'inputencoding=s' =>	\$options{'inputenc'},
		'outputencoding=s' =>	\$options{'outputenc'},

		'help'	=>	\&usage,
		'version' =>	sub { print_version(); exit 0; },
		'debug' =>	sub { $Cz::Cstocs::DEBUG = 1; },
		%$getopt_config_hashref
		);

	if (grep { /--/ } @ARGV) {
		Getopt::Long::GetOptions(%getopt_config);
	} elsif (@ARGV < 2) {
		usage();
	}

	my ($inputenc, $outputenc);
	if (defined $options{'inputenc'}) {
		$inputenc = $options{'inputenc'};
		delete $options{'inputenc'};
	} else {
		$inputenc = shift @ARGV;
	}

	if (defined $options{'outputenc'}) {
		$outputenc = $options{'outputenc'};
		delete $options{'outputenc'};
	} else {
		$outputenc = shift @ARGV;
	}

	my $tag;
	for $tag (keys %options) {
		delete $options{$tag} unless defined $options{$tag};
	}
	print STDERR "Calling new Cz::Cstocs $inputenc, $outputenc\n" if Cz::Cstocs::DEBUG;
	my $convert = new Cz::Cstocs $inputenc, $outputenc, %options;

	$options{'inputenc'} = $inputenc;
	$options{'outputenc'} = $outputenc;
	if (wantarray) {
		return ($convert, $options);
	}
	return $convert;
}

1;

