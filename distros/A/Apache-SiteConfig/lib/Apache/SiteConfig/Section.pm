package Apache::SiteConfig::Section;
use Moose;
extends 'Apache::SiteConfig::Root';

has name => ( is => 'rw' );
has value => ( is => 'rw' );

sub to_string {
    my ($self) = @_;
    my $level = $self->get_level;
    my $indent = " " x ($level * 4);
    return join "\n" ,"$indent<@{[$self->name]} @{[ $self->value ]}>",
        (map { $_->to_string } @{ $self->statements }),
        "$indent</@{[ $self->name ]}>\n";
}

1;
