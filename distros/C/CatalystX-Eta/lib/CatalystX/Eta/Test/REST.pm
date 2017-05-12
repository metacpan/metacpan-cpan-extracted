package CatalystX::Eta::Test::REST;

use base qw(Stash::REST);
use strict;

CatalystX::Eta::Test::REST->add_trigger( 'process_response' => \&on_process_response );

use Test::More;

sub on_process_response {
    my ( $self, $opt ) = @_;

    my $req = $opt->{req};

    my $desc = join ' ', $req->method, $req->uri->path,
      '-> ' . $opt->{conf}->{code} . ( $opt->{conf}{is_fail} ? ' is fail' : '' );

    is(
        $opt->{res}->code,
        $opt->{conf}->{code},
        $desc . ( exists $opt->{conf}->{name} ? ' - ' . $opt->{conf}->{name} : '' )
    );

    if ( $opt->{res}->code != $opt->{conf}->{code} ) {
        eval('use DDP; my $x= $opt->{res}; p $x ');
    }
}

1;
