# -*- perl -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Pod::Find qw(pod_where);
use Pod::Usage;

WriteMakefile(NAME => 'App::Glacier',
	      ABSTRACT_FROM => 'glacier',
	      VERSION_FROM => 'glacier',
	      AUTHOR    =>      'Sergey Poznyakoff <gray@gnu.org>',
	      LICENSE   =>      'gpl_3',
	      EXE_FILES =>      [ 'glacier' ],
	      PREREQ_PM =>      { 'Carp' => 1.26,
				  'Data::Dumper' => 2.135_06,
				  'DateTime' => 1.42,
				  'DateTime::Format::ISO8601' => 0.08,
				  'Digest::SHA' => 5.85,
				  'Exporter' => 5.66,
				  'File::Basename' => 2.84,
				  'File::Path' => 2.08_01,
				  'File::stat' => 1.05,
				  'GDBM_File' => 1.14,
				  'Getopt::Long' => 2.38,
				  'JSON' => 2.90,
				  'Net::Amazon::Glacier' => 0.15,
				  'POSIX' => 1.30,
				  'Pod::Find' => 1.51,
				  'Pod::Man' => 2.25,
				  'Pod::Usage' => 1.51,
				  'Scalar::Util' => 1.47,
				  'Storable' => 2.34,
				  'Term::ReadKey' => 2.32
	      } );

sub pod_command_name {
    my ($pack) = @_;
    my %args;
    
    my $msg = "";

    open my $fd, '>', \$msg;

    $args{-input} = pod_where({-inc => 1}, $pack);
    pod2usage(-verbose => 99,
	      -sections => 'NAME',
	      -output => $fd,
	      -exitval => 'NOEXIT',
	      %args);

    my @a = split /\n/, $msg;
    return undef if $#a < 1;
    $msg = $a[1];
    $msg =~ s/^\s+//;
    $msg =~ s/ - .*$//;
    return $msg;
}

sub MY::postamble {
    my $s = <<'_MAKE_'
all:: subcommand-manpages
.PHONY: subcommand-manpages
subcommand-manpages: manifypods
	$(NOECHO) $(ECHO) Generating manpages for the subcommands    
_MAKE_
;
    push @INC, 'lib';
    foreach my $file (glob("lib/App/Glacier/Command/*.pm")) {
	my $mod = $file;
	$mod =~ s{^.*lib/}{};
	$mod =~ s{\.pm$}{};
	$mod =~ s{/}{::}g;
	if (my $command = pod_command_name($mod)) {
	    my $man1file = $command;
	    $man1file =~ s/ /-/;
	    $man1file .= '.$(MAN1EXT)';
	    $s .= "\t\$(NOECHO)sed 's/$mod 3/$command 1/' \$(INST_MAN3DIR)/$mod.\$(MAN3EXT) > \$(INST_MAN1DIR)/$man1file\n"
	}
    }
    pop @INC; 
    $s .= "\n";
    return $s;
}
