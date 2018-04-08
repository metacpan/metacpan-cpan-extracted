package App::Env::Site1::App1;

use strict;
use warnings;

# track the number of times this is invoked
my $cnt = 0;

sub envs
{
    my ( $opt ) = @_;

    $cnt++;

    warn( "Site1 App1 $cnt\n" ) if $ENV{APP_ENV_DEBUG};
    return { %ENV,
             Site1_App1 => $cnt,
             Site1_App1_v1 => $cnt,
             %{$opt} };
}

sub reset
{
    $cnt = 0;
}

1;
