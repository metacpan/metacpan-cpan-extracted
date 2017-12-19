[% IF not vars %][% vars = [ 'var1', 'var2' ] %][% END -%]
[% IF not sub %][% sub = 'class_method' %][% END -%]
[% INCLUDE perl/pod.pl -%]

sub [% sub %] {
	my $caller = shift;
	my $class = (ref $caller) ? ref $caller : $caller;
	my ( [% FOREACH var = vars %]$[% var %], [% END %] ) = @_;

}
