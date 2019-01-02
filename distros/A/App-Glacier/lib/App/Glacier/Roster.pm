package App::Glacier::Roster;
use parent 'App::Glacier::DB';

sub foreach {
    my ($self, $fun) = @_;
    $self->SUPER::foreach(sub {
	my ($key, $descr) = @_;
	(my $vault = $descr->{VaultARN}) =~ s{.*:vaults/}{};
	&{$fun}($key, $descr, $vault);
    });
}	

1;
