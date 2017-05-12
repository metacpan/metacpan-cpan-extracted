package CommitBit::Dispatcher;
use Jifty::Dispatcher -base;


# Log out
before 'logout' => run {
    Jifty->web->new_action(
        class   => 'Logout',
        moniker => 'logout',
    )->run;
};
before '*' => run {
        Jifty->web->navigation->child(
                 Home => # override the jifty default. ew

                label => _('Home'),
            url        => '/',
            sort_order => 1);


    if ( Jifty->web->current_user->id ) {
        Jifty->web->navigation->child(
            prefs     =>
                label => _('Preferences'),
            url        => '/prefs',
            sort_order => 998
        );
        Jifty->web->navigation->child(
            logout    =>
                label => _('Logout'),
            url        => '/logout',
            sort_order => 999
        );
    } else {
        Jifty->web->navigation->child(
            login     =>
                label => _('Login'),
            url        => '/login',
            sort_order => 999
        );
    }

    if (    Jifty->web->current_user->user_object
        and Jifty->web->current_user->user_object->admin )
    {
        Jifty->web->navigation->child(
            admin     =>
                label => _('Admin'),
            url => '/admin'
        );
    }

};

before qr'/admin/|/prefs' => run {
    unless (Jifty->web->current_user->id) {
            tangent '/login';
    }
};

# Sign up for an account
on 'signup' => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Signup',
	    moniker => 'signupbox'
	);

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

on 'prefs' => run {
    set 'action' =>
        Jifty->web->new_action(
	    class => 'UpdateUser',
	    moniker => 'prefsbox',
        record => Jifty->web->current_user->user_object
	);

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

# Login
on 'login' => run {
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Login',
	    moniker => 'loginbox'
	);
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};

## LetMes
before qr'^/let/(.*)' => run {
    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;

    Jifty->web->temporary_current_user($let_me->validated_current_user);

    my %args = %{$let_me->args};
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on qr'^/let/' => run {
    my $let_me = get 'let_me';
    show '/let/' . $let_me->path;
};


before qr'^/admin' => run {
    my $admin =   Jifty->web->navigation->child('admin') || Jifty->web->navigation->child( admin => label => _('Admin'), url => '/admin');
    if (Jifty->web->current_user->user_object->admin ) {
        $admin->child( 'repos' => label => 'Repositories', url => '/admin/repositories');
    }
     $admin->child( 'proj' => label => 'Projects', url => '/admin/projects');


};

before qr'^/admin/repository' => run {
    unless  (Jifty->web->current_user->user_object->admin ) {
        redirect '/__jifty/error/permission_denied/not_admin'; 
    }

};

before qr'^/admin/project/([^/]+)(/.*|)$' => run  {
    my $admin =   Jifty->web->navigation->child('admin')->child('proj');
    my $proj = $admin->child( $1 => label => $1, url => '/admin/project/'.$1.'/index.html');
    $proj->child( base => label => _('Overview'), url => '/admin/project/'.$1.'/index.html'); 
    $proj->child( people => label => _('People'), url => '/admin/project/'.$1.'/people'); 
};

on qr'^/admin/repository/([^/]+)(/.*|)$' => run {
    my $name    = $1;
    my $path    = $2||'index.html';
    $name = URI::Escape::uri_unescape($name);
    warn "Name - $name - $path";
    my $repository = CommitBit::Model::Repository->new();
    $repository->load_by_cols( name => $name );
    unless ($repository->id) {
        redirect '/__jifty/error/repository/not_found';
    }

    my $admin =   Jifty->web->navigation->child('admin')->child('repos');
    $radmin =   $admin->child($repository->name => url => '/admin/repository/'.$name.'/index.html');
    $radmin->child( $repository->name => label => 'Overview', url => '/admin/repository/'.$name.'/index.html');
    $radmin->child( $repository->name."projects" => label => 'Projects', url => '/admin/repository/'.$name.'/projects');
    set repository => $repository;
    show "/admin/repository/$path";
};



on qr'^/(.*?/)?project/([^/]+)(/.*|)$' => run {
    my $prefix = $1 ||'';
    my $name    = $2;
    my $path    = $3;
    warn "Got to $1 $2 $3";


    unless (lc($prefix) eq 'admin') {
        Jifty->web->navigation->child(admin => label => _('Admin project'), url =>  '/admin/project/'.$name, order => 5);
    }

    $name = URI::Escape::uri_unescape($name);
    my $project = CommitBit::Model::Project->new();
    $project->load_by_cols( name => $name );
    unless ($project->id) {
        redirect '/__jifty/error/project/not_found';
    }

    if (lc($prefix) eq 'admin') {
    unless  ($project->is_project_admin(Jifty->web->current_user)
             or Jifty->web->current_user->user_object->admin) {
        redirect '/__jifty/error/permission_denied/not_admin'; 
    }
    }

    set project => $project;
    my $url = $prefix . ($path ? '/project/' . $path : '/project/index.html' );

    show $url;
};

1;
