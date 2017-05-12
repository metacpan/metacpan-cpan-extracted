#!/usr/bin/perl -w

=head1 NAME

cgi_ex_2.cgi - Rewrite of cgi_ex_1.cgi using CGI::Ex::App

=cut

use strict;
use base qw(CGI::Ex::App);
use CGI::Ex::Dump qw(debug);

if ($0 eq __FILE__) {
    __PACKAGE__->navigate;
}

### show what hooks ran when we are done
sub post_navigate { debug shift->dump_history }

### this will work for both userinfo_hash_common and _success_hash_common
sub hash_common {
    return {
        title => 'My Application',
        color => ['#ccccff', '#aaaaff'],
    };
}

###----------------------------------------------------------------###

sub main_hash_validation {
    return {
        'group order' => ['username', 'password'],
        username => {
            required => 1,
            min_len  => 3,
            max_len  => 30,
            match    => 'm/^\w+$/',
            # could probably all be done with match => 'm/^\w{3,30}$/'
        },
        password => {
            required => 1,
            max_len  => 20,
        },
        password_verify => {
            validate_if => 'password',
            equals      => 'password',
        },
    };
}

sub main_finalize {
    my $self = shift;
    my $form = $self->form;
    debug $form;
    return 1;
}

sub main_next_step { '_success' }

sub main_file_print {
    return \ qq {
    <html>
    <head>
      <title>[% title %]</title>
      <style>
      .error {
        display: block;
        color: red;
        font-weight: bold;
      }
      </style>
    </head>
    <body>
    <h1 style='color:blue'>Please Enter information</h1>
    <span style='color:red'>[% error_header %]</span>
    <br>

    <form name="[% form_name %]" action="[% script_name %]" method="POST">
    <input type=hidden name=processing value=1>

    <table>
    <tr bgcolor=[% color.0 %]>
      <td>Username:</td>
      <td>
        <input type=text size=30 name=username>
        <span class=error id=username_error>[% username_error %]</span></td>
    </tr>
    <tr bgcolor=[% color.1 %]>
      <td>Password:</td>
      <td><input type=password size=20 name=password>
        <span class=error id=password_error>[% password_error %]</span></td>
    </tr>
    <tr bgcolor=[% color.0 %]>
      <td>Password Verify:</td>
      <td><input type=password size=20 name=password_verify>
        <span class=error id=password_verify_error>[% password_verify_error %]</span></td>
    </tr>
    <tr bgcolor=[% color.1 %]>
      <td colspan=2 align=right><input type=submit value=Submit></td>
    </tr>

    </table>

    </form>

    [% js_validation %]
    </body>
    </html>
};
}

###----------------------------------------------------------------###

sub _success_file_print {
    return \ qq{
    <html>
    <head><title>[% title %]</title></head>
    <body>
    <h1 style='color:green'>Success</h1>
    <br>
    I can now continue on with the rest of my script!
    </body>
    </html>
};
}

###----------------------------------------------------------------###
### These methods override the base functionality of CGI::Ex::App

sub ready_validate { shift->form->{'processing'} ? 1 : 0 }

sub set_ready_validate {
    my $self = shift;
    my ($step, $is_ready) = (@_ == 2) ? @_ : (undef, shift);
    if ($is_ready) {
        $self->form->{'processing'} = 1;
    } else {
        delete $self->form->{'processing'};
    }
}


__END__

