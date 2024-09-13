package    # hide from PAUSE
    DBIx::Squirrel::dr;

use 5.010_001;
use strict;
use warnings;
use DBIx::Squirrel::Utils qw/throw/;
use namespace::clean;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    $DBIx::Squirrel::dr::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::dr::ISA     = qw/DBI::dr/;
}

sub _root_class {
    my $root_class = ref($_[0]) || $_[0];
    $root_class =~ s/::\w+$//;
    return RootClass => $root_class if wantarray;
    return $root_class;
}

sub _clone_connection {
    my $invocant = shift;
    return unless UNIVERSAL::isa($_[0], 'DBI::db');
    my $connection = shift;
    my $attrs      = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    return $connection->clone({%{$attrs}, __PACKAGE__->_root_class});
}

sub connect {
    goto &_clone_connection if UNIVERSAL::isa($_[1], 'DBI::db');
    my $invocant = shift;
    my $attrs    = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    my $dbh = DBI::connect($invocant, @_, {%{$attrs}, __PACKAGE__->_root_class})
        or throw $DBI::errstr;
    return $dbh;
}

sub connect_cached {
    my $invocant   = shift;
    my $attributes = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    my $dbh
        = DBI::connect_cached($invocant, @_,
                              {%{$attributes}, __PACKAGE__->_root_class},
        ) or throw $DBI::errstr;
    return $dbh;
}

1;
