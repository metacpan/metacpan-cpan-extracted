#!/usr/bin/perl
use strict;
use lib 'lib';
use Conan::Configure::Xen;

my $bd = Conan::Configure::Xen->new(basedir => '/tmp')->{basedir};

print "Basedir: $bd\n";

my $new_settings = shift;

for( @ARGV ){
	my $s = $bd . "/" . $_;
	print "Searching: $s\n";
	my @files = glob "$s"  ;
	print "File: " . join( ",", @files ) . "\n";

	next unless $new_settings =~ /^\S+\s*=\s*\S.*$/;
	my $key = $1 if $new_settings =~ /^(\S+)/;

	# Check if there are quotes around the val
	unless( $new_settings =~ /^\S+\s*=\s*'(.*?)'/ ){
		my $val = $1 if $new_settings =~ /^\S+\s*=\s*(\S.*)$/ ;
		$new_settings = sprintf "%s = '%s'", $key, $val;
	}

	print "Updating: [$new_settings]\n";

	for my $fn ( @files ){
		print "Executing [perl -p -i -e \"s/^$key.*/$new_settings/\" $fn]\n";
		open my $fd, "perl -p -i -e \"s/^$key.*/$new_settings/\" $fn |";
		print <$fd> . "\n";
	}
}

__END__

=head1 NAME

conan-config

=head1 SYNOPSIS

This script is used for updating xen configuration files.

=head1 DESCRIPTION

The script takes a key/value pair as the first parameter, followed by a regex that matches a fileset within the basedir of the config.

  my $bd = Conan::Configure::Xen->new(basedir => '/tmp')->{basedir};

=head2 USAGE

perl scripts/conan-update.pl "version = '2.3'" 'foo0[5-9].cfg'

