package App::ssl4curl;

use warnings;
use strict;

use Cwd;
use Config;
use open qw<:encoding(UTF-8)>;

=head1 NAME

App::ssl4curl - Install and setup Mozilla certificates for curl SSL/TLS from ~/.bashrc

=cut

BEGIN {
    require Exporter;
    our $VERSION = 1.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( get_ca install_ca );
}


my( %option, $mozilla_ca_path, $mk_ca_bundle_script ) = ();
my $CURL_CA_BUNDLE = '';

# setup cpan
$ENV{PERL_MM_USE_DEFAULT}=1;

#sub install_ca {
    my $install_ca = sub {
# use cpan to install Mozilla::CA
        system("perl -MCPAN -e 'install Mozilla::CA'");
    };
#}

sub get_ca {
    #my $option = shift;
    my $get_ca = sub {
# find Mozilla::CA installed path 
        open my $pipe,"-|", 'perldoc -l Mozilla::CA';
        while(<$pipe>){ $mozilla_ca_path = $_ }
        close $pipe;

# find path to mk-ca-bundle.pl
        $mk_ca_bundle_script = $mozilla_ca_path;
        $mk_ca_bundle_script =~ s/(.*)(\/CA\.pm)/$1/;
        $mk_ca_bundle_script = $1;
        $mk_ca_bundle_script = "$mk_ca_bundle_script" . '/' . 'mk-ca-bundle.pl';

# execute mk-ca-bundle.pl to download certificates
        open $pipe,"-|", "$mk_ca_bundle_script 2>&1";
        close $pipe;

# find path to created cacert.pem
        my $cwd = getcwd();
        chomp $mozilla_ca_path;
        $mozilla_ca_path =~ s/(.*)(\.pm)/$1/;
# make export string
        $CURL_CA_BUNDLE = $mozilla_ca_path . '/' . 'cacert.pem';
    };
    return $CURL_CA_BUNDLE unless $get_ca->();
}


=head1 SYNOPSIS

=over 12

=item Install Mozilla::CA module and setup certificates for curl SSL/TLS from ~/.bashrc

=back

=head1 GIF

=over 12

L<https://github.com/z448/ssl4curl>

=back

=head1 USAGE

=over 12 

- Initialize from command line as root or use sudo. Use normal user if you have local::lib set up. This will install Mozilla::CA module.

C<udo ssl4curl -i>

- Add to ~/.bashrc to check/download and setup certificates on start of every session

C<export `ssl4curl -p`>

- Execute on command line to check/download certificates and list export string. You can add output string into your ~/.bashrc in which case certificate setup will be skiped on start of session.

C<ssl4curl>

- Print this documentation

C<ssl4curl -h>

=back

=head1 AUTHOR

Zdenek Bohunek , C<< <zdenek@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Zdenek Bohunek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

