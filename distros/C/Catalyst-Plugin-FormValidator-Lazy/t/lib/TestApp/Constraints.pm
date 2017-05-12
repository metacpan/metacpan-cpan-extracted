package TestApp::Constraints;

sub strict_kyoto {
    my $value = shift;
    return $value =~ /^kinkakuji$/ ? 1 : 0 ;
}


sub loose_kyoto {
    my $value = shift;
    return $value =~ /^kin/ ? 1 : 0 ;
}

sub static_nyan {
    my $value = shift;
    my $num1  = shift;
    my $num2  = shift;

    my $answer = $value * $num1 * $num2;
    return ( $answer == 2 * 3 * 10 ) ? 1 : 0;
}

sub static_won {
    my $value = shift;
    return $value eq 'won' ? 1  : 0 ; 
}

1;
