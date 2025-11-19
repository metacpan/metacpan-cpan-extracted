package Daje::Document::Templates::Base;
use Mojo::Base -base;
use v5.42;


# NAME
# ====
#
#      Daje::Document::Templates::Base - It's the base class for all Daje Document Templates
#
#
# REQUIRES
# ========
#
# use Mojo::Base;
#
# DESCRIPTION
# ===========
#
# Daje::Document::Templates::Base Provides some common methods
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

has 'subs';

sub get_subs_array($self) {
    my $subs = [];
    if (defined $self->subs) {
        @{$subs} = split(',', $self->subs);
    }
    return $subs;
}

sub add_subs($self, $data) {
    $self->set_subs();
    my $subs = $self->get_subs_array();
    my $length = scalar @{$subs};
    for (my $i = 0; $i < $length; $i++) {
        my $sub = @{$subs}[$i];
        $data->{$sub} = $self->$sub();
    }
}
1;