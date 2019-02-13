package Data::Tabulate::Plugin::Test;

use warnings;
use strict;

use Data::Dumper

# ABSTRACT: Test plugin for Data::Tabulate

our $VERSION = '0.01';

sub new{
    return bless {},shift;
}

sub remove_var1 {
    my ($self, $bool) = @_;

    $self->{remove_var1} = $bool if @_ > 1;
    return $self->{remove_var1};
}

sub output {
    my ($self,@data) = @_;
    
    my $dump = Dumper( \@data );

    if ( $self->{remove_var1} ) {
        $dump =~ s{\$VAR1 \s* = \s*}{}x;
        $dump =~ s{^\s{8}}{}xmsg;
    }

    return $dump;
}

1; # End of Data::Tabulate::Plugin::Test
