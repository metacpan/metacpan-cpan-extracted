package Data::Format::Validate::Email;
our $VERSION = q/0.2/;

use Carp;
use base q/Exporter/;

our @EXPORT_OK = qw/
    looks_like_any_email
    looks_like_common_email
/;

our %EXPORT_TAGS = (
    q/all/ => [qw/
        looks_like_any_email
        looks_like_common_email
    /]
);

sub looks_like_any_email {

    $_ = shift || croak q/Value most be provided/;
    /^\S+@\S+$/
}

sub looks_like_common_email {

    $_ = shift || croak q/Value most be provided/;
    /^\w+(?:\.\w+)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,6}$/i
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::Email - A e-mail validating module.

=head1 SYNOPSIS

Module that validate e-mail addressess.

=head1 Utilities

=over 4

=item Any E-mail

    use Data::Format::Validate::Email 'looks_like_any_email';

    looks_like_any_email 'israel.batista@univem.edu.br';    # 1
    looks_like_any_email '!$%@&[.B471374@*")..$$#!+=.-';    # 1

    looks_like_any_email 'israel.batistaunivem.edu.br';     # 0
    looks_like_any_email 'israel. batista@univem.edu.br';   # 0
    looks_like_any_email 'israel.batista@univ em.edu.br';   # 0

=item Common E-mail

    use Data::Format::Validate::Email 'looks_like_common_email';

    looks_like_common_email 'israel.batista@univem.edu.br';         # 1
    looks_like_common_email 'israel.batista42@univem.edu.br';       # 1

    looks_like_common_email 'israel.@univem.edu.br';                # 0
    looks_like_common_email 'israel.batistaunivem.edu.br';          # 0
    looks_like_common_email '!$%@&[.B471374@*")..$$#!+=.-';         # 0
    looks_like_common_email '!srael.batista@un!vem.edu.br';         # 0
    looks_like_common_email 'i%rael.bati%ta@univem.edu.br';         # 0
    looks_like_common_email 'isra&l.batista@univ&m.&du.br';         # 0
    looks_like_common_email 'israel[batista]@univem.edu.br';        # 0
    looks_like_common_email 'israel. batista@univem.edu.br';        # 0
    looks_like_common_email 'israel.batista@univem. edu.br';        # 0
    looks_like_common_email 'israel.batista@univem..edu.br';        # 0
    looks_like_common_email 'israel..batista@univem.edu.br';        # 0
    looks_like_common_email 'israel.batista@@univem.edu.br';        # 0
    looks_like_common_email 'israel.batista@univem.edu.brasilia';   # 0

=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/Email.pm

=head1 AUTHOR

Created by Israel Batista <<israel.batista@univem.edu.br>>

=cut
