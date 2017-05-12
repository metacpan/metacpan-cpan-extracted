#===============================================================================
#
#  DESCRIPTION:  Flow SQL
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
#$Id$
package Collection::Utl::Flow;

=head1 NAME

Collection::Utl::Flow - extention for flow sql queries

=head1 SYNOPSIS

    use Flow;
    my $f = $collection->list_ids( exp=>{ type=>1, },
        page=>0, onpage=>10,  );
    my $fr = create_flow($f, sub { warn Dumper \@_});
    $fr->run();

             
=head1 DESCRIPTION

extention for flow sql queries

=cut
our $VERSION = '0.01';
use Flow;
use strict;
use warnings;
use base 'Flow';
sub flow {
    my $self = shift;
    if (my $h = $self->get_handler) {
    my $collection = $self->{__collection__};
    my $args = $self->{__flow_sql__};
    $collection->__flow_sql__($h, @$args);
    }
}

1;
__END__

=head1 SEE ALSO

Collection, Flow, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


