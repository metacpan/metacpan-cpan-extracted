#line 1
use strict;
use warnings;

package Module::Install::AuthorRequires;

# cargo cult
BEGIN {
    our $VERSION = '0.01';
    our $ISCORE  = 1;
#    our @ISA     = qw{Module::Install::Base};
}

use base qw/Module::Install::Base/;

sub author_requires {
    my $self = shift;

    return $self->{values}->{author_requires}
        unless @_;

    my @added;
    while (@_) {
        my $mod = shift or last;
        my $version = shift || 0;
        push @added, [$mod => $version];
    }

    push @{ $self->{values}->{author_requires} }, @added;
    $self->admin->author_requires(@added);

    return map { @$_ } @added;
}

1;

__END__

#line 93
