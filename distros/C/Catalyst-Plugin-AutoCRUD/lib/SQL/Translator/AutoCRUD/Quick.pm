package SQL::Translator::AutoCRUD::Quick;
{
  $SQL::Translator::AutoCRUD::Quick::VERSION = '2.143070';
}

use strict;
use warnings;

{
    package # hide from toolchain
        SQL::Translator::AutoCRUD::Quick::Table;
    use base 'SQL::Translator::Schema::Table';

    sub new {
        my ($class, $self) = @_;
        return bless $self, $class;
    };

    sub f {
        my $self = shift;
        return $self->{cpac_f} if $self->{cpac_f};
        $self->{cpac_f} = { map {($_->name => $_)} ($self->get_fields) };
        return $self->{cpac_f};
    }
}

use base 'SQL::Translator::Schema';

sub new {
    my ($class, $self) = @_;
    return bless $self, $class;
};

sub t {
    my $self = shift;
    return $self->{cpac_t} if $self->{cpac_t};
    $self->{cpac_t} = {
        (map {($_->name => SQL::Translator::AutoCRUD::Quick::Table->new($_))}
            $self->get_tables),
    };
    return $self->{cpac_t};
}

1;
