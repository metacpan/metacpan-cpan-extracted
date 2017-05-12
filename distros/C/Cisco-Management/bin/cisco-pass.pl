#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::Management;

my $PASSWORD_LINES = "( password 7 )|(-server key 7 )|( key-string 7 )";
my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'encrypt:s' => \$opt{encrypt},
  'help!'     => \$opt_help,
  'man!'      => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Make sure at least one host was provided
if (!@ARGV) {
    pod2usage(-verbose => 0, -message => "$0: argument required\n")
}

if (defined($opt{encrypt})) {
    if (my $passwd = Cisco::Management->password_encrypt($ARGV[0], $opt{encrypt})) {
        print "$_\n" for (@{$passwd})
    } else {
        printf "Error - %s\n", Cisco::Management->error
    }
} else {
    my @passwords;
    my $linecnt = 0;
    if (-e $ARGV[0]) {
        open(IN, $ARGV[0]);
        while (<IN>) {
            chomp $_;
            if ($_ =~ $PASSWORD_LINES) { push @passwords, "($linecnt) " . $_; }
            $linecnt++
        }
        close (IN)
    } else {
        push @passwords, $ARGV[0]
    }

    for (@passwords) {
        my @parts = split(/ /,$_);
        if (my $passwd = Cisco::Management->password_decrypt($parts[$#parts])) {
            if ($linecnt > 0) {
                print "@parts = $passwd\n"
            } else {
                print "$passwd\n"
            }
        } else {
            printf "Error - %s\n", Cisco::Management->error
        }
    }
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-PASS - Cisco Password Decrypter

=head1 SYNOPSIS

 cisco-pass [options] string

=head1 DESCRIPTION

Decrypts Cisco type 7 passwords.

=head1 ARGUMENTS

 string           Encrypted Cisco type 7 password or filename 
                  of Cisco config file - all passwords found 
                  will be decrypted.

=head1 OPTIONS

 -e [#]           Interpret 'string' as cleartext and encrypt it
 --encrypt        instead of decrypting.  Optional number means 
                  return only the password encrypted by index #.  
                  Range is 0 - 52.  Using a non-numerical value 
                  causes the password to be encrypted by a random 
                  index.
                  DEFAULT:  (or not specified) return all.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
