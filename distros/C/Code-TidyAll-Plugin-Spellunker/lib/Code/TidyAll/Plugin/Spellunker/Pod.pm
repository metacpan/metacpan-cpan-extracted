package Code::TidyAll::Plugin::Spellunker::Pod;
use strict;
use warnings;

use Moo;

extends 'Code::TidyAll::Plugin::Spellunker';

use Spellunker::Pod;

sub _check_source {
    my ($self, $source) = @_;

    my $engine = Spellunker::Pod->new();
    $engine->add_stopwords(@{ $self->parsed_stopwords });
    return $engine->check_text($source);
}

1;
__END__
