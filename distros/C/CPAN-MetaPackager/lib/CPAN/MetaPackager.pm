package CPAN::MetaPackager;

use 5.36.0;

our $VERSION = '1.03';

#-------------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaPackager - Manage the cpan.metapackager.sqlite database

=head1 How to convert a package details file into an SQL db

=over
=item My web host and I use case-sensitive file systems
=item The distro CPAN-MetaPackager-1.00.tgz ships with data/cpan.metapackager.sqlite
=item (15 Mb) which is the output of running scripts/build.db.sh
=item You will need your own copy of 02packages.details.txt.gz to run scripts/build.db.sh
=item 02packages.details.txt.gz contains 9 header lines & about 270,458 records
=back

=over
=item cd /tmp
=item Run: wget https://www.cpan.org/modules/02packages.details.txt.gz
=item Run: gunzip 02packages.details.txt.gz
=item Run: tar xvf CPAN-MetaPackager-1.00.tgz
=item cd CPAN-MetaPackager
=item The next command will take 104 minutes for 264,956 records on my Levono M70Q 'Tiny' desktop
=item Run: time scripts/build.db.sh
=item Output file: data/cpan.metapackager.sqlite
=item cp data/cpan.metapackager.sqlite /tmp
=item Run: git push
=item Now run CPAN::MetaCurator. It defaults to (optionally) reading /tmp/cpan.metapackager.sqlite
=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/CPAN-MetaPackager>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-MetaPackager>.

=head1 Author

Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

My homepage: L<https://savage.net.au/>.

=head1 License

Perl 5.

=head1 Copyright

Australian copyright (c) 2026, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
