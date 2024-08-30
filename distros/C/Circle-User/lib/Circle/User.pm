package Circle::User;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use File::Path qw(make_path);
use File::Basename;
use Circle::Common qw(load_config build_url_template http_json_post http_json_get);

our $VERSION = '0.02';
our @EXPORT  = qw(
  send_register_verify_code
  register
  send_verify_code
  login
  logout
  send_pay_verify_code
  set_pay_password
  have_pay_password
  send_reset_password_verify_code
  reset_password
  add_contacts
  list_contacts
  save_or_update_user_info
  get_user_info
);

sub _build_url_template {
    my ($path) = @_;
    return build_url_template( "user", $path );
}

sub send_register_verify_code {
    my ($req) = @_;
    my $url = _build_url_template("sendRegisterVerifyCode");
    return http_json_post( $url, $req );
}

sub register {
    my ($req) = @_;
    my $url = _build_url_template("register");
    return http_json_post( $url, $req );
}

sub send_verify_code {
    my ($req) = @_;
    my $url = _build_url_template("sendVerifyCode");
    return http_json_post( $url, $req );
}

sub login {
    my ($req)    = @_;
    my $url      = _build_url_template("login");
    my $response = http_json_post( $url, $req );
    if ( $response->{status} == 200 ) {
        my $login_data = $response->{data};
        _save_session_data( $req, $login_data );
    }

    return $response;
}

sub _save_session_data {
    my ( $req, $login_data ) = @_;
    my $user_type    = defined $req->{email} ? 1             : 0;
    my $user_key     = defined $req->{email} ? 'email'       : 'phone';
    my $user_value   = defined $req->{email} ? $req->{email} : $req->{phone};
    my $user_id      = $login_data->{userId};
    my $session_key  = $login_data->{sessionKey};
    my $config       = load_config();
    my $session_path = $config->{user}->{sessionPath};
    my $full_path    = $ENV{HOME} . '/' . $session_path;

    if ( not -f $full_path ) {
        my $dirname = dirname($full_path);
        make_path($dirname);
    }
    my $content = qq(
##### user login information
userType=$user_type
userId=$user_id
$user_key=$user_value
sessionKey=$session_key
);
    open my $fd, ":>encoding(utf8)", $full_path;
    print $fd $content;
    close($fd);
    chmod 0600, $full_path;
}

sub logout {
    my $url = _build_url_template("logout");
    return http_json_post( $url, {} );
}

sub send_pay_verify_code {
    my ($req) = @_;
    my $url = _build_url_template("sendPayVerifyCode");
    return http_json_post( $url, $req );
}

sub set_pay_password {
    my ($req) = @_;
    my $url = _build_url_template("setPayPassword");
    return http_json_post( $url, $req );
}

sub have_pay_password {
    my $url = _build_url_template("havePayPassword");
    return http_json_get($url);
}

sub send_reset_password_verify_code {
    my ($req) = @_;
    my $url = _build_url_template("sendResetPasswordVerifyCode");
    return http_json_post( $url, $req );
}

sub reset_password {
    my ($req) = @_;
    my $url = _build_url_template("resetPassword");
    return http_json_post( $url, $req );
}

sub add_contacts {
    my ($req) = @_;
    my $url = _build_url_template("addContacts");
    return http_json_post( $url, $req );
}

sub list_contacts {
    my $url = _build_url_template("listContacts");
    return http_json_get($url);
}

sub save_or_update_user_info {
    my ($req) = @_;
    my $url = _build_url_template("saveOrUpdateUserInfo");
    return http_json_post( $url, $req );
}

sub get_user_info {
    my $url = _build_url_template("userInfo");
    return http_json_get($url);
}

1;

__END__

=head1 NAME

Circle::User - the user module for Circle::Chain SDK

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    # 1. first register if you not signup.
    my $response = send_register_verify_code({
      email => 'circle-node@gmail.com'
    });
    if ($response->{status} != 200) {
      croak 'cannot send register verify code:' . $response->{status};
    }
    # receive you verify code in email or your mobile phone.
    $response = register({
      email => 'circle-node@gmail.com',
      passwordInput1 => '<password>',
      passwordInput2 => '<password>',
      verifyCode => '<verify_code>'
    });
    if ($response->{status} != 200) {
      croak 'cannot register status' . $response->{status};
    }

    # 2. then login
    $response = send_verify_code({
      email => 'circle-node@gmail.com'
    });
    if ($response->{status} != 200) {
      croak 'cannot send login verify code:' . $response->{status};
    }
    # receive you verify code in email or your mobile phone.
    $response = login({
      email => 'circle-node@gmail.com',
      verifyCode => '<verify_code>',
      password => '<password>'
    });
    if ($response->{status} != 200) {
      croak 'cannot login status' . $response->{status};
    }

    # 3. set pay password.
    $response = send_pay_verify_code({
      email => 'circle-node@gmail.com'
    });
    if ($response->{status} != 200) {
      croak 'cannot send pay password verify code:' . $response->{status};
    }
    # receive you payVerifyCode from your email.
    $response = set_pay_password({
      account => {
      	email => 'circle-node@gmail.com'
      },
      verifyCode => '<verify_code>',
      password => '<password>'
    });
    if ($response->{status} != 200) {
      croak 'cannot set pay password status:' . $response->{status};
    }
    # now the pay password is set success.

=head1 DESCRIPTION

The module provides user functions such as register, login and reset password etc.

=head1 EXPORT

Export the following methods in default:

    our @EXPORT = qw(
      send_register_verify_code
      register
      send_verify_code
      login
      logout
      send_pay_verify_code
      set_pay_password
      have_pay_password
      send_reset_password_verify_code
      reset_password
      add_contacts
      list_contacts
      save_or_update_user_info
      get_user_info
    );

So you just use the module:

    use Circle::User;


=head1 METHODS

=head2 send_register_verify_code

    my $response = send_register_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send register verify code:' . $response->{status};
    }

If you want send register verify code to your phone, you can use the following code:

    $response = send_register_verify_code({ phone => '<your mobile phone>'});

Note: the phone register is only supported in China mainland.

=head2 register

    # receive you verify code in email or your mobile phone.
    $response = register(
        {
            email          => 'circle-node@gmail.com',
            passwordInput1 => '<password>',
            passwordInput2 => '<password>',
            verifyCode     => '<verify_code>'
        }
    );

=head2 send_verify_code

    $response = send_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send login verify code:' . $response->{status};
    }

=head2 login

    # receive you verify code in email or your mobile phone.
    $response = login(
        {
            email      => 'circle-node@gmail.com',
            verifyCode => '<verify_code>',
            password   => '<password>'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot login status' . $response->{status};
    }

=head2 logout

    $response = logout();
    if ( $response->{status} == 200 ) {
        # you success log out.
    }

=head2 send_pay_verify_code

    $response = send_pay_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send pay password verify code:' . $response->{status};
    }

=head2 set_pay_password

    # receive you payVerifyCode from your email.
    $response = set_pay_password(
        {
            account => {
                email => 'circle-node@gmail.com'
            },
            verifyCode => '<verify_code>',
            password   => '<password>'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot set pay password status:' . $response->{status};
    }

=head2 send_reset_password_verify_code

    $response = send_reset_password_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send reset password verify code:' . $response->{status};
    }

=head2 reset_password

    # receive you payVerifyCode from your email.
    $response = reset_password(
        {
            account => {
                email => 'circle-node@gmail.com'
            },
            verifyCode => '<verify_code>',
            password1  => '<password>'
            password2  => '<password'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot set reset password status:' . $response->{status};
    }

=head2 add_contacts

    my $response = add_contacts({
        phone => '<phone>',
        name  => 'tony',
        sex   => 1,  # 0 woman, 1 man
        icon  => '',
        address => 'Beijing China',
        description => 'this is my friend: tony'
    });
    if ($response->{status} == 200) {
       # add contacts success here.
    }

=head2 list_contacts

    my $response = list_contacts();
    if ($response->{status} == 200) {
        my $data = $response->{data};
        # process contacts here.
    }

=head2 save_or_update_user_info

    my $response = save_or_update_user_info({
        "name" => "test",
        "phone" => "<your phone>",
        "email" => "test@gmail.com",
        "sex" => 1,
        "address" => "beijing",
        "motherLang" => 1,
        "wechat" => "lidh04"
    });
    if ($response->{status} == 200) {
      # your data is save success here.
    }

=head2 get_user_info

    my $response = get_user_info();
    if ($response->{status} == 200) {
        my $data = $response->{data};
        # process user info data here.
    }

=head1 SEE ALSO

See L<Circle::Common> for circle common module.

See L<Circle::Wallet> for circle wallet module.

See L<Circle::Block> for circle block module.

=head1 COPYRIGHT AND LICENSE

Copyright 2024-2030 Charles li

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
