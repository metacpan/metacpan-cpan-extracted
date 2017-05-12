package App::I18N::Command;
use warnings;
use strict;
use base qw(App::CLI App::CLI::Command);

sub options {
    return (
        'h|help|?' => 'help',
        'man' => 'man',
    );
}

sub alias {
    (
        "s" => "server",
        "p" => "parse",
        "l" => "lang",
        "export" => 'gen',
    );
}

sub invoke {
    my ($pkg, $cmd, @args) = @_;
    local *ARGV = [$cmd, @args];
    my $ret = eval {
        $pkg->dispatch();
    };
    if( $@ ) {
        warn $@;
    }
}

sub prompt {
    my ( $self, $msg, $default ) = @_;
    $default ||= "Y";

    print STDERR $msg;
    my $ans = <STDIN>;
    chomp($ans);
    $ans =~ s{[\r\n]}{}g;

    $ans ||= $default;

    return $ans;
}


sub logger {
    return App::I18N->logger();
}

1;
