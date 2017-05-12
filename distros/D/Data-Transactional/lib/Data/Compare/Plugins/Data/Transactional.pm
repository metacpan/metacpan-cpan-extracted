package Data::Compare::Plugins::Data::Transactional;

use strict;
use warnings;

use Data::Compare;
use Scalar::Util qw(blessed);

our $VERSION = '1.04';

sub _register {
    return
    [
        ['Data::Transactional', \&_dt_dt_compare],
	['Data::Transactional', 'ARRAY', \&_dt_notdt_compare],
	['Data::Transactional', 'HASH', \&_dt_notdt_compare],
    ];
}

sub _dt_dt_compare {
    my($t1, $t2) = @_;
    Compare(_underlying($t1), _underlying($t2));
}

sub _dt_notdt_compare {
    my($dt, $notdt) = @_;
    ($dt, $notdt) = ($notdt, $dt) if(!(blessed($dt) && $dt->isa('Data::Transactional')));
    Compare(_underlying($dt), $notdt);
}

sub _underlying {
    my $tied = shift;
    return $tied->current_state();
}

_register();

=head1 NAME

Data::Compare::Plugin::Data::Transactional - plugin for Data::Compare to
handle Data::Transactional objects.

=head1 DESCRIPTION

Enables Data::Compare to Do The Right Thing for Data::Transactional
objects.

=over

=item comparing a Data::Transactional object to another Data::Transactional object

If you compare two Data::Transactional objects, they compare equal if
their *current* values are the same.  We never look at any checkpoints
that may be stored.

=item comparing a Data::Transactional object to an ordinary array or hash

These will be considered the same if they have the same current contents -
again, checkpoints are ignored.

=back

=head1 AUTHOR

Copyright (c) 2004 David Cantrell. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Compare>

L<Data::Transactional>

=cut
