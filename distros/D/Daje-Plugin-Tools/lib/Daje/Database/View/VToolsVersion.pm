package Daje::Database::View::VToolsVersion;
use Mojo::Base 'Daje::Database::View::Super::VToolsVersion', -base, -signatures, -async_await;
use v5.40;

# NAME
# ====
#
# Daje::Database::View::VToolsVersion - It creates perl code
#
# SYNOPSIS
# ========
#
#     use Daje::Database::View::VToolsVersion;
#
# DESCRIPTION
# ===========
#
# Daje::Database::View::VToolsVersion is a module that retrieves data from a View
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

async sub load_pkey_p($self, $tools_version_pkey) {
    return $self->load_pkey($tools_version_pkey);
}
1;