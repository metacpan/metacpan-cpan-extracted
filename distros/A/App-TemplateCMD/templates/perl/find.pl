[% IF not vars %][% vars = [ 'search' ] %][% END -%]
[% IF not sub %][% sub = 'find_files' %][% END -%]
[% INCLUDE perl/pod.pl vars => [ 'dir', vars ]-%]

sub [% sub %] {
	my ( $dir, [% FOREACH var = vars %]$[% var %], [% END %] ) = @_;

	opendir DIR, $dir or warn "Unable to open the directory $dir: $!\n" and return;
	my @files = readdir DIR;
	close DIR;

	foreach my $file ( @files ) {
		next if $file =~ /^\.\.?$/;	# ignore the directories . and ..
		if ( -d "$dir/$file" ) {

			# recurse to sub directories
			find_files( "$$dir/$file", [% FOREACH var = vars %]$[% var %], [% END %] );
		}
		else {

			# process the file
			;
		}
	}
	return ;
}
