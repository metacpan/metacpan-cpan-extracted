package CACertOrg::CA;

use strict;
use vars qw( $VERSION );
$VERSION = '20110724.005';

use Cwd            qw();
use File::Spec     qw();
use File::Basename qw(dirname);

sub SSL_ca_file { # Stolen from Mozilla::CA
    my $file = File::Spec->catfile( dirname(__FILE__), "CA", "root.crt" );

    unless( File::Spec->file_name_is_absolute($file) ) {
		$file = File::Spec->catfile(Cwd::cwd(), $file);
    	}

    return $file;
	}

1;

__END__

=encoding utf8

=head1 NAME

CACertOrg::CA - CACert.org's CA root certificate in PEM format

=head1 SYNOPSIS

    use LWP::UserAgent;
    use CACertOrg::CA;

    my $ua = LWP::UserAgent->new( ... );
    $ua->ssl_opts(
    	verify_hostnames => 1,
		SSL_ca_file      => CACertOrg::CA::SSL_ca_file(),
		)

=head1 DESCRIPTION

CACertOrg::CA provides a copy of Certificate Authority
certificate for CACert.org. This is the Class 1 PKI Key.

sha1 13:5C:EC:36:F4:9C:B8:E9:3B:1A:B2:70:CD:80:88:46:76:CE:8F:33

md5 A6:1B:37:5E:39:0D:9C:36:54:EE:BD:20:31:46:1F:6B

=head2 Functions

The module provide a single function:

=over

=item SSL_ca_file()

Returns the absolute path to the CA cert PEM file.

=back

=head1 SEE ALSO

L<http://www.cacert.org/policy/RootDistributionLicense.php>

L<http://www.cacert.org/index.php?id=3>

=head1 LICENSE

For the bundled CACert.org CA PEM file license comes from:

	http://www.cacert.org/policy/RootDistributionLicense.php

Root Distribution License

=head2 1. Terms

"CAcert Inc" means CAcert Incorporated, a non-profit association
incorporated in New South Wales, Australia.

"CAcert Community Agreement" means the agreement entered into by each
person wishing to RELY.

"Member" means a natural or legal person who has agreed to the CAcert
Community Agreement.

"Certificate" means any certificate or like device to which CAcert
Inc's digital signature has been affixed.

"CAcert Root Certificates" means any certificate issued by CAcert Inc
to itself for the purposes of signing further CAcert Roots or for
signing certificates of Members.

"RELY" means the human act in taking on a risk or liability on the
basis of the claim(s) bound within a certificate issued by CAcert.

"Embedded" means a certificate that is contained within a software
application or hardware system, when and only when, that software
application or system is distributed in binary form only.

=head2 2. Copyright

CAcert Root Certificates are Copyright CAcert Incorporated. All rights
reserved.

=head2 3. License

You may copy and distribute CAcert Root Certificates only in
accordance with this license.

CAcert Inc grants you a free, non-exclusive license to copy and
distribute CAcert Root Certificates in any medium, with or without
modification, provided that the following conditions are met:

Redistributions of Embedded CAcert Root Certificates must take
reasonable steps to inform the recipient of the disclaimer in section
4 or reproduce this license and copyright notice in full in the
documentation provided with the distribution.

Redistributions in all other forms must reproduce this license and
copyright notice in full.

=head2 4. Disclaimer

THE CACERT ROOT CERTIFICATES ARE PROVIDED "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED TO THE MAXIMUM EXTENT PERMITTED BY LAW. IN NO EVENT SHALL
CACERT INC, ITS MEMBERS, AGENTS, SUBSIDIARIES OR RELATED PARTIES BE
LIABLE TO THE LICENSEE OR ANY THIRD PARTY FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THESE CERTIFICATES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE. IN ANY EVENT, CACERT'S LIABILITY SHALL NOT EXCEED $1,000.00
AUSTRALIAN DOLLARS.

THIS LICENSE SPECIFICALLY DOES NOT PERMIT YOU TO RELY UPON ANY
CERTIFICATES ISSUED BY CACERT INC. IF YOU WISH TO RELY ON CERTIFICATES
ISSUED BY CACERT INC, YOU MUST ENTER INTO A SEPARATE AGREEMENT WITH
CACERT INC.

=head2 5. Statutory Rights

Nothing in this license affects any statutory rights that cannot be
waived or limited by contract. In the event that any provision of this
license is held to be invalid or unenforceable, the remaining
provisions of this license remain in full force and effect.

=cut
