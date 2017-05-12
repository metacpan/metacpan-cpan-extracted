package MyApp::Plugin::Greeting;

use strict;

sub greeting {

    my $self = shift;
    my $greeting;
    my($hour) = (localtime time)[2];
    if($hour >= 5 && $hour <= 11){
        $greeting = "good morning";
    }elsif($hour >= 12 && $hour <= 18){
        $greeting = "hello";
    }elsif($hour >= 19 && $hour <= 23){
        $greeting= "good evening";
    }else{
        $greeting = "good night";
    }
    return $greeting;
}
1;
