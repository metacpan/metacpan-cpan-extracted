package CGI::Ex::Auth;

=head1 NAME

CGI::Ex::Auth - Handle logins nicely.

=cut

###----------------------------------------------------------------###
#  Copyright 2004-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use strict;
use vars qw($VERSION);

use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::MD5 qw(md5_hex);
use CGI::Ex;
use Carp qw(croak);

$VERSION = '2.44';

###----------------------------------------------------------------###

sub new {
    my $class = shift || croak "Usage: ".__PACKAGE__."->new";
    my $self  = ref($_[0]) ? shift() : (@_ % 2) ? {} : {@_};
    return bless {%$self}, $class;
}

sub get_valid_auth {
    my $self = shift;
    $self = $self->new(@_) if ! ref $self;
    delete $self->{'_last_auth_data'};

    # shortcut that will print a js file as needed (such as the md5.js)
    if ($self->script_name . $self->path_info eq $self->js_uri_path . "/CGI/Ex/md5.js") {
        $self->cgix->print_js('CGI/Ex/md5.js');
        eval { die "Printed Javascript" };
        return;
    }

    my $form = $self->form;

    # allow for logout
    if ($form->{$self->key_logout} && ! $self->{'_logout_looking_for_user'}) {
        local $self->{'_logout_looking_for_user'} = 1;
        local $self->{'no_set_cookie'}    = 1;
        local $self->{'no_cookie_verify'} = 1;
        $self->check_valid_auth; # verify the logout so we can capture the username if possible

        $self->logout_hook;

        if ($self->bounce_on_logout) {
            my $key_c = $self->key_cookie;
            $self->delete_cookie({key => $key_c}) if $self->cookies->{$key_c};
            my $user = $self->last_auth_data ? $self->last_auth_data->{'user'} : undef;
            $self->location_bounce($self->logout_redirect(defined($user) ? $user : ''));
            eval { die "Logging out" };
            return;
        } else {
            $self->form({});
            $self->handle_failure;
            return;
        }
    }

    my $data;

    # look in form first
    my $form_user = delete $form->{$self->key_user};
    if (defined $form_user) {
        if (delete $form->{$self->key_loggedout}) { # don't validate the form on a logout
            $data = $self->new_auth_data({user => $form_user, error => 'Logged out'});
        } elsif (defined $form->{ $self->key_pass }) {
            $data = $self->verify_token({
                token => {
                    user        => $form_user,
                    test_pass   => delete $form->{ $self->key_pass },
                    expires_min => delete($form->{ $self->key_save }) ? -1 : delete($form->{ $self->key_expires_min }) || undef,
                },
                from => 'form',
            });
        } elsif (! length $form_user) {
            $data = $self->new_auth_data({user => '', error => 'Invalid user'});
        } else {
            $data = $self->verify_token({token => $form_user, from => 'form'});
        }
    }

    # no valid form data ? look in the cookie
    if (! ref($data)  # no form
        || ($data->error && $data->{'allow_cookie_match'})) { # had form with error - but we can check if form user matches existing cookie
        my $cookie = $self->cookies->{$self->key_cookie};
        if (defined($cookie) && length($cookie)) {
            my $form_data = $data;
            $data = $self->verify_token({token => $cookie, from => 'cookie'});
            if (defined $form_user) { # they had form data
                my $user = $self->cleanup_user($form_user);
                if (! $data || !$self->check_form_user_against_cookie($user, $data->{'user'}, $data)) { # but the cookie didn't match
                    $data = $self->{'_last_auth_data'} = $form_data; # restore old form data failure
                    $data->{'user'} = $user if ! defined $data->{'user'};
                }
            }
        }
    }

    # failure
    if (! $data) {
        return $self->handle_failure({had_form_data => defined($form_user)});
    }

    # success
    my $_key = $self->key_cookie;
    my $_val = $self->generate_token($data);
    my $use_session = $self->use_session_cookie($_key, $_val); # default false
    if ($self->use_plaintext || ($data->{'type'} && $data->{'type'} eq 'crypt')) {
        $use_session = 1 if ! defined($use_session) && ! defined($data->{'expires_min'});
    }
    $self->set_cookie({
        name    => $_key,
        value   => $_val,
        expires => ($use_session ? '' : '+20y'), # non-cram cookie types are session cookies unless save was set (thus setting expires_min)
    });

    return $self->handle_success({is_form => ($data->{'from'} eq 'form' ? 1 : 0)});
}

sub handle_success {
    my $self = shift;
    my $args = shift || {};
    if (my $meth = $self->{'handle_success'}) {
        return $meth->($self, $args);
    }
    my $form = $self->form;

    # bounce to redirect
    if (my $redirect = $form->{ $self->key_redirect }) {
        $self->location_bounce($redirect);
        eval { die "Success login - bouncing to redirect" };
        return;

    # if they have cookies we are done
    } elsif (scalar(keys %{$self->cookies}) || $self->no_cookie_verify) {
        $self->success_hook;
        return $self;

    # need to verify cookies are set-able
    } elsif ($args->{'is_form'}) {
        $form->{$self->key_verify} = $self->server_time;
        my $url = $self->script_name . $self->path_info . "?". $self->cgix->make_form($form);

        $self->location_bounce($url);
        eval { die "Success login - bouncing to test cookie" };
        return;
    }
}

sub success_hook {
    my $self = shift;
    if (my $meth = $self->{'success_hook'}) {
        return $meth->($self);
    }
    return;
}

sub logout_hook {
    my $self = shift;
    if (my $meth = $self->{'logout_hook'}) {
        return $meth->($self);
    }
    return;
}

sub handle_failure {
    my $self = shift;
    my $args = shift || {};
    if (my $meth = $self->{'handle_failure'}) {
        return $meth->($self, $args);
    }
    my $form = $self->form;

    # make sure the cookie is gone
    my $key_c = $self->key_cookie;
    $self->delete_cookie({name => $key_c}) if exists $self->cookies->{$key_c};

    # no valid login and we are checking for cookies - see if they have cookies
    if (my $value = delete $form->{$self->key_verify}) {
        if (abs(time() - $value) < 15) {
            $self->no_cookies_print;
            return;
        }
    }

    # oh - you're still here - well then - ask for login credentials
    my $key_r = $self->key_redirect;
    local $form->{$key_r} = $form->{$key_r} || $self->script_name . $self->path_info . (scalar(keys %$form) ? "?".$self->cgix->make_form($form) : '');
    local $form->{'had_form_data'} = $args->{'had_form_data'} || 0;
    $self->login_print;
    my $data = $self->last_auth_data;
    eval { die defined($data) ? $data : "Requesting credentials" };

    # allow for a sleep to help prevent brute force
    sleep($self->failed_sleep) if defined($data) && $data->error ne 'Login expired' && $self->failed_sleep;
    $self->failure_hook;

    return;
}

sub failure_hook {
    my $self = shift;
    if (my $meth = $self->{'failure_hook'}) {
        return $meth->($self);
    }
    return;
}

sub check_valid_auth {
    my $self = shift;
    $self = $self->new(@_) if ! ref $self;

    local $self->{'location_bounce'} = sub {}; # but don't bounce to other locations
    local $self->{'login_print'}     = sub {}; # check only - don't login if not
    local $self->{'set_cookie'}      = $self->{'no_set_cookie'} ? sub {} : $self->{'set_cookie'};
    return $self->get_valid_auth;
}

###----------------------------------------------------------------###

sub script_name { shift->{'script_name'} || $ENV{'SCRIPT_NAME'} || '' }

sub path_info { shift->{'path_info'} || $ENV{'PATH_INFO'} || '' }

sub server_time { time }

sub cgix {
    my $self = shift;
    $self->{'cgix'} = shift if @_ == 1;
    return $self->{'cgix'} ||= CGI::Ex->new;
}

sub form {
    my $self = shift;
    $self->{'form'} = shift if @_ == 1;
    return $self->{'form'} ||= $self->cgix->get_form;
}

sub cookies {
    my $self = shift;
    $self->{'cookies'} = shift if @_ == 1;
    return $self->{'cookies'} ||= $self->cgix->get_cookies;
}

sub delete_cookie {
    my $self = shift;
    my $args = shift;
    return $self->{'delete_cookie'}->($self, $args) if $self->{'delete_cookie'};
    local $args->{'value'}   = '';
    local $args->{'expires'} = '-10y';
    if (my $dom = $ENV{HTTP_HOST}) {
        $dom =~ s/:\d+$//;
        do {
            local $args->{'domain'} = $dom;
            $self->set_cookie($args);
            local $args->{'domain'} = ".$dom";
            $self->set_cookie($args);
        }
        while ($dom =~ s/^[\w\-]*\.// and $dom =~ /\./);
    }
    $self->set_cookie($args);
    delete $self->cookies->{$args->{'name'}};
}

sub set_cookie {
    my $self = shift;
    my $args = shift;
    return $self->{'set_cookie'}->($self, $args) if $self->{'set_cookie'};
    my $key  = $args->{'name'};
    my $val  = $args->{'value'};
    my $dom  = $args->{'domain'} || $self->cookie_domain;
    my $sec  = $args->{'secure'} || $self->cookie_secure;
    $self->cgix->set_cookie({
        -name    => $key,
        -value   => $val,
        -path    => $args->{'path'} || $self->cookie_path($key, $val) || '/',
        ($dom ? (-domain => $dom) : ()),
        ($sec ? (-secure => $sec) : ()),
        ($args->{'expires'} ? (-expires => $args->{'expires'}): ()),
    });
    $self->cookies->{$key} = $val;
}

sub location_bounce {
    my $self = shift;
    my $url  = shift;
    return $self->{'location_bounce'}->($self, $url) if $self->{'location_bounce'};
    return $self->cgix->location_bounce($url);
}

###----------------------------------------------------------------###

sub key_logout       { shift->{'key_logout'}       ||= 'cea_logout'   }
sub key_cookie       { shift->{'key_cookie'}       ||= 'cea_user'     }
sub key_user         { shift->{'key_user'}         ||= 'cea_user'     }
sub key_pass         { shift->{'key_pass'}         ||= 'cea_pass'     }
sub key_time         { shift->{'key_time'}         ||= 'cea_time'     }
sub key_save         { shift->{'key_save'}         ||= 'cea_save'     }
sub key_expires_min  { shift->{'key_expires_min'}  ||= 'cea_expires_min' }
sub form_name        { shift->{'form_name'}        ||= 'cea_form'     }
sub key_verify       { shift->{'key_verify'}       ||= 'cea_verify'   }
sub key_redirect     { shift->{'key_redirect'}     ||= 'cea_redirect' }
sub key_loggedout    { shift->{'key_loggedout'}    ||= 'loggedout'    }
sub bounce_on_logout { shift->{'bounce_on_logout'} ||= 0              }
sub secure_hash_keys { shift->{'secure_hash_keys'} ||= []             }
#perl -e 'use Digest::MD5 qw(md5_hex); open(my $fh, "<", "/dev/urandom"); for (1..10) { read $fh, my $t, 5_000_000; print md5_hex($t),"\n"}'
sub no_cookie_verify { shift->{'no_cookie_verify'} ||= 0              }
sub use_crypt        { shift->{'use_crypt'}        ||= 0              }
sub use_blowfish     { shift->{'use_blowfish'}     ||= ''             }
sub use_plaintext    { my $s = shift; $s->use_crypt || ($s->{'use_plaintext'} ||= 0) }
sub use_base64       { my $s = shift; $s->{'use_base64'}  = 1      if ! defined $s->{'use_base64'};  $s->{'use_base64'}  }
sub expires_min      { my $s = shift; $s->{'expires_min'} = 6 * 60 if ! defined $s->{'expires_min'}; $s->{'expires_min'} }
sub failed_sleep     { shift->{'failed_sleep'}     ||= 0              }
sub cookie_path      { shift->{'cookie_path'}      }
sub cookie_domain    { shift->{'cookie_domain'}    }
sub cookie_secure    { shift->{'cookie_secure'}    }
sub use_session_cookie { shift->{'use_session_cookie'} }
sub disable_simple_cram { shift->{'disable_simple_cram'} }
sub complex_plaintext { shift->{'complex_plaintext'} }

sub logout_redirect {
    my ($self, $user) = @_;
    my $form = $self->cgix->make_form({$self->key_loggedout => 1, (length($user) ? ($self->key_user => $user) : ()) });
    return $self->{'logout_redirect'} || $self->script_name ."?$form";
}

sub js_uri_path {
    my $self = shift;
    return $self->{'js_uri_path'} ||= $self->script_name ."/js";
}

###----------------------------------------------------------------###

sub no_cookies_print {
    my $self = shift;
    return $self->{'no_cookies_print'}->($self) if $self->{'no_cookies_print'};
    $self->cgix->print_content_type;
    print qq{<div style="border: 2px solid black;background:red;color:white">You do not appear to have cookies enabled.</div>};
}

sub login_print {
    my $self = shift;
    my $hash = $self->login_hash_common;
    my $file = $self->login_template;

    ### allow for a hooked override
    if (my $meth = $self->{'login_print'}) {
        $meth->($self, $file, $hash);
        return 0;
    }

    ### process the document
    my $args = $self->template_args;
    $args->{'INCLUDE_PATH'} ||= $args->{'include_path'} || $self->template_include_path,
    my $t = $self->template_obj($args);
    my $out = '';
    $t->process_simple($file, $hash, \$out) || die $t->error;

    ### fill in form fields
    require CGI::Ex::Fill;
    CGI::Ex::Fill::fill({text => \$out, form => $hash});

    ### print it
    $self->cgix->print_content_type;
    print $out;

    return 0;
}

sub template_obj {
    my ($self, $args) = @_;
    return $self->{'template_obj'} || do {
        require Template::Alloy;
        Template::Alloy->new($args);
    };
}

sub template_args { $_[0]->{'template_args'} ||= {} }

sub template_include_path { $_[0]->{'template_include_path'} || '' }

sub login_hash_common {
    my $self = shift;
    my $form = $self->form;
    my $data = $self->last_auth_data;
    $data = {no_data => 1} if ! ref $data;

    return {
        %$form,
        error              => ($form->{'had_form_data'}) ? "Login Failed" : "",
        login_data         => $data,
        key_user           => $self->key_user,
        key_pass           => $self->key_pass,
        key_time           => $self->key_time,
        key_save           => $self->key_save,
        key_expires_min    => $self->key_expires_min,
        key_redirect       => $self->key_redirect,
        form_name          => $self->form_name,
        script_name        => $self->script_name,
        path_info          => $self->path_info,
        md5_js_path        => $self->js_uri_path ."/CGI/Ex/md5.js",
        $self->key_user    => $data->{'user'} || '',
        $self->key_pass    => '', # don't allow for this to get filled into the form
        $self->key_time    => $self->server_time,
        $self->key_expires_min => $self->expires_min,
        text_user          => $self->text_user,
        text_pass          => $self->text_pass,
        text_save          => $self->text_save,
        text_submit        => $self->text_submit,
        hide_save          => $self->hide_save,
    };
}

###----------------------------------------------------------------###

sub verify_token {
    my $self  = shift;
    my $args  = shift;
    if (my $meth = $self->{'verify_token'}) {
        return $meth->($self, $args);
    }
    my $token = delete $args->{'token'}; die "Missing token" if ! length $token;
    my $data  = $self->new_auth_data({token => $token, %$args});
    my $meth;

    # make sure the token is parsed to usable data
    if (ref $token) { # token already parsed
        $data->add_data({%$token, armor => 'none'});

    } elsif (my $meth = $self->{'parse_token'}) {
        if (! $meth->($self, $args)) {
            $data->error('Invalid custom parsed token') if ! $data->error; # add error if not already added
            $data->{'allow_cookie_match'} = 1;
            return $data;
        }
    } else {
        if (! $self->parse_token($token, $data)) {
            $data->error('Invalid token') if ! $data->error; # add error if not already added
            $data->{'allow_cookie_match'} = 1;
            return $data;
        }
    }


    # verify the user
    if (! defined($data->{'user'})) {
        $data->error('Missing user');
    } elsif (! defined($data->{'user'} = $self->cleanup_user($data->{'user'}))
             || ! length($data->{'user'})) {
        $data->error('Missing cleaned user');
    } elsif (! defined $data->{'test_pass'}) {
        $data->error('Missing test_pass');
    } elsif (! $self->verify_user($data->{'user'})) {
        $data->error('Invalid user');
    }
    return $data if $data->error;

    # get the pass
    my $pass;
    if (! defined($pass = eval { $self->get_pass_by_user($data->{'user'}) })) {
        $data->add_data({details => $@});
        $data->error('Could not get pass');
    } elsif (ref $pass eq 'HASH') {
        my $extra = $pass;
        $pass = exists($extra->{'real_pass'}) ? delete($extra->{'real_pass'})
              : exists($extra->{'password'})  ? delete($extra->{'password'})
              : do { $data->error('Data returned by get_pass_by_user did not contain real_pass or password'); undef };
        $data->error('Invalid login') if ! defined $pass && ! $data->error;
        $data->add_data($extra);
    }
    return $data if $data->error;
    $data->add_data({real_pass => $pass}); # store - to allow generate_token to not need to relookup the pass


    # validate the pass
    if ($meth = $self->{'verify_password'}) {
        if (! $meth->($self, $pass, $data)) {
            $data->error('Password failed verification') if ! $data->error;
        }
    } else{
        if (! $self->verify_password($pass, $data)) {
            $data->error('Password failed verification') if ! $data->error;
        }
    }
    return $data if $data->error;


    # validate the payload
    if ($meth = $self->{'verify_payload'}) {
        if (! $meth->($self, $data->{'payload'}, $data)) {
            $data->error('Payload failed custom verification') if ! $data->error;
        }
    } else {
        if (! $self->verify_payload($data->{'payload'}, $data)) {
            $data->error('Payload failed verification') if ! $data->error;
        }
    }

    return $data;
}

sub new_auth_data {
    my $self = shift;
    return $self->{'_last_auth_data'} = CGI::Ex::Auth::Data->new(@_);
}

sub parse_token {
    my ($self, $token, $data) = @_;
    my $found;
    my $bkey;
    for my $armor ('none', 'base64', 'blowfish') {
        my $copy = ($armor eq 'none')       ? $token
            : ($armor eq 'base64')          ? $self->use_base64 ? eval { local $^W; decode_base64($token) } : next
            : ($bkey = $self->use_blowfish) ? decrypt_blowfish($token, $bkey)
            : next;
        if ($self->complex_plaintext && $copy =~ m|^ ([^/]+) / (\d+) / (-?\d+) / ([^/]*) / (.*) $|x) {
            $data->add_data({
                user         => $1,
                plain_time   => $2,
                expires_min  => $3,
                payload      => $4,
                test_pass    => $5,
                armor        => $armor,
            });
            $found = 1;
            last;
        } elsif ($copy =~ m|^ ([^/]+) / (\d+) / (-?\d+) / ([^/]*) / ([a-fA-F0-9]{32}) (?: / (sh\.\d+\.\d+))? $|x) {
            $data->add_data({
                user         => $1,
                cram_time    => $2,
                expires_min  => $3,
                payload      => $4,
                test_pass    => $5,
                secure_hash  => $6 || '',
                armor        => $armor,
            });
            $found = 1;
            last;
        } elsif ($copy =~ m|^ ([^/]+) / (.*) $|x) {
            $data->add_data({
                user         => $1,
                test_pass    => $2,
                armor        => $armor,
            });
            $found = 1;
            last;
        }
    }
    return $found;
}

sub verify_password {
    my ($self, $pass, $data) = @_;
    my $err;

    ### looks like a secure_hash cram
    if ($data->{'secure_hash'}) {
        $data->add_data(type => 'secure_hash_cram');
        my $array = eval {$self->secure_hash_keys };
        if (! $array) {
            $err = 'secure_hash_keys not found';
        } elsif (! @$array) {
            $err = 'secure_hash_keys empty';
        } elsif ($data->{'secure_hash'} !~ /^sh\.(\d+)\.(\d+)$/ || $1 > $#$array) {
            $err = 'Invalid secure hash';
        } else {
            my $rand1 = $1;
            my $rand2 = $2;
            my $real  = $pass =~ /^[a-fA-F0-9]{32}$/ ? lc($pass) : md5_hex($pass);
            my $str  = join("/", @{$data}{qw(user cram_time expires_min payload)});
            my $sum = md5_hex($str .'/'. $real .('/sh.'.$array->[$rand1].'.'.$rand2));
            if ($data->{'expires_min'} > 0
                && ($self->server_time - $data->{'cram_time'}) > $data->{'expires_min'} * 60) {
                $err = 'Login expired';
            } elsif (lc($data->{'test_pass'}) ne $sum) {
                $err = 'Invalid login';
            }
        }

    ### looks like a simple_cram
    } elsif ($data->{'cram_time'}) {
        $data->add_data(type => 'simple_cram');
        die "Type simple_cram disabled during verify_password" if $self->disable_simple_cram;
        my $real = $pass =~ /^[a-fA-F0-9]{32}$/ ? lc($pass) : md5_hex($pass);
        my $str  = join("/", @{$data}{qw(user cram_time expires_min payload)});
        my $sum  = md5_hex($str .'/'. $real);
        if ($data->{'expires_min'} > 0
                 && ($self->server_time - $data->{'cram_time'}) > $data->{'expires_min'} * 60) {
            $err = 'Login expired';
        } elsif (lc($data->{'test_pass'}) ne $sum) {
            $err = 'Invalid login';
        }

    ### expiring plain
    } elsif ($data->{'plain_time'}
             && $data->{'expires_min'} > 0
             && ($self->server_time - $data->{'plain_time'}) > $data->{'expires_min'} * 60) {
        $err = 'Login expired';

    ### plaintext_crypt
    } elsif ($pass =~ m|^([./0-9A-Za-z]{2})([./0-9A-Za-z]{11})$|
             && crypt($data->{'test_pass'}, $1) eq $pass) {
        $data->add_data(type => 'crypt', was_plaintext => 1);

    ### failed plaintext crypt
    } elsif ($self->use_crypt) {
        $err = 'Invalid login';
        $data->add_data(type => 'crypt', was_plaintext => ($data->{'test_pass'} =~ /^[a-fA-F0-9]{32}$/ ? 0 : 1));

    ### plaintext and md5
    } else {
        my $is_md5_t = $data->{'test_pass'} =~ /^[a-fA-F0-9]{32}$/;
        my $is_md5_r = $pass =~ /^[a-fA-F0-9]{32}$/;
        my $test = $is_md5_t ? lc($data->{'test_pass'}) : md5_hex($data->{'test_pass'});
        my $real = $is_md5_r ? lc($pass) : md5_hex($pass);
        $data->add_data(type => ($is_md5_r ? 'md5' : 'plaintext'), was_plaintext => ($is_md5_t ? 0 : 1));
        $err = 'Invalid login'
            if $test ne $real;
    }

    $data->error($err) if $err;
    return ! $err;
}

sub last_auth_data { shift->{'_last_auth_data'} }

sub generate_token {
    my $self  = shift;
    my $data  = shift || $self->last_auth_data;
    die "Can't generate a token off of a failed auth" if ! $data;
    die "Can't generate a token for a user which contains a \"/\"" if $data->{'user'} =~ m{/};
    my $token;
    my $exp = defined($data->{'expires_min'}) ? $data->{'expires_min'} : $self->expires_min;

    my $user = $data->{'user'} || die "Missing user";
    my $load = $self->generate_payload($data);
    die "User can not contain a \"/\."                                           if $user =~ m|/|;
    die "Payload can not contain a \"/\.  Please encode it in generate_payload." if $load =~ m|/|;

    ### do kinds that require staying plaintext
    if (   (defined($data->{'use_plaintext'}) ?  $data->{'use_plaintext'} : $self->use_plaintext) # ->use_plaintext is true if ->use_crypt is
        || (defined($data->{'use_crypt'})     && $data->{'use_crypt'})
        || (defined($data->{'type'})          && $data->{'type'} eq 'crypt')) {
        my $pass = defined($data->{'test_pass'}) ? $data->{'test_pass'} : $data->{'real_pass'};
        $token = $self->complex_plaintext ? join('/', $user, $self->server_time, $exp, $load, $pass) : "$user/$pass";

    ### all other types go to cram - secure_hash_cram, simple_cram, plaintext and md5
    } else {
        my $real = defined($data->{'real_pass'}) ? ($data->{'real_pass'} =~ /^[a-fA-F0-9]{32}$/ ? lc($data->{'real_pass'}) : md5_hex($data->{'real_pass'}))
                                                 : die "Missing real_pass";
        my $array;
        if (! $data->{'prefer_simple_cram'}
            && ($array = eval { $self->secure_hash_keys })
            && @$array) {
            my $rand1 = int(rand @$array);
            my $rand2 = int(rand 100000);
            my $str = join("/", $user, $self->server_time, $exp, $load);
            my $sum = md5_hex($str .'/'. $real .('/sh.'.$array->[$rand1].'.'.$rand2));
            $token  = $str .'/'. $sum . '/sh.'.$rand1.'.'.$rand2;
        } else {
            die "Type simple_cram disabled during generate_token" if $self->disable_simple_cram;
            my $str = join("/", $user, $self->server_time, $exp, $load);
            my $sum = md5_hex($str .'/'. $real);
            $token  = $str .'/'. $sum;
        }
    }

    if (my $key = $data->{'use_blowfish'} || $self->use_blowfish) {
        $token = encrypt_blowfish($token, $key);

    } elsif (defined($data->{'use_base64'}) ? $data->{'use_base64'} : $self->use_base64) {
        $token = encode_base64($token, '');
    }

    return $token;
}

sub generate_payload {
    my $self = shift;
    my $args = shift;
    if (my $meth = $self->{'generate_payload'}) {
        return $meth->($self, $args);
    }
    return defined($args->{'payload'}) ? $args->{'payload'} : '';
}

sub verify_user {
    my $self = shift;
    my $user = shift;
    if (my $meth = $self->{'verify_user'}) {
        return $meth->($self, $user);
    }
    return 1;
}

sub cleanup_user {
    my $self = shift;
    my $user = shift;
    if (my $meth = $self->{'cleanup_user'}) {
        return $meth->($self, $user);
    }
    return $user;
}

sub check_form_user_against_cookie {
    my ($self, $form_user, $cookie_user, $data) = @_;
    return if ! defined($form_user) || ! defined($cookie_user);
    return $form_user eq $cookie_user;
}

sub get_pass_by_user {
    my $self = shift;
    my $user = shift;
    if (my $meth = $self->{'get_pass_by_user'}) {
        return $meth->($self, $user);
    }

    die "Please override get_pass_by_user";
}

sub verify_payload {
    my ($self, $payload, $data) = @_;
    if (my $meth = $self->{'verify_payload'}) {
        return $meth->($self, $payload, $data);
    }
    return 1;
}

###----------------------------------------------------------------###

sub encrypt_blowfish {
    my ($str, $key) = @_;

    require Crypt::Blowfish;
    my $cb = Crypt::Blowfish->new($key);

    $str .= (chr 0) x (8 - length($str) % 8); # pad to multiples of 8

    my $enc = '';
    $enc .= unpack "H16", $cb->encrypt($1) while $str =~ /\G(.{8})/g; # 8 bytes at a time

    return $enc;
}

sub decrypt_blowfish {
    my ($enc, $key) = @_;

    require Crypt::Blowfish;
    my $cb = Crypt::Blowfish->new($key);

    my $str = '';
    $str .= $cb->decrypt(pack "H16", $1) while $enc =~ /\G([A-Fa-f0-9]{16})/g;
    $str =~ y/\00//d;

    return $str
}

###----------------------------------------------------------------###

sub login_template {
    my $self = shift;
    return $self->{'login_template'} if $self->{'login_template'};

    my $text = join '',
        map {ref $_ ? $$_ : /\[%/ ? $_ : $_ ? "[% TRY; PROCESS '$_'; CATCH %]<!-- [% error %] -->[% END %]\n" : ''}
        $self->login_header, $self->login_form, $self->login_script, $self->login_footer;
    return \$text;
}

sub login_header { shift->{'login_header'} || 'login_header.tt' }
sub login_footer { shift->{'login_footer'} || 'login_footer.tt' }

sub login_form {
    my $self = shift;
    return $self->{'login_form'} if defined $self->{'login_form'};
    return \q{<div class="login_chunk">
<span class="login_error">[% error %]</span>
<form class="login_form" name="[% form_name %]" method="POST" action="[% script_name %][% path_info %]">
<input type="hidden" name="[% key_redirect %]" value="">
<input type="hidden" name="[% key_time %]" value="">
<input type="hidden" name="[% key_expires_min %]" value="">
<table class="login_table">
<tr class="login_username">
  <td>[% text_user %]</td>
  <td><input name="[% key_user %]" type="text" size="30" value=""></td>
</tr>
<tr class="login_password">
  <td>[% text_pass %]</td>
  <td><input name="[% key_pass %]" type="password" size="30" value=""></td>
</tr>
[% IF ! hide_save ~%]
<tr class="login_save">
  <td colspan="2">
    <input type="checkbox" name="[% key_save %]" value="1"> [% text_save %]
  </td>
</tr>
[%~ END %]
<tr class="login_submit">
  <td colspan="2" align="right">
    <input type="submit" value="[% text_submit %]">
  </td>
</tr>
</table>
</form>
</div>
};
}

sub text_user   { my $self = shift; return defined($self->{'text_user'})   ? $self->{'text_user'}   : 'Username:' }
sub text_pass   { my $self = shift; return defined($self->{'text_pass'})   ? $self->{'text_pass'}   : 'Password:' }
sub text_save   { my $self = shift; return defined($self->{'text_save'})   ? $self->{'text_save'}   : 'Save Password ?' }
sub hide_save   { my $self = shift; return defined($self->{'hide_save'})   ? $self->{'hide_save'}   : 0 }
sub text_submit { my $self = shift; return defined($self->{'text_submit'}) ? $self->{'text_submit'} : 'Login' }

sub login_script {
    my $self = shift;
    return $self->{'login_script'} if defined $self->{'login_script'};
    return '' if $self->use_plaintext || $self->disable_simple_cram;
    return \q{<form name="[% form_name %]_jspost" style="margin:0px" method="POST">
<input type="hidden" name="[% key_user %]"><input type="hidden" name="[% key_redirect %]">
</form>
<script src="[% md5_js_path %]"></script>
<script>
if (document.md5_hex) document.[% form_name %].onsubmit = function () {
  var f = document.[% form_name %];
  var u = f.[% key_user %].value;
  var p = f.[% key_pass %].value;
  var t = f.[% key_time %].value;
  var s = f.[% key_save %] && f.[% key_save %].checked ? -1 : f.[% key_expires_min %].value;

  var str = u+'/'+t+'/'+s+'/'+'';
  var sum = document.md5_hex(str +'/' + document.md5_hex(p));

  var f2 = document.[% form_name %]_jspost;
  f2.[% key_user %].value = str +'/'+ sum;
  f2.[% key_redirect %].value = f.[% key_redirect %].value;
  f2.action = f.action;
  f2.submit();
  return false;
}
</script>
};
}

###----------------------------------------------------------------###

package CGI::Ex::Auth::Data;

use strict;
use overload
    'bool'   => sub { ! shift->error },
    '0+'     => sub { 1 },
    '""'     => sub { shift->as_string },
    fallback => 1;

sub new {
    my ($class, $args) = @_;
    return bless {%{ $args || {} }}, $class;
}

sub add_data {
    my $self = shift;
    my $args = @_ == 1 ? shift : {@_};
    @{ $self }{keys %$args} = values %$args;
}

sub error {
    my $self = shift;
    if (@_ == 1) {
        $self->{'error'} = shift;
        $self->{'error_caller'} = [caller];
    }
    return $self->{'error'};
}

sub as_string {
    my $self = shift;
    return $self->error || ($self->{'user'} && $self->{'type'}) ? "Valid auth data" : "Unverified auth data";
}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

    use CGI::Ex::Auth;

    ### authorize the user
    my $auth = CGI::Ex::Auth->get_valid_auth({
        get_pass_by_user => \&get_pass_by_user,
    });


    sub get_pass_by_user {
        my $auth = shift;
        my $user = shift;
        my $pass = some_way_of_getting_password($user);
        return $pass;
    }

    ### OR - if you are using a OO based CGI or Application

    sub require_authentication {
        my $self = shift;

        return $self->{'auth'} = CGI::Ex::Auth->get_valid_auth({
            get_pass_by_user => sub {
                my ($auth, $user) = @_;
                return $self->get_pass($user);
            },
        });
    }

    sub get_pass {
        my ($self, $user) = @_;
        return $self->loopup_and_cache_pass($user);
    }

=head1 DESCRIPTION

CGI::Ex::Auth allows for auto-expiring, safe and easy web based
logins.  Auth uses javascript modules that perform MD5 hashing to cram
the password on the client side before passing them through the
internet.

For the stored cookie you can choose to use simple cram mechanisms,
secure hash cram tokens, auto expiring logins (not cookie based),
and Crypt::Blowfish protection.  You can also choose to keep
passwords plaintext and to use perl's crypt for testing
passwords.  Or you can completely replace the cookie parsing/generating
and let Auth handle requesting, setting, and storing the cookie.

A theoretical downside to this module is that it does not use a
session to preserve state so get_pass_by_user has to happen on every
request (any authenticated area has to verify authentication each time
- unless the verify_token method is completely overridden).  In theory
you should be checking the password everytime a user makes a request
to make sure the password is still valid.  A definite plus is that you
don't need to use a session if you don't want to.  It is up to the
interested reader to add caching to the get_pass_by_user method.

In the end, the only truly secure login method is across an https
connection.  Any connection across non-https (non-secure) is
susceptible to cookie hijacking or tcp hijacking - though the
possibility of this is normally small and typically requires access to
a machine somewhere in your TCP chain.  If in doubt - you should try
to use https - but even then you need to guard the logged in area
against cross-site javascript exploits.  A discussion of all security
issues is far beyond the scope of this documentation.

=head1 METHODS

=over 4

=item C<new>

Constructor.  Takes a hashref of properties as arguments.

Many of the methods which may be overridden in a subclass,
or may be passed as properties to the new constuctor such as in the following:

    CGI::Ex::Auth->new({
        get_pass_by_user => \&my_pass_sub,
        key_user         => 'my_user',
        key_pass         => 'my_pass',
        login_header     => \"<h1>My Login</h1>",
    });

The following methods will look for properties of the same name.  Each of these will be
described separately.

    cgix
    cleanup_user
    cookie_domain
    cookie_secure
    cookie_path
    cookies
    expires_min
    form
    form_name
    get_pass_by_user
    js_uri_path
    key_cookie
    key_expires_min
    key_logout
    key_pass
    key_redirect
    key_save
    key_time
    key_user
    key_verify
    key_loggedout
    bounce_on_logout
    login_footer
    login_form
    login_header
    login_script
    login_template
    handle_success
    handle_failure
    success_hook
    failure_hook
    logout_hook
    no_cookie_verify
    path_info
    script_name
    secure_hash_keys
    template_args
    template_include_path
    template_obj
    text_user
    text_pass
    text_save
    text_submit
    hide_save
    use_base64
    use_blowfish
    use_crypt
    use_plaintext
    use_session_cookie
    verify_token
    verify_payload
    verify_user

=item C<generate_token>

Takes either an auth_data object from a auth_data returned by verify_token,
or a hashref of arguments.

Possible arguments are:

    user           - the username we are generating the token for
    real_pass      - the password of the user (if use_plaintext is false
                     and use_crypt is false, the password can be an md5sum
                     of the user's password)
    use_blowfish   - indicates that we should use Crypt::Blowfish to protect
                     the generated token.  The value of this argument is used
                     as the key.  Default is false.
    use_base64     - indicates that we should use Base64 encoding to protect
                     the generated token.  Default is true.  Will not be
                     used if use_blowfish is true.
    use_plaintext  - indicates that we should keep the password in plaintext
    use_crypt      - also indicates that we should keep the password in plaintext
    expires_min    - says how many minutes until the generated token expires.
                     Values <= 0 indicate to not ever expire.  Used only on cram
                     types.
    payload        - a payload that will be passed to generate_payload and then
                     will be added to cram type tokens.  It cannot contain a /.
    prefer_simple_cram
                   - If the secure_hash_keys method returns keys, and it is a non-plaintext
                     token, generate_token will create a secure_hash_cram.  Set
                     this value to true to tell it to use a simple_cram.  This
                     is generally only useful in testing.

The following are types of tokens that can be generated by generate_token.  Each type includes
pseudocode and a sample of a generated that token.

    plaintext:
        user         := "paul"
        real_pass    := "123qwe"
        token        := join("/", user, real_pass);

        use_base64   := 0
        token        == "paul/123qwe"

        use_base64   := 1
        token        == "cGF1bC8xMjNxd2U="

        use_blowfish := "foobarbaz"
        token        == "6da702975190f0fe98a746f0d6514683"

        Notes: This token will be used if either use_plaintext or use_crypt is set.
        The real_pass can also be the md5_sum of the password.  If real_pass is an md5_sum
        of the password but the get_pass_by_user hook returns the crypt'ed password, the
        token will not be able to be verified.

    simple_cram:
        user        := "paul"
        real_pass   := "123qwe"
        server_time := 1148512991         # a time in seconds since epoch
        expires_min := 6 * 60
        payload     := "something"

        md5_pass    := md5_sum(real_pass) # if it isn't already a 32 digit md5 sum
        str         := join("/", user, server_time, expires_min, payload, md5_pass)
        md5_str     := md5(sum_str)
        token       := join("/", user, server_time, expires_min, payload, md5_str)

        use_base64  := 0
        token       == "paul/1148512991/360/something/16d0ba369a4c9781b5981eb89224ce30"

        use_base64  := 1
        token       == "cGF1bC8xMTQ4NTEyOTkxLzM2MC9zb21ldGhpbmcvMTZkMGJhMzY5YTRjOTc4MWI1OTgxZWI4OTIyNGNlMzA="

        Notes: use_blowfish is available as well

    secure_hash_cram:
        user        := "paul"
        real_pass   := "123qwe"
        server_time := 1148514034         # a time in seconds since epoch
        expires_min := 6 * 60
        payload     := "something"
        secure_hash := ["aaaa", "bbbb", "cccc", "dddd"]
        rand1       := 3                  # int(rand(length(secure_hash)))
        rand2       := 39163              # int(rand(100000))

        md5_pass    := md5_sum(real_pass) # if it isn't already a 32 digit md5 sum

        sh_str1     := join(".", "sh", secure_hash[rand1], rand2)
        sh_str2     := join(".", "sh", rand1, rand2)
        str         := join("/", user, server_time, expires_min, payload, md5_pass, sh_str1)
        md5_str     := md5(sum_str)
        token       := join("/", user, server_time, expires_min, payload, md5_str, sh_str2)

        use_base64  := 0
        token       == "paul/1148514034/360/something/06db2914c9fd4e11499e0652bcf67dae/sh.3.39163"

        Notes: use_blowfish is available as well.  The secure_hash keys need to be set in the
        "secure_hash_keys" property of the CGI::Ex::Auth object.

=item C<get_valid_auth>

Performs the core logic.  Returns an auth object on successful login.
Returns false on errored login (with the details of the error stored in
$@).  If a false value is returned, execution of the CGI should be halted.
get_valid_auth WILL NOT automatically stop execution.

  $auth->get_valid_auth || exit;

Optionally, the class and a list of arguments may be passed.  This will create a
new object using the passed arguments, and then run get_valid_auth.

  CGI::Ex::Auth->get_valid_auth({key_user => 'my_user'}) || exit;

=item C<check_valid_auth>

Runs get_valid_auth with login_print and location_bounce set to do nothing.
This allows for obtaining login data without forcing an html login
page to appear.

=item C<login_print>

Called if login errored.  Defaults to printing a very basic (but
adequate) page loaded from login_template..

You will want to override it with a template from your own system.
The hook that is called will be passed the step to print (currently
only "get_login_info" and "no_cookies"), and a hash containing the
form variables as well as the following:

=item C<login_hash_common>

Passed to the template swapped during login_print.

    %$form,            # any keys passed to the login script
    error              # The text "Login Failed" if a login occurred
    login_data         # A login data object if they failed authentication.
    key_user           # $self->key_user,        # the username fieldname
    key_pass           # $self->key_pass,        # the password fieldname
    key_time           # $self->key_time,        # the server time field name
    key_save           # $self->key_save,        # the save password checkbox field name
    key_redirect       # $self->key_redirect,    # the redirect fieldname
    form_name          # $self->form_name,       # the name of the form
    script_name        # $self->script_name,     # where the server will post back to
    path_info          # $self->path_info,       # $ENV{PATH_INFO} if any
    md5_js_path        # $self->js_uri_path ."/CGI/Ex/md5.js", # script for cramming
    $self->key_user    # $data->{'user'},        # the username (if any)
    $self->key_pass    # '',                     # intentional blankout
    $self->key_time    # $self->server_time,     # the server's time
    $self->key_expires_min # $self->expires_min  # how many minutes crams are valid
    text_user          # $self->text_user        # template text Username:
    text_pass          # $self->text_pass        # template text Password:
    text_save          # $self->text_save        # template text Save Password ?
    text_submit        # $self->text_submit      # template text Login
    hide_save          # $self->hide_save        # 0

=item C<bounce_on_logout>

Default 0.  If true, will location bounce to script returned by logout_redirect
passing the key key_logout.  If false, will simply show the login screen.

=item C<key_loggedout>

Key to bounce with in the form during a logout should bounce_on_logout return true.
Default is "loggedout".

=item C<key_logout>

If the form hash contains a true value in this field name, the current user will
be logged out.  Default is "cea_logout".

=item C<key_cookie>

The name of the auth cookie.  Default is "cea_user".

=item C<key_verify>

A field name used during a bounce to see if cookies exist.  Default is "cea_verify".

=item C<key_user>

The form field name used to pass the username.  Default is "cea_user".

=item C<key_pass>

The form field name used to pass the password.  Default is "cea_pass".

=item C<key_save>

Works in conjunction with key_expires_min.  If key_save is true, then
the cookie will be set to be saved for longer than the current session
(If it is a plaintext variety it will be given a 20 year life rather
than being a session cookie.  If it is a cram variety, the expires_min
portion of the cram will be set to -1).  If it is set to false, the cookie
will be available only for the session (If it is a plaintext variety, the cookie
will be session based and will be removed on the next loggout.  If it is
a cram variety then the cookie will only be good for expires_min minutes.

Default is "cea_save".

=item C<key_expires_min>

The name of the form field that contains how long cram type cookies will be valid
if key_save contains a false value.

Default key name is "cea_expires_min".  Default field value is 6 * 60 (six hours).

This value will have no effect when use_plaintext or use_crypt is set.

A value of -1 means no expiration.

=item C<failed_sleep>

Number of seconds to sleep if the passed tokens are invalid.  Does not apply
if validation failed because of expired tokens.  Default value is 0.
Setting to 0 disables any sleeping.

=item C<form_name>

The name of the html login form to attach the javascript to.  Default is "cea_form".

=item C<verify_token>

This method verifies the token that was passed either via the form or via cookies.
It will accept plaintext or crammed tokens (A listing of the available algorithms
for creating tokes is listed below).  It also allows for armoring the token with
base64 encoding, or using blowfish encryption.  A listing of creating these tokens
can be found under generate_token.

=item C<parse_token>

Used by verify_token to remove armor from the passed tokens and split the token into its parts.
Returns true if it was able to parse the passed token.

=item C<cleanup_user>

Called by verify_token.  Default is to do no modification.  Allows for usernames to
be lowercased, or canonized in some other way.  Should return the cleaned username.

=item C<verify_user>

Called by verify_token.  Single argument is the username.  May or may not be an
initial check to see if the username is ok.  The username will already be cleaned at
this point.  Default return is true.

=item C<get_pass_by_user>

Called by verify_token.  Given the cleaned, verified username, should return a
valid password for the user.  It can always return plaintext.  If use_crypt is
enabled, it should return the crypted password.  If use_plaintext and use_crypt
are not enabled, it may return the md5 sum of the password.

   get_pass_by_user => sub {
       my ($auth_obj, $user) = @_;
       my $pass = $some_obj->get_pass({user => $user});
       return $pass;
   }

Alternately, get_pass_by_user may return a hashref of data items that
will be added to the data object if the token is valid.  The hashref
must also contain a key named real_pass or password that contains the
password.  Note that keys passed back in the hashref that are already
in the data object will override those in the data object.

   get_pass_by_user => sub {
       my ($auth_obj, $user) = @_;
       my ($pass, $user_id) = $some_obj->get_pass({user => $user});
       return {
           password => $pass,
           user_id  => $user_id,
       };
   }

=item C<verify_password>

Called by verify_token.  Passed the password to check as well as the
auth data object.  Should return true if the password matches.
Default method can handle md5, crypt, cram, secure_hash_cram, and
plaintext (all of the default types supported by generate_token).  If
a property named verify_password exists, it will be used and called as
a coderef rather than using the default method.

=item C<verify_payload>

Called by verify_token.  Passed the password to check as well as the
auth data object.  Should return true if the payload is valid.
Default method returns true without performing any checks on the
payload.  If a property named verify_password exists, it will be used
and called as a coderef rather than using the default method.


=item C<cgix>

Returns a CGI::Ex object.

=item C<form>

A hash of passed form info.  Defaults to CGI::Ex::get_form.

=item C<cookies>

The current cookies.  Defaults to CGI::Ex::get_cookies.

=item C<login_template>

Should return either a template filename to use for the login template, or it
should return a reference to a string that contains the template.  The contents
will be used in login_print and passed to the template engine.

Default login_template is the values of login_header, login_form, login_script, and
login_script concatenated together.

Values from login_hash_common will be passed to the template engine, and will
also be used to fill in the form.

The basic values are capable of handling most needs so long as appropriate
headers and css styles are used.

=item C<login_header>

Should return a header to use in the default login_template.  The default
value will try to PROCESS a file called login_header.tt that should be
located in directory specified by the template_include_path method.

It should ideally supply css styles that format the login_form as desired.

=item C<login_footer>

Same as login_header - but for the footer.  Will look for login_footer.tt by
default.

=item C<login_form>

An html chunk that contains the necessary form fields to login the user.  The
basic chunk has a username text entry, password text entry, save password checkbox,
and submit button, and any hidden fields necessary for logging in the user.

=item C<login_script>

Contains javascript that will attach to the form from login_form.  This script
is capable of taking the login_fields and creating an md5 cram which prevents
the password from being passed plaintext.

=item C<text_user, text_pass, text_save>

The text items shown in the default login template.  The default values are:

    text_user  "Username:"
    text_pass  "Password:"
    text_save  "Save Password ?"

=item C<disable_simple_cram>

Disables simple cram type from being an available type. Default is
false.  If set, then one of use_plaintext, use_crypt, or
secure_hash_keys should be set.  Setting this option allows for
payloads to be generated by the server only - otherwise a user who
understands the algorithm could generate a valid simple_cram cookie
with a custom payload.

Another option would be to only accept payloads from tokens if use_blowfish
is set and armor was equal to "blowfish."

=back

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=head1 AUTHORS

Paul Seamons <perl at seamons dot com>

=cut
