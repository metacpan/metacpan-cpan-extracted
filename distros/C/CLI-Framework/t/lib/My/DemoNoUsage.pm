package My::DemoNoUsage;
use base qw( CLI::Framework );

use lib 'lib';
use lib 't/lib';

use strict;
use warnings;

sub option_spec {
    (
        [ "arg1|o=s" => "arg1" ],
        [ ],
        [ "arg2|t=s" => "arg2" ]
    )
}

sub command_map {
    tree    => 'CLI::Framework::Command::Tree',
    a       => 'My::DemoNoUsage::Command::A',
}

#-------
1;

__END__

=pod

=head1 NAME

My::DemoNoUsage - Test the case where no usage_text() is provided by the CLIF Application class.

=cut
