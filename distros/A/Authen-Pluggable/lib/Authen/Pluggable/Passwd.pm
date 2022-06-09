package Authen::Pluggable::Passwd;
$Authen::Pluggable::Passwd::VERSION = '0.03';
use Mojo::Base -base, -signatures;

use Authen::Simple::Passwd;

has 'parent' => undef, weak => 1;
has _cfg => sub { return { file => '/etc/passwd' } };

sub authen ( $s, $user, $pass ) {
    my $auth = Authen::Simple::Passwd->new( path => $s->_cfg->{file} );

    return undef unless $auth->authenticate($user, $pass);
    # SU $_ c'è la riga autenticata
    my (undef,undef,$uid, $gid, $cn, $home, $shell) = split /:/;
    return { user => $user, cn => $cn, gid => $gid, uid => $uid };
}

sub cfg ($s, %cfg) {

    if (%cfg) {
        while (my ($k, $v) = each %cfg) {
            $s->_cfg->{$k} = $v;
        }
    }
    return $s->parent;
}

1;

=pod

=head1 NAME

Authen::Pluggable::Passwd - Authentication via a passwd file

=head1 VERSION

version 0.03

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Authentication via a passwd file
