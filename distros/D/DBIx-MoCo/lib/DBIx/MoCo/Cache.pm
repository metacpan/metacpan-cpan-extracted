package DBIx::MoCo::Cache;
use strict;
use warnings;

my $cache = {};
my $cache_created = time();
my $cache_expire = 600; # seconds

sub new { bless {}, shift }

sub set {
    my $self = shift;
    my ($k,$v) = @_;
    $cache->{$k} = $v if defined $k;
}

sub get {
    my $self = shift;
    my $k = shift or return;
    if (!$cache_created || ($cache_created + $cache_expire < time())) {
        $self->clear;
        #warn 'clear cache';
    }
    return $cache->{$k};
}

sub clear {
    $cache = {};
    $cache_created = time();
}

sub remove {
    my $self = shift;
    my $k = shift or return;
    #warn "remove cache $k";
    $cache->{$k} = undef;
}

sub cache_expire {
    my $class = shift;
    $cache_expire = $_[0] if $_[0];
    $cache_expire;
}

1;

=head1 NAME

DBIx::MoCo::Cache - Simple Cache for DBIx::MoCo

=head1 SYNOPSIS

  my $c = DBIx::MoCo::Cache->new;
  my $u = User->new(user_id => '123');
  my $oid = $u->object_id;
  $c->set($oid, $u);
  my $o = $c->get($oid); # $o is $u
  $c->remove($oid); # flush

=head1 SEE ALSO

L<DBIx::MoCo>, L<Cache>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
