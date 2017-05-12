use CatalystX::Declare;

model MyApp::Web::Model::Calc {

    method op (Str $op) {

        if ($op eq 'add') { 
            return sub {
                my $num = shift;
                $num += $_
                    for @_;
                return $num;
            };
        }
        elsif ($op eq 'multiply') {
            return sub {
                my $num = shift;
                $num *= $_
                    for @_;
                return $num;
            };
        }
        else {
            return sub { 'unknown operator' };
        }
    }
}
