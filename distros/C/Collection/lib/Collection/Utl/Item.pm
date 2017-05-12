package Collection::Utl::Item;

=head1 NAME

Collection::Utl::Item - Base class for objects.

=head1 SYNOPSIS

    use Collection::Utl::Item;
    our @ISA = qw( Collection::Utl::Item  );
             
=head1 DESCRIPTION

Base class for objects.

=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Collection::Utl::Base;
@Collection::Utl::Item::ISA     = qw(Collection::Utl::Base);
$Collection::Utl::Item::VERSION = '0.02';
attributes(qw/ _attr/);
sub init { return 1 };    #if suss

sub _init {
    my $self = shift;
    $self->_attr(shift);
    return $self->init(@_);
}

sub _get_attr {
    return $_[0]->_attr;
}

sub _changed {
    my $self = shift;
    my $rec  = $self->_attr();
    if ( ref $rec eq 'HASH' and my $obj = tied %$rec ) {
        return $obj->_changed;
    }
    else {
        carp ref($self) . "Not tied _attr";
    }
    return 0;
}

# Preloaded methods go here.

1;
__END__


=head1 SEE ALSO

Collection::Utl::ActiveRecord, Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

