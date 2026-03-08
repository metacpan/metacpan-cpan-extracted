package CPAN::MetaCurator;

use 5.36.0;

our $VERSION = '1.11';

#-------------------------------------------------

1;

=pod

=head1 How to convert a Perl.Wiki.html into a jsTree

Note: My web host and I use case-sensitive file systems.

A: Prepare wikis
1: cd ~/savage.net.au/
2: Edit Perl.Wiki, etc. Includes updating the release date. Save to ~/Downloads/
3: cp ~/Downloads/*.Wiki.html to misc/
4: git commit -am"Update Perl.Wiki V 1.xx"
5: mv ~/Downloads/*.Wiki.html to $DH

B: Export Perl.Wiki.html
1: In the 'Tools' tab click 'export all'
2: In the export menu click 'JSON format'. This creates ~/Downloads/tiddlers.json
3: cd ~/perl.modules/CPAN-MetaCurator
4: mv ~/Downloads/tiddlers.json data/tiddlers.json

C: Rebuild Perl Wiki Tree
1: Run scripts/build.db.sh to import tiddlers.json file into database data/cpan.metacurator.sqlite
2: Run scripts/export.tree.sh to export database to html/cpan.metacurator.tree.html
3: Run script to backup new files: bu5.sh savage.net.au

D: Patch ~/savage.net.au/index.html
1: cd ~/perl.modules/Local-Website
2: Edit Local::Website::Util::PatchIndex's sub parser() if necessary
3: Run scripts/parse.index.sh to patch ~/savage.net.au/index.html
4: cp index.html $DH
5: cp misc/*.Wiki.html $DH/misc

E: Upload
1: Upload Perl.Wiki.html, etc to savage.net.au
2: Upload index.html
3: Log in to blogs.perl.org
4: Post details of the uploads
5: Wait ... Check how it appears on blogs.perl.org. Takes about 1 min

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
