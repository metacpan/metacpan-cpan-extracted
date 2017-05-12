package Apache::AuthPOP3;

use warnings;
use strict;

our $VERSION = '0.02';

use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} and 
                     $ENV{MOD_PERL_API_VERSION} >= 2);

BEGIN {
  if ($ENV{MOD_PERL}) {
    my @constants = qw(OK DECLINED HTTP_UNAUTHORIZED);
    if (MP2) {
      require Apache2::Access;      # for note_basic_auth_failure, get_basic_auth_pw, and requires
      require Apache2::RequestUtil; # for push_handlers, and dir_config
      require Apache2::RequestRec;  # for user, and filename
      require Apache2::Log;         # for log_error
      require Apache2::Const;
      Apache2::Const->import(-compile => @constants);
    } else {
      require Apache;
      require Apache::Constants;
      Apache::Constants->import(@constants);
    }
  }
}

use Net::POP3;
use Cache::FileCache;
use Digest::SHA1 qw(sha1_hex);

sub handler {
  my $r = shift;

  $r->push_handlers(PerlAuthzHandler => \&authorize);

  # check if MailHost config variable is present
  return MP2 ? Apache2::Const::DECLINED() : Apache::Constants::DECLINED() unless (my $mailhost = $r->dir_config('MailHost'));

  # get user's authentication credentials
  my ($res, $passwd_sent) = $r->get_basic_auth_pw;
  return $res if (MP2 and $res != Apache2::Const::OK() or !MP2 and $res != Apache::Constants::OK());
  my $user_sent = $r->user;

  my $reason = authenticate($mailhost, $user_sent, $passwd_sent);
  if ($reason) {
    $r->note_basic_auth_failure;
    $r->log_reason($reason, $r->filename);
    return MP2 ? Apache2::Const::HTTP_UNAUTHORIZED() : Apache::Constants::HTTP_UNAUTHORIZED();
  }

  return MP2 ? Apache2::Const::OK() : Apache::Constants::OK();
}

sub authenticate {
  my ($mailhost, $user_sent, $passwd_sent) = @_;

  $user_sent and $passwd_sent or return 'either username or password is empty';

  # cache sha1-ed password
  my $cache = new Cache::FileCache({ 'namespace' => __PACKAGE__, 'default_expires_in' => 120 });
  my $passwd_cached_sha1 = $cache->get($user_sent);
  my $passwd_sent_sha1 = sha1_hex($passwd_sent);
  if (defined $passwd_cached_sha1) {
    return "user $user_sent: POP3 login failed" if $passwd_cached_sha1 ne $passwd_sent_sha1;
  } else {
    return "user $user_sent: POP3 login failed" unless Net::POP3->new($mailhost)->login($user_sent, $passwd_sent);
    $cache->set($user_sent, $passwd_sent_sha1);
  }

  return '';
}

sub authorize {
  my $r = shift;

  return MP2 ? Apache2::Const::DECLINED() : Apache::Constants::DECLINED() unless (my $requires = $r->requires);
  my $user_sent = $r->user;

  for my $entry (@$requires) {
    my ($requirement, @rest) = split /\s+/, $entry->{requirement};
    return MP2 ? Apache2::Const::OK() : Apache::Constants::OK() if (lc $requirement eq 'valid-user');

    if (lc $requirement eq 'user') {
      foreach (@rest) { 
        if ($user_sent eq $_) {

          # change the username seen by apache to the one defined in UserMap
          if (my $usermap = $r->dir_config('UserMap')) {
            my %usermap = split /\s*(?:=>|,)\s*/, $usermap;
            $r->user($usermap{$user_sent}) if defined $usermap{$user_sent};
          }
          return MP2 ? Apache2::Const::OK() : Apache::Constants::OK();
        }
      }
      $r->log_error("user $user_sent: invalid user");
    }

    $r->log_error("user $user_sent: failed requirement");
  }

  $r->note_basic_auth_failure;
  $r->log_reason("user $user_sent: not authorized", $r->filename);
  return MP2 ? Apache2::Const::HTTP_UNAUTHORIZED() : Apache::Constants::HTTP_UNAUTHORIZED();
}

1;

__END__

=head1 NAME

Apache::AuthPOP3 - Authentication and Authorization via POP3

=head1 SYNOPSIS

  # In httpd.conf or startup.pl:

  PerlModule Apache::AuthDBI

  # In httpd.conf or .htaccess:

  <Location /protected>
    AuthName POP3
    AuthType Basic
    PerlAuthenHandler Apache::AuthPOP3
    PerlSetVar        MailHost pop.example.com

    PerlSetVar        UserMap pop3user1=>realname1,pop3user2=>realname2
    Require user      pop3user1 pop3user2 pop3user3 pop3user4

    # Require valid-user
  </Location>

=head1 DESCRIPTION

This module allows authentication and authorization against a POP3 server.

Received username and password are looked up in the cache. If nothing was
stored in the cache with that particular username and password within
the past two minutes, they are passed to the POP3 server and cached
once authenticated; SHA1 checksum of password is used in caching.

After being authorized, the username or the name that maps to it based
on the UserMap configuration is used to set the remote user.

=head1 CONFIGURATION

=over 4

=item B<MailHost> (Required)

Defines the POP3 server to authenticate against. 

=item B<UserMap> (Optional)

If defined, the remote user is set based on this.

=back

=head1 AUTHOR

Sherwin Daganato, C<< <sherwin at cpan.org> >>

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Net::POP3>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Sherwin Daganato, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

