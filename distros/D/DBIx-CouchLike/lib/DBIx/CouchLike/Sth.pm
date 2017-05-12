package DBIx::CouchLike::Sth;

use strict;
use warnings;
use base qw/ Class::Accessor::Fast /;
__PACKAGE__->mk_accessors(qw/ sth sql trace quote /);

sub execute {
    my $self = shift;

    if ( my $h = $self->{trace} ) {
        my @params = map { $self->{quote}->($_) } @_;
        my $sql    = $self->{sql};
        $sql =~ s/\?/shift @params/eg;
        print $h "TRACE >> $sql\n";
    }
    $self->{sth}->execute(@_);
}

sub fetchrow_arrayref {
    shift->{sth}->fetchrow_arrayref(@_);
}

sub finish {
    shift->{sth}->finish(@_);
}

1;
