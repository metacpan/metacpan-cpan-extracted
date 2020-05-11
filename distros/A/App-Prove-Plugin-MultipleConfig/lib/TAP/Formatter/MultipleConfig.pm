package TAP::Formatter::MultipleConfig;
use strict;
use warnings;

use parent 'TAP::Formatter::Console';

use ConfigCache;
use TAP::Formatter::Console::NoRulerParallelSession;

sub open_test {
    my ($self, $filename, $parser) = @_;
    my $pid = $parser->_iterator->{pid};
    ConfigCache->set_config_by_filename($filename, $pid);

    my $session = TAP::Formatter::Console::NoRulerParallelSession->new({
        name       => $filename,
        formatter  => $self,
        parser     => $parser,
        show_count => $self->show_count,
    });

    $session->header;
    return $session;
}

1;

__END__

=head1 NAME

TAP::Formatter::MultipleConfig - TAP::Formatter for MultipleConfig

=head1 DESCRIPTION

TAP::Formatter::MultipleConfig is TAP::Formatter for MultipleConfig.
Before starting each test, this module associate a pid with a filename.

=head1 LICENSE

Copyright (C) takahito.yamada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

takahito.yamada

=head1 SEE ALSO

L<prove>, L<App::Prove::Plugin::MySQLPool>

=cut
