package Apache::Session::Browseable::_common;

use strict;
use AutoLoader 'AUTOLOAD';

our $VERSION = '1.2.2';

sub _tabInTab {
    my ( $class, $t1, $t2 ) = @_;

    # if no fields are required, return 0
    return 0 unless(@$t1 and @$t2);
    foreach my $f (@$t1) {
        unless ( grep { $_ eq $f } @$t2 ) {
            return 0;
        }
    }
    return 1;
}

sub _fieldIsIndexed {
    my ( $class, $args, $field ) = @_;
    my $index =
      ref( $args->{Index} ) ? $args->{Index} : [ split /\s+/, $args->{Index} ];
    return ( grep { $_ eq $field } @$index );
}

1;
__END__

sub searchOn {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} eq $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

sub searchOnExpr {
    my ( $class, $args, $selectField, $value, @fields ) = splice @_;
    $value = quotemeta($value);
    $value =~ s/\\\*/\.\*/g;
    $value = qr/^$value$/;
    my %res = ();
    $class->get_key_from_all_sessions(
        $args,
        sub {
            my $entry = shift;
            my $id    = shift;
            return undef unless ( $entry->{$selectField} =~ $value );
            if (@fields) {
                $res{$id}->{$_} = $entry->{$_} foreach (@fields);
            }
            else {
                $res{$id} = $entry;
            }
            undef;
        }
    );
    return \%res;
}

1;

