package BugCli::Completions;

push @BugCli::ISA, __PACKAGE__
  unless grep { $_ eq __PACKAGE__ } @BugCli::ISA;

sub last_bugids { return keys %BugCli::lastbugs; }

sub comp_delete { last_bugids }
sub comp_show   { last_bugids; }
sub comp_fix    { last_bugids; }
sub comp_bugs   { return keys %{ $BugCli::config->{query} }; }

sub comp_config {
    my ( $self, $param ) = @_;
    if ( not $param ) {
        return ( keys %{$BugCli::config}, 'show' );
    }
    elsif ( $param =~ /(.*?)\.(.*)?$/ ) {
        if ( exists $BugCli::config->{$1} ) {
            my ($a) = $2 || ".*";
            my (@res) = map { "$1.$_" }
              grep { /$a/ } ( keys %{ $BugCli::config->{$1} } );
            if ( not @res ) {
                @res = grep { /$a/ } ( keys %{$BugCli::config}, 'show' );
            }
            return @res;
        }
    }
    else {
        return grep { /$param/ } ( keys %{$BugCli::config}, 'show' );
    }
}

1;
