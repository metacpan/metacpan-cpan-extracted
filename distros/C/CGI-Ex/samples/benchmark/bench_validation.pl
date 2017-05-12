#!/usr/bin/perl -w

use Benchmark qw(timethese cmpthese countit timestr);
use CGI::Ex::Dump qw(debug);
use CGI::Ex::Validate;
use Data::FormValidator;

my $form = {
  username  => "++foobar++",
  password  => "123",
  password2 => "1234",
};

my $val_hash_ce = {
    username => {
        required => 1,
        match    => 'm/^\w+$/',
        match_error => '$name may only contain letters and numbers',
        untaint  => 1,
    },
    password => {
        required => 1,
        match    => 'm/^[ -~]{6,30}$/',
#        min_len  => 6,
#        max_len  => 30,
#        match    => 'm/^[ -~]+$/',
        untaint  => 1,
    },
    password2 => {
        validate_if => 'password was_valid',
        equals      => 'password',
    },
    email => {
        required => 1,
        match    => 'm/^[\w\.\-]+\@[\w\.\-]+$/',
        untaint  => 1,
    },
};

my $val_hash_df = {
    required => [qw(username password email)],
    dependencies => {
        password => [qw(password2)],
    },
    constraints => {
        email    => qr/^[\w\.\-]+\@[\w\.\-]+$/,
        password => qr/^[ -~]{6,30}$/,
        username => qr/^\w+$/,
    },
    untaint_all_constraints => 1,
    msgs => {
        format => '%s',
        prefix => 'error_',
    },
};

sub check_form {
  my $form = shift;
  my $hash = {};
  if (! exists $form->{'username'}) {
    push @{ $hash->{'username_error'} }, 'Username required';
  } elsif ($form->{'username'} !~ m/^(\w+)$/) {
    push @{ $hash->{'username_error'} }, 'Username may only contain letters and numbers';
  } else {
    $form->{'username'} = $1;
  }
  if (! exists $form->{'password'}) {
    push @{ $hash->{'password_error'} }, 'Password required';
  } else {
    if ($form->{'password'} !~ m/^([ -~]+)$/) {
      push @{ $hash->{'password_error'} }, 'Password contained bad characters';
    } else {
      $form->{'password'} = $1;
    }
    if (length($form->{'password'}) < 6) {
      push @{ $hash->{'password_error'} }, 'Password must be more than 6 characters';
    } elsif (length($form->{'password'}) > 30) {
      push @{ $hash->{'password_error'} }, 'Password must be less than 30 characters';
    }

    if (exists($form->{'password'})
        && ! $hash->{'password_error'}
        && (! defined($form->{'password2'})
            || $form->{'password2'} ne $form->{'password'})) {
      push @{ $hash->{'password2_error'} }, 'Password2 and password must be the same';
    }
  }

  if (! exists $form->{'email'}) {
    push @{ $hash->{'email_error'} }, 'Email required';
  } elsif ($form->{'email'} !~ m/^[\w\.\-]+\@[\w\.\-]+$/) {
    push @{ $hash->{'email_error'} }, 'Please type a valid email address';
  }

  return $hash;
}

debug(CGI::Ex::Validate->validate($form, $val_hash_ce)->as_hash);
debug(Data::FormValidator->check($form, $val_hash_df)->msgs);
debug(check_form($form));

cmpthese (-2,{
  cgi_ex    => sub { my $t = CGI::Ex::Validate->validate($form, $val_hash_ce) },
  data_val  => sub { my $t = Data::FormValidator->check($form, $val_hash_df) },
  homegrown => sub { my $t = check_form($form) },
},'auto');

cmpthese (-2,{
  cgi_ex    => sub { my $t = CGI::Ex::Validate->validate($form, $val_hash_ce)->as_hash },
  data_val  => sub { my $t = Data::FormValidator->check($form, $val_hash_df)->msgs },
  homegrown => sub { my $t = scalar keys %{ check_form($form) } },
},'auto');

### Home grown solution blows the others away - but lacks features
#
# Benchmark: running cgi_ex, data_val, homegrown for at least 2 CPU seconds...
#   cgi_ex:  3 wallclock secs ( 2.04 usr +  0.00 sys =  2.04 CPU) @ 2845.10/s (n=5804)
#   data_val:  3 wallclock secs ( 2.17 usr +  0.00 sys =  2.17 CPU) @ 1884.79/s (n=4090)
#   homegrown:  3 wallclock secs ( 2.13 usr +  0.00 sys =  2.13 CPU) @ 77093.43/s (n=164209)
#              Rate  data_val    cgi_ex homegrown
# data_val   1885/s        --      -34%      -98%
# cgi_ex     2845/s       51%        --      -96%
# homegrown 77093/s     3990%     2610%        --
# Benchmark: running cgi_ex, data_val, homegrown for at least 2 CPU seconds...
#   cgi_ex:  2 wallclock secs ( 2.21 usr +  0.01 sys =  2.22 CPU) @ 2421.17/s (n=5375)
#   data_val:  2 wallclock secs ( 2.27 usr +  0.03 sys =  2.30 CPU) @ 1665.22/s (n=3830)
#   homegrown:  2 wallclock secs ( 2.04 usr +  0.01 sys =  2.05 CPU) @ 72820.00/s (n=149281)
#              Rate  data_val    cgi_ex homegrown
# data_val   1665/s        --      -31%      -98%
# cgi_ex     2421/s       45%        --      -97%
# homegrown 72820/s     4273%     2908%        --
