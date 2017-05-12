package MyFeed;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = shift || {};
    return bless $self, $class;
}

sub link {
    my $self = shift;
    if (@_) { $self->{link} = shift }
    return $self->{link};
}
sub base {
    my $self = shift;
    if (@_) { $self->{base} = shift }
    return $self->{base};
}
sub title {
    my $self = shift;
    if (@_) { $self->{title} = shift }
    return $self->{title};
}
sub tagline {
    my $self = shift;
    if (@_) { $self->{tagline} = shift }
    return $self->{tagline};
}
sub description {
    my $self = shift;
    if (@_) { $self->{description} = shift }
    return $self->{description};
}
sub author {
    my $self = shift;
    if (@_) { $self->{author} = shift }
    return $self->{author};
}
sub language {
    my $self = shift;
    if (@_) { $self->{language} = shift }
    return $self->{language};
}
sub copyright {
    my $self = shift;
    if (@_) { $self->{copyright} = shift }
    return $self->{copyright};
}
sub generator {
    my $self = shift;
    if (@_) { $self->{generator} = shift }
    return $self->{generator};
}
sub id {
    my $self = shift;
    if (@_) { $self->{id} = shift }
    return $self->{id};
}
sub modified {
    my $self = shift;
    if (@_) { $self->{modified} = shift }
    return $self->{modified};
}

sub entries {
    my $self = shift;
    if (@_) { $self->{_entries} = shift }
    return $self->{_return_entries_array}
        ? @{ $self->{_entries} }
        : $self->{_entries};
}

1;
