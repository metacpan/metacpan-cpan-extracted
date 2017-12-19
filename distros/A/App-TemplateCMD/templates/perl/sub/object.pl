[% IF not vars %][% vars = [ 'var1', 'var2' ] %][% END -%]
[% IF not sub %][% sub = 'method' %][% END -%]
[% INCLUDE perl/pod.pl -%]

sub [% sub %] {
	my ( $self, %args ) = @_;
	my ( [% FOREACH var = vars %]$[% var %], [% END %] ) = @_;
	#my $dbh  = $self->{dbh};
	#my $q    = $self->{cgi};
	#my $set  = $self->{set};

}
