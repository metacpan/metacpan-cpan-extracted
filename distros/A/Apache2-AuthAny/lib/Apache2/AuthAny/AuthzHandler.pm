package Apache2::AuthAny::AuthzHandler;

use strict;
use Apache2::Const -compile => qw(OK DECLINED HTTP_UNAUTHORIZED);
use Data::Dumper qw(Dumper);

use Apache2::AuthAny::DB qw();
our $VERSION = '0.201';

sub handler {
    my $r = shift;

    my $cf = Apache2::Module::get_config('Apache2::AuthAny',
                                         $r->server,
                                         $r->per_dir_config) || {};

    my %require;
    foreach my $req (@{ $r->requires }) {
        my ($k, @v) = split /\s+/, $req->{requirement};
#        warn "\$k => $k, \@v => @v";
        unless ($k) {
            my $msg = "Configuration error. Lone Require";
            $r->log->error("Apache2::AuthAny::AuthzHandler: $msg");
            die $msg;
        }
        $k = lc($k);

        if ($k eq 'valid-user') {
            $require{'valid-user'} = 1;

        } elsif ($k eq 'identified-user') {
            $require{'identified-user'} = 1;

         } elsif ($k eq 'authenticated') {
             $require{'authenticated'} = 1;

         } elsif ($k eq 'session') {
             $require{'session'} = 1;

        } elsif ($k eq 'user') {
            foreach my $user (@v) {
                $require{user}{$user} = 1;
            }

        } elsif ($k eq 'role') {
            foreach my $role (@v) {
                push @{ $require{role} }, $role;
            }

        } else {
            my $msg = "invalid Require statement 'Require $req->{requirement}'";
            die "$msg";
        }
    }

#    warn Dumper(\%require);
    unless (%require) {
        my $msg = "Apache2::AuthAny::AuthzHandler: No 'Require'. WTF";
        $r->log->error($msg);
        die $msg;
        #return Apache2::Const::DECLINED;
    }

    my $user_permitted = 0;
    $r->log->info("Authz: %require: '" . Dumper(\%require) . "'");

    if ($require{'valid-user'} ||
        ($require{user} && $require{user}{$r->user}) ||
        ($require{'identified-user'} && $ENV{AA_IDENT_UID})
       ) {
        $user_permitted = 1;
    } elsif (! $ENV{AA_IDENT_UID}) {
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'unknown');
    }

    if (! $user_permitted && $require{role} ) {
        my %user_role = map { $_ => 1 } split(",", $ENV{AA_ROLES});
        foreach my $required_role (@{ $require{role} }) {
            if ($user_role{$required_role}) {
                $user_permitted = 1;
                last;
            }
        }
    }

    # If user would otherwise be permitted, but has timed out, go
    # to gate with timeout message.
    if ($user_permitted && $require{'authenticated'} && $ENV{AA_STATE} ne 'authenticated') {
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'timeout');
    }

    # Do not allow otherwise permitted identified users who are flagged in-active
    if ($user_permitted && exists($ENV{AA_IDENT_active}) && ! $ENV{AA_IDENT_active}) {
        my $msg = "Not activated";
        $r->log->warn("Apache2::AuthAny::AuthzHandler: $msg");
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'authz',  {msg => $msg});
    }

    # Do not allow otherwise permitted users with no session cookie
    if ($user_permitted && $require{'session'} && ! $ENV{AA_SESSION}) {
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'session');
    }

    return Apache2::Const::OK if $user_permitted;

    # Determine which error message to use on the GATE page
    if ($require{role}) {
        return Apache2::AuthAny::AuthUtil::goToGATE
              ($r, 'authz', { req_roles => join(",", @{ $require{role} }),
                              user_roles => $ENV{AA_ROLES},
               });
    } else {
        my $msg = "Only certain users are permitted";
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'authz', {msg => $msg});
    }
}

1;

