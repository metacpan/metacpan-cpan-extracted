package Config::INI::Access;

use vars qw ($VERSION);
$VERSION = '0.9999';

use strict;
use Config::INI::Reader;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(config);

my $Config = {};
bless $Config, __PACKAGE__;

our $AUTOLOAD;
sub AUTOLOAD {
    my $key = shift;
    my $subkey = $AUTOLOAD;

    $subkey =~ s{.*::}{};

	$key = exists $key->{$subkey} ? $key->{$subkey} : bless {}, __PACKAGE__;

    if (ref $key) {
		return bless $key, __PACKAGE__;
	}
	else {
		return $key;
	}
}

sub DESTROY {
}

sub config {
    return $Config;
}

sub load {
	my $this = shift;
    my $filename = shift;

	return 0 unless -e $filename;

    my $ini = Config::INI::Reader->read_file($filename);

    my $c = 0;
    foreach my $section (keys %$ini) {
        unless ($Config->{$section}) {
			if ('_' eq $section) {
				foreach my $key (keys %{$ini->{$section}}) {
					$Config->{$key} = $ini->{$section}->{$key};
					$c++;
				}	
			}
			else {
	            $Config->{$section} = $ini->{$section};
				$c += keys %{$ini->{$section}};
			}
        }
        else {
            foreach my $key (keys %{$ini->{$section}}) {
                $Config->{$section}->{$key} = $ini->{$section}->{$key};
                $c++;
            }
        }
    }

    return $c;
}

1;

__END__

=head1 NAME

Config::INI::Access - Syntactic sugar for accessing data from .ini-files

=head1 SYNOPSIS

	use Config::INI::Access;

	config->load('config.ini');

	print config->section->key;

=head1 ABSTRACT

Config::INI::Access allows to access configuration data stored in Windows-formatted 
.ini-files with arrows rather than hash braces.

=head1 DESCRIPTION

Module exports the only user subroutine C<config>. You should first load the 
.ini-file calling C<load()> method, and then receive access to the structure 
of configuration via Perl's pointer C<-E<gt>>.

INI structure is in fact a hash, but rather than typing extra sigil and braces 
for accessing hash and subhash elements you simply use an arrow:

	print config->section_name->key_name;

Note that no C<$> sigil comes before C<config>.

Global keys are available directly:

	print config->global_key_name;

At any time configuration may be redefined by calling C<load()> once more:

	config->load('config1.ini');
	print config->section->key;

	config->load('config2.ini');
	print config->section->key;

Keys and values defined in both files are redefined so that keys from a second one
replace previously defined. Values that were not redefined remain with their
initial values.

=head2 TODO

This module should return C<undef> for attempts of reading the key that 
does not exists. Right now hash syntax may be used to learn out if the
element does not exist:
    
    $unknown = config->non_existing if config->{'non_existing'};
    $unknown = config->section->non_existing if config->section->{'non_existing'};
 
=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head2 THANKS

Thanks to Ivan Serezhkin for helping with arrows, asterisks and packages--all the dark sides of Perl.

=head1 COPYRIGHT AND LICENSE

Config::INI::Access module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl.

=cut
