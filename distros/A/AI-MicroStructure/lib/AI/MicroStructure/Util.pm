package AI::MicroStructure::Util;

use strict;
use Cwd;
use Config::Auto;
use Env qw/PWD/;

sub get_cwd {
    my @CWD; if (!-e ".micro") {
        push @CWD, $ENV{HOME}."/data-hub/";
    } else {
        push @CWD, getcwd();
    }
    return @CWD;
}

sub load_config {

    my @CWD = AI::MicroStructure::Util::get_cwd();
    my $config = {};#Config::Auto::parse(".micro", path => @CWD) || {};
    if (-e ".micro" && -e $ENV{HOME}."/.micro") {
        my $c = Config::Auto::parse($ENV{HOME}."/.micro");
        foreach (keys %{$c}) { $config->{$_} ||= $c->{$_}; }
    }
    if($config->{default}) {
        shift @CWD;
        push @CWD, $config->{default};
        if (-e "$CWD[0]/.micro") {
            my $c = Config::Auto::parse("$CWD[0]/.micro");
            foreach (keys %{$config}) { $c->{$_} ||= $config->{$_}; }
            $config = $c;
        }
    }
    my $structdir = "structures";
    my $path = {
      "structures" => $structdir,
      "cwd/structures" => "$CWD[0]/$structdir",
    };

    return { "cwd" => @CWD, "path" => $path, "cfg" => $config };

}


sub config {

    my $state = AI::MicroStructure::Util::load_config(); my @CWD = $state->{cwd};
    $state->{cfg}->{query}      ||= "micro";
    $state->{cfg}->{tempdir}    ||= "/tmp/micro-temp/";
    $state->{cfg}->{couchdb}    ||= "http://localhost:5984/";
    $state->{cfg}->{conceptimg} ||= "http://qunatup.com/tiny/concept2.php";
    $state->{cfg}->{wikipedia}  ||= "http://en.wikipedia.org/wiki/";
    $state->{cfg}->{db}         ||= "table";
    $state->{cfg}->{out}        ||= "json";
    $state->{cfg}->{jsonout}      = sprintf("%s/%s/",
                                            $state->{cwd},
                                            $state->{cfg}->{db});





    return $state;
}
1;
