# $Id: Node.pm 5801 2008-01-29 10:01:14Z daisuke $

package DBIx::Replicate::Node;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp::Clan;
use UNIVERSAL::require;

__PACKAGE__->mk_accessors($_) for qw(conn table); # sql_maker

sub new
{
    my $class = shift;
    my $args  = shift || {};

    foreach my $p (qw/conn table/) {
        croak "required parameter $p is missing\n"
            unless $args->{$p};
    }
    my $conn = $args->{conn};
    my $table = $args->{table};
#    my $sql_maker_class = $args->{sql_maker_class} || 'SQL::Abstract::Limit';
#    my $sql_maker_args  = $args->{sql_maker_args} || { limit_dialect => $conn };

#    $sql_maker_class->require or die;
#    my $sql_maker = $sql_maker_class->new( %{ $sql_maker_args } );
    my $self  = $class->SUPER::new({
        conn => $conn,
        table => $table,
#        sql_maker => $sql_maker
    });
    $self;
}

1;


