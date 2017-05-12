package Template::Plugin::Catalyst::View::PDF::Reuse::Barcode;

use strict;
use warnings;
use parent 'Template::Plugin';

our $AUTOLOAD;
our $target = 'PDF::Reuse::Barcode';

# Adapted from Template::Plugin::Procedural by Mark Fowler
sub load {
    my ($class, $context) = @_;

    my $proxy = "Template::Plugin::" . $class;
    eval "use $target";
    no strict "refs";
    if ($@) {
        my $error = $@;
        *{ $proxy . "::AUTOLOAD" } = sub {
            $AUTOLOAD =~ s!^.*::!!;
            die "Cannot load $target so unable to execute '$AUTOLOAD' in template - $error"
                unless ($AUTOLOAD eq 'DESTROY');
        };  
    } else {
        *{ $proxy . "::AUTOLOAD" } = sub {
            $AUTOLOAD =~ s!^.*::!!;
            if (my $method = $target->can($AUTOLOAD)) {
                shift @_;

                # Expand hashref arguments for PDF::Reuse::Barcode
                if (ref $_[0] eq 'HASH') {
                    splice @_,0,1,%{$_[0]};
                }

                goto $method;
            } else {
                warn "Cannot find method $AUTOLOAD in $target";
            }
        };  
    }

    *{ $proxy . "::new" } = sub {
        my $this;
        return bless \$this, $_[0];
    };
 
    return $proxy;
}


=head1 NAME

Template::Plugin::Catalyst::View::PDF::Reuse

=head1 SYNOPSYS

Template Toolkit plugin for PDF::Reuse

=head1 AUTHOR

Jon Allen, L<jj@jonallen.info>

=head1 SEE ALSO

Penny's Arcade Open Source - L<http://www.pennysarcade.co.uk/opensource>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Penny's Arcade Limited, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
