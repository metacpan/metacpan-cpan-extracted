package # hide from PAUSE
App::DBBrowser::Credentials;

use warnings;
use strict;
use 5.008003;
no warnings 'utf8';

use Term::Form qw();


sub new {
    my ( $class, $opt ) = @_;
    bless $opt, $class;
}


sub get_login {
    my ( $sf, $key, $info ) = @_;
    if ( ! $sf->{parameter}{required}{$key} ) {
        return;
    }
    my $env_var = 'DBI_' . uc $key;
    if ( $sf->{parameter}{use_env_var}{$env_var} && exists $ENV{$env_var} ) {
        return $ENV{$env_var}; #
    }
    elsif ( defined $sf->{parameter}{arguments}{$key} && length $sf->{parameter}{arguments}{$key} ) {
        my $saved_value = $sf->{parameter}{arguments}{$key};
        return $saved_value;
    }
    else {
        my $keep_secret = $sf->{parameter}{secret}{$key};
        my $prompt = ucfirst( $key ) . ':';
        my $trs = Term::Form->new();
        # Readline
        my $new = $trs->readline( $prompt, { no_echo => $keep_secret, info => $info } );
        return $new;
    }
}





1;


__END__
