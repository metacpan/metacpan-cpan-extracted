package MyTestApp;

use Dancer2;
use Dancer2::Plugin::TemplateFlute;

get '/' => sub {
    # this is the 1st request made during tests so make sure session is
    # created so that a session cooke is returned that the test can then
    # apply to all subsequent sessions.
    session foo => 'bar';
    template 'index';
};

any [qw/get post/] => '/register' => sub {
    my $form = form('registration');
    my %values = %{$form->values};
    # VALIDATE, filter, etc. the values
    $form->fill(\%values);
    template register => {form => $form };
};

any [qw/get post/] => '/login' => sub {
    # select the form to fill. Only one supported for now.
    my $form;
    if (params->{login}) {
        $form = form('login');
    }
    else {
        $form = form('registration');
    }
    $form->fill($form->values);
    template login => { form => $form } ;
};

any [qw/get post/] => '/bugged_single' => sub {
    template register => {};
};

any [qw/get post/] => '/bugged_multiple' => sub {
    template login => {};
};

any [qw/get post/] => '/multiple' => sub {
    my $login;
    debug "params: ", to_dumper({params}) if request->is_post;
    if (params->{login}) {
        $login = form('logintest', source => 'body');
    }
    else {
        $login = form('logintest', source => 'session');
    }
    my $registration;
    if (params->{register}) {
        $registration = form('registrationtest', source => 'body');
    }
    else {
        $registration = form('registrationtest', source => 'session');
    }
    template multiple => { form => [ $login, $registration ] };
};

any [qw/post get/] => '/checkout' => sub {
    my (@days, @years);
    for (1..31) {
        push @days, { value => $_, label => "Day $_" };
    }
    for (2012..2020) {
        push @years, { value => $_, label => "Year $_" };
    }
    my $form;
    if (params->{submit}) {
        $form = form('giftinfo', source => 'body' );
    }
    else {
        $form = form('giftinfo', source => 'session' );
    }

    my $detform;
    if (params->{submit_details}) {
        $detform = form('giftdetails', source => 'body' );
    }
    else {
        $detform = form('giftdetails', source => 'session' );
    }

    template 'checkout-giftinfo' => {
                                     form => [ $form, $detform ],
                                     days => \@days,
                                     years => \@years
                                    };
};

get '/iter' => sub {
    template dropdown => {
                          my_wishlists_dropdown => iterator()
                         };
};

any [qw/get post/] => '/double-dropdown' => sub {
    my $form = form('account_edit');
    my %values = %{$form->values};
    # VALIDATE, filter, etc. the values
    $form->fill(\%values);

    template double => {
                        'roles' => [
                                    {
                                     'value' => '1'
                                    },
                                    {
                                     'value' => '2'
                                    },
                                    {
                                     'value' => '3'
                                    },
                                    {
                                     'value' => '4'
                                    } 
                                   ],
                        form => $form,
                       };
};

any [qw/get post/] => '/double-dropdown-noform' => sub {
    template double => {
                        'roles' => [
                                    {
                                     'value' => '1'
                                    },
                                    {
                                     'value' => '2'
                                    },
                                    {
                                     'value' => '3'
                                    },
                                    {
                                     'value' => '4'
                                    } 
                                   ],
                       };
};

get '/ampersand' => sub {
    my @countries = ({name => 'Trinidad&Tobago'});

    template 'ampersand', {countries => \@countries};
};

sub iterator {
    return [{ label => "a",
              value => "b" },
            { label => "c",
              value => "d" }]
}


1;

