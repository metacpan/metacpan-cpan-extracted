package My::DemoNoUsage::Command::A;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

sub option_spec {
    (
        [ "opt1=s"   => "one" ],
        [ "opt2=s"   => "two" ],
    )
}

sub run {
    return "running command '" . $_[0]->name . "'\n";
}

#-------
1;

__END__

=pod

=head1 NAME

My::DemoNoUsage::Command::A - Test the case where no usage_text() is provided by the CLIF Command class.

=cut
