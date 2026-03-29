package Daje::Helper::Companies::Load;
use Mojo::Base -base, -async_await;
use v5.42;

# NAME
# ====
#
# Daje::Helper::Companies::Load - Its a company helper
#
#
# DESCRIPTION
# ===========
#
#
#
# REQUIRES
# ========
#
#
# v5.42
#
# Mojo::Base
#
#
# METHODS
# =======
#
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

has 'db';

async sub load_companies_from_user_mail_p($self, $mail){
    my $stmt = qq {
        SELECT companies_companies.* FROM companies_companies, companies_users
            WHERE companies_companies_pkey  = companies_companies_fkey
        AND users_users_fkey = (SELECT users_users_pkey FROM users_users WHERE mail = ?)
    };

    my $hash = $self->db->query(
        $stmt,($mail)
    );

    my $result = [];
    $result = $hash->hashes if $hash && $hash->rows > 0;

    return $result;
}
1;