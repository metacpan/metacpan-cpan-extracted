package AnyEvent::Retry::Types;
BEGIN {
  $AnyEvent::Retry::Types::VERSION = '0.03';
}
# ABSTRACT: Types used internally by C<AnyEvent::Retry>
use strict;
use warnings;
use true;

use MooseX::Types -declare => ['Interval'];
use MooseX::Types::Moose qw(Str HashRef);

role_type Interval, { role => 'AnyEvent::Retry::Interval::API' };

sub class_name {
    my $str = shift;
    if(/^\+(.+)$/){
        return $1;
    }
    else {
        return "AnyEvent::Retry::Interval::$str";
    }
}

coerce Interval, from Str, via {
    my $name = class_name($_);
    Class::MOP::load_class($name);
    return $name->new;
};

coerce Interval, from HashRef, via {
    my $req = [keys %$_]->[0];
    my $args = $_->{$req};

    my $name = class_name($req);
    Class::MOP::load_class($name);
    return $name->new($args);
};

__END__
=pod

=head1 NAME

AnyEvent::Retry::Types - Types used internally by C<AnyEvent::Retry>

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

