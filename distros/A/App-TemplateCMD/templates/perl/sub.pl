[% IF not vars %][% vars = [ 'var1', 'var2' ] %][% END -%]
[% IF not sub %][% sub = 'sub' %][% END -%]
[% INCLUDE perl/pod.pl -%]

sub [% sub %] {
	my ( [% FOREACH var = vars %]$[% var %], [% END %] ) = @_;

}
