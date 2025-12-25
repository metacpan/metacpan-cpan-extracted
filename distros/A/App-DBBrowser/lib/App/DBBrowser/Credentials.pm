package # hide from PAUSE
App::DBBrowser::Credentials;

use warnings;
use strict;
use 5.016;

use Term::Form::ReadLine qw();


sub new {
    my ( $class, $info, $options ) = @_;
    my $sf = {
        i => $info,
        o => $options,
    };
    bless $sf, $class;
}


sub get_login {
    my ( $sf, $key, $show_sofar ) = @_;
    if ( ! $sf->{o}{connect_data}{"${key}_required"} ) {
        return;
    }
    my $env_var = 'DBI_' . uc $key;
    if ( length $sf->{o}{connect_data}{$key} ) {
        return $sf->{o}{connect_data}{$key};
    }
    elsif ( $sf->{o}{connect_data}{"use_dbi_$key"} && exists $ENV{$env_var} ) {
        return $ENV{$env_var}; #
    }
    else {
        my $no_echo = $key =~ /^(?:host|port|user)\z/ ? 0 : 1;
        my $prompt = ucfirst( $key ) . ': ';
        my $tr = Term::Form::ReadLine->new( $sf->{i}{tr_default} );
        # Readline
        my $new = $tr->readline(
            $prompt,
            { info => $show_sofar, no_echo => $no_echo, history => [] }
        );
        return $new;
    }
}




1;


__END__
