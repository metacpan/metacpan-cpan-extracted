package CPAN::MetaCurator;

use 5.36.0;

our $VERSION = '1.15';

#-------------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaCurator - Manage the cpan.metacurator.sqlite database

=head1 How to convert a Perl.Wiki.html into a jsTree

Note: My web host and I use case-sensitive file systems.

=head2 Prepare wikis
=over
=item cd ~/savage.net.au/
=item Edit Perl.Wiki, etc. Includes updating the release date. Save to ~/Downloads/
=item cp ~/Downloads/*.Wiki.html to misc/
=item git commit -am"Update Perl.Wiki V 1.xx"
=item mv ~/Downloads/*.Wiki.html to $DH (/dev/shm/html on my machine) for eye-ball check via FF
=back

=head2 Export Perl.Wiki.html
=over
=item In the 'Tools' tab click 'export all'
=item In the export menu click 'JSON format'. This creates ~/Downloads/tiddlers.json
=item cd ~/perl.modules/CPAN-MetaCurator
=item mv ~/Downloads/tiddlers.json data/tiddlers.json
=back

=head2 Rebuild Perl Wiki Tree

Note: Optionally use sqlite database (15 Mb) from CPAN::MetaPackager

=over
=item Set env var INCLUDE_PACKAGES=1 if you have /tmp/cpan.metapackager.sqlite available & to 0 (default) otherwise
=item Run scripts/build.db.sh to import tiddlers.json file into database data/cpan.metacurator.sqlite
=item Run scripts/export.tree.sh to export CPAN::MetaCurator database to html/cpan.metacurator.tree.html
=item git push
=back

=head2 Patch ~/savage.net.au/index.html
=over
=item cd ~/perl.modules/Local-Website
=item Edit Local::Website::Util::PatchIndex's sub parser() if necessary
=item Run scripts/parse.index.sh to patch ~/savage.net.au/index.html
=item cp index.html $DH
=item Backup new files: bu5.sh savage.net.au
=item Backup new files: bu5.sh perl.modules
=back

=head2 Upload
=over
=item Upload Perl.Wiki.html, etc to savage.net.au
=item Upload index.html
=item Log in to blogs.perl.org
=item Post details of the uploads
=item Wait ... Check how it appears on blogs.perl.org. Takes about 1 min
=back

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/CPAN-MetaCurator>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-MetaCurator>.

=head1 Author

Current maintainer: Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

My homepage: L<https://savage.net.au/>.

=head1 License

Perl 5.

=head1 Copyright

Australian copyright (c) 2025, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
