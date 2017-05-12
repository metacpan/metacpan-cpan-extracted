use utf8;
use strict;
use warnings;


package DR::Msgpuck::Bool;

use overload
    bool        => sub { ${ $_[0] } },
    int         => sub { ${ $_[0] } },
    '!'         => sub { $_[0]->new(!${ $_[0] }) },
    '""'        => sub { ${ $_[0] } },
;

sub TO_JSON {
    my ($self) = @_;
    $$self ? 'true' : 'false';
}

sub TO_MSGPACK {
    my ($self) = @_;
    pack 'C', $$self ? 0xC3 : 0xC2;
}

sub new {
    my ($class, $v) = @_;
    $v = $v ? 1 : 0;
    bless \$v => ref($class) || $class;
}

package DR::Msgpuck::True;
BEGIN { our @ISA = ('DR::Msgpuck::Bool'); }

sub new {
    my ($class) = @_;
    $class->SUPER::new(1);
}

package DR::Msgpuck::False;
BEGIN { our @ISA = ('DR::Msgpuck::Bool'); }

sub new {
    my ($class) = @_;
    $class->SUPER::new(0);
}

1;

__END__

=head1 NAME

DR::Msgpuck::Bool - container for bool.

=head1 SYNOPSIS

    use DR::Msgpuck::Bool;
    use DR::Msgpuck;

    my $blobtrue1 = msgpack(DR::Msgpuck::Bool->new(1));
    my $blobtrue2 = msgpack(DR::Msgpuck::Bool::True->new);

    
    my $blobfalse1 = msgpack(DR::Msgpuck::Bool->new(0));
    my $blobfalse2 = msgpack(DR::Msgpuck::Bool::False->new);


=head1 DESCRIPTION

L<msgunpack> uses the class while unpacks booleans. You can use
the class to force pack value as boolean.


=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
