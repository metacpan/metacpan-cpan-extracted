package Daje::Document::Templates::Tools::Generate::SQL;
use Mojo::Base 'Daje::Document::Templates::Base', -base;
use v5.42;

# NAME
# ====
#
# Daje::Templates::Tools::Generate::SQL; - It creates perl code
#
# SYNOPSIS
# ========
#
#     use Daje::Templates::Tools::Generate::SQL;
#
#     Provides a method for the template to be loaded into the data structure
#
#     sub length_default_calc($self) returns a sub for setting details in template.
#
#
# DESCRIPTION
# ===========
#
# Daje::Templates::Tools::Generate::SQL; is a module that retrieves data from a View
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

sub set_subs($self) {
    $self->subs(('length_default_calc'));
}


sub length_default_calc($self) {
    return sub {
        my $length = $_[0];
        my $scale = $_[1];
        my $notnull = $_[2];
        my $default = $_[3];
        my $result = "";
        if ($length > 0 and $scale > 0) {
            $result = "($length, $scale)";
        }
        elsif ($length > 0 and $scale == 0) {
            $result = "($length)";
        }
        if ($notnull == 1) {
            $result .= " NOT NULL DEFAULT $default"
        }

        return $result;
    };
}
1;

__DATA__

@@ sql


[% FOREACH version IN versions %]
-- up [% version.version %]
    [% FOREACH table IN version.tables %]
CREATE TABLE IF NOT EXISTS [% table.table_name %]
(
    [% table.table_name %]_pkey  SERIAL NOT NULL,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    insdatetime timestamp without time zone NOT NULL DEFAULT now(),
    modby character varying COLLATE pg_catalog."default" NOT NULL DEFAULT 'System'::character varying,
    moddatetime timestamp without time zone NOT NULL DEFAULT now(),
    [% FOREACH field IN table.fields %]
    [% field.fieldname %]  [% field.datatype %] [% length_default_calc(field.length, field.scale, field.notnull, field.default) %],
    [% END %]
    CONSTRAINT [% table.table_name %]_pkey PRIMARY KEY ([% table.table_name %]_pkey)
);
    [% END %]

-- down [% version.version %]

[% END %]

