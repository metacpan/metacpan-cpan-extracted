package Daje::Helper::Users::VerificationCodes;
use Mojo::Base -base;
use v5.42;

# NAME
# ====
#
#      Daje::Helper::Users::VerificationCodes - It's the login verification code manager
#
#
# REQUIRES
# ========
#
# use Mojo::Base;
# use Daje::Database::Model::Super::Users;
#
# DESCRIPTION
# ===========
#
# Daje::Helper::Users::VerificationCodes is verifying logging in users
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#
#

use Daje::Database::Model::UsersVerificationCodes;

has 'db';

sub verification($self, $users_users_pkey) {

    my @set = ('0' ..'9', 'A' .. 'F');
    my $verification_code = join '' => map $set[rand @set], 1 .. 4;

    my $login_verification_codes_pkey = Daje::Database::Model::UsersVerificationCodes->new(
        db => $self->db
    )->save_verification_code(
        $users_users_pkey, $verification_code
    );

    return $verification_code;
}
1;