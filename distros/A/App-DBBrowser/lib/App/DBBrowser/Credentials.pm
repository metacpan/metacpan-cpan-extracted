package # hide from PAUSE
App::DBBrowser::Credentials;

use warnings;
use strict;
use 5.010001;

use Term::Form qw();


sub new {
    my ( $class, $info, $options ) = @_;
    my $sf = {
        i => $info,
        o => $options,
    };
    bless $sf, $class;
}


sub get_login {
    my ( $sf, $key, $show_sofar, $settings ) = @_;
    if ( ! exists $settings->{login_data}{$key} ) {
        return;
    }
    my $default = $settings->{login_data}{$key}{default};
    my $no_echo = $settings->{login_data}{$key}{secret};
    my $env_var = 'DBI_' . uc $key;
    if ( $settings->{env_var_yes}{$env_var} && exists $ENV{$env_var} ) {
        return $ENV{$env_var}; #
    }
    elsif ( defined $default && length $default ) {
        return $default;
    }
    else {
        my $prompt = ucfirst( $key ) . ': ';
        my $tf = Term::Form->new( $sf->{i}{tf_default} );
        # Readline
        my $new = $tf->readline( $prompt,
            { info => $show_sofar, no_echo => $no_echo }
        );
        return $new;
    }
}



1;


__END__
