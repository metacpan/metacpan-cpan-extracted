use utf8;
use strict;
use warnings;

package DBIx::DR::Util;

use base qw(Exporter);
our @EXPORT = qw(camelize decamelize);


sub camelize($) {
    my ($str) = @_;

    my ($module, $method) = split /#/, $str;

    $module =
        join '', map { ucfirst } split /_/,
            join '::' => map { ucfirst lc } split /-/ => $module;

    $module =~ s/dbix::dr::/DBIx::DR::/i;

    return ($module, $method);
}


sub decamelize($;$) {
    my ($class, $constructor) = @_;
    for ($class) {
        s/(?<!^)[A-Z]/_$&/g;
        s/::_/::/g;
        s/::/-/g;
    }

    return lc $class unless $constructor;
    return lc($class) . "#$constructor";
}

1;

=head1 NAME

DBIx::DR::Util - some functions for L<DBIx::DR>.

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

