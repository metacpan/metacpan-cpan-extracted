#!/usr/bin/perl -w

use strict;
use vars qw($VERSION);

$VERSION = '2.00';

use Getopt::Long;
use DBIx::PasswordIniFile;
use Config::IniFiles;

# Command line Arguments.
my($ini_file, $section, $key, $cipher);
GetOptions(
             'inifile|f=s' => \$ini_file,
             'section|s=s' => \$section,
             'key|k:s'     => \$key,
             'cipher|c:s'  => \$cipher
           );

die "!! $ini_file does not exist" if ! -e $ini_file;

my $cfg = new Config::IniFiles( -file => $ini_file ) || die $!;

# Guess 'pass' or 'password'  
# 'driver' param was mandatory with old content model for .ini file,
# and with new content model, this param does't exist.
# So, existence or not existence of this param determines content model.
#
my $param = ( $cfg->exists($section,'driver') 
           ? 'password' 
           : 'pass');
my $clear_passw = $cfg->val($section, $param);

my $ini = DBIx::PasswordIniFile->new( 
             -file => $ini_file, 
             -section => $section, 
             $key ? ( -key => $key ) : (),
             $cipher ? ( -cipher => $cipher ) : ()
         );

my $encrypt_passw = $ini->changePassword( $clear_passw );

print "Value of $param parameter changed to:\n$encrypt_passw\n"; 

__END__

=head1 NAME

encpassw.pl - Encrypts password in C<.ini> files

=head1 DESCRIPTION

Reads the value of a property C<password> in a configuration file ('a la'
C<.ini> style), and rewrites the value with the result of its encryption.

Style C<.ini> configuration files are those with a syntax compatible with
C<Config::IniFiles>, and briefly this means:

=over 4

=item *

Lines beginning with C<#> are comments and are ignored. Also, blank lines are
ignored. Use this for readability purposes.

=item *

A section name is a string (including whitespaces) between C<[> and C<]>.

=item *

Each section has one or more property/value pairs. Each property/value pair
is specified with the syntax

    property=value

One property/value pair per line.

=back

See L<Config::IniFiles> for detailed information about syntax.

=head1 SYNTAX

    perl encpassw.pl --inifile=<ini_file> 
                     --section=<section_name_of_ini_file_with_password_param>
                     [--key=<encryption_decryption_key> ]
                     [--cipher=<encryption_decryption_algorithm> ]

=head1 ARGUMENTS

=over 4

=item --inifile

Name or pathname of file whose password value have to be encrypted.
It doen't need to have C<.ini> in its name.

=item --section

Section name in C<inifile> where the C<password> property is.

=item --key

Encryption / Decryption key in clear form.
Use the same value with C<DBIx::PasswordIniFile>.

=item --cipher

Name of an installed cipher algoritm. Cipher algorithms live in namespace 
C<Crypt::>.

If not specified, default is C<Crypt::Blowfish>. It must be installed.

=back

=head1 COPYRIGHT

Copyright 2010-2020 Enrique Castilla.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

This program is distributed in the hope that it will be useful, but without any 
warranty; without even the implied warranty of merchantability or fitness for a 
particular purpose. 

=head1 AUTHOR

Enrique Castilla E<lt>L<mailto:ecastillacontreras@yahoo.es|ecastillacontreras@yahoo.es>E<gt>.
