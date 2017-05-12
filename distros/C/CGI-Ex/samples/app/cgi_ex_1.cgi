#!/usr/bin/perl -w

=head1 NAME

cgi_ex_1.cgi - Show a basic example using some of the CGI::Ex tools (but not App based)

=cut

if (__FILE__ eq $0) {
    main();
}

###----------------------------------------------------------------###

use strict;
use CGI::Ex;
use CGI::Ex::Validate ();
use CGI::Ex::Dump qw(debug);

###----------------------------------------------------------------###

sub main {
    my $cgix = CGI::Ex->new;
    my $vob  = CGI::Ex::Validate->new;
    my $form = $cgix->get_form();

    ### allow for js validation libraries
    ### path_info should contain something like /CGI/Ex/yaml_load.js
    ### see the line with 'js_val' below
    my $info = $ENV{PATH_INFO} || '';
    if ($info =~ m|^(/\w+)+.js$|) {
        $info =~ s|^/+||;
        $cgix->print_js($info);
        return;
    }


    ### check for errors - if they have submitted information
    my $has_info = ($form->{'processing'}) ? 1 : 0;
    my $errob = $has_info ? $vob->validate($form, validation_hash()) : undef;
    my $form_name = 'formfoo';

    ### failed validation - send out the template
    if (! $has_info || $errob) {

        ### get a template and swap defaults
        my $swap = defaults_hash();

        ### add errors to the swap (if any)
        if ($errob) {
            my $hash = $errob->as_hash();
            $swap->{$_} = delete($hash->{$_}) foreach keys %$hash;
            $swap->{'error_header'} = 'Please correct the form information below';
        }

        ### get js validation ready
        $swap->{'form_name'} = $form_name;
        $swap->{'js_val'} = $vob->generate_js(validation_hash(), # filename or valhash
                                              $form_name,         # name of form
                                              $ENV{'SCRIPT_NAME'}); # browser path to cgi that calls print_js

        ### swap in defaults, errors and js_validation
        my $content = $cgix->swap_template(get_content_form(), $swap);

        ### fill form fields
        $cgix->fill(\$content, $form);
        #debug $content;

        ### print it out
        $cgix->print_content_type();
        print $content;
        return;
    }

    debug $form;

    ### show some sort of success if there were no errors
    $cgix->print_content_type;
    my $content = $cgix->swap_template(get_content_success(), defaults_hash());
    print $content;
    return;

}

###----------------------------------------------------------------###

sub validation_hash {
    return {
        'group order' => ['username', 'password', 'password_verify'],
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

sub defaults_hash {
    return {
        title       => 'My Application',
        script_name => $ENV{'SCRIPT_NAME'},
        color       => ['#ccccff', '#aaaaff'],
    }
}

###----------------------------------------------------------------###

sub get_content_form {
  return qq{
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

    [% js_val %]
    </body>
    </html>
  };
}

sub get_content_success {
  return qq{
    <html>
    <head><title>[% title %]</title></head>
    <body>
    <h1 style='color:green'>Success</h1>
    <br>
    print "I can now continue on with the rest of my script!";
    </body>
    </html>
  };
}

__END__
