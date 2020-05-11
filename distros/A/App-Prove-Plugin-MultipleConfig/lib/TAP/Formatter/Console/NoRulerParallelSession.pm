package TAP::Formatter::Console::NoRulerParallelSession;
use strict;
use warnings;

use parent 'TAP::Formatter::Console::ParallelSession';

# somehow, show_count isn't set and formatter fails to write stdout correctly. So forcibly set show_count true;
sub _should_show_count {
    return 1;
}

sub _clear_ruler {
}

sub _output_ruler {
}

1;

=head1 NAME

TAP::Formatter::Console::NoRulerParallelSession - TAP::Formatter::Console for MultipleConfig

=head1 DESCRIPTION

TAP::Formatter::Console::NoRulerParallelSession is for not emitting ruler when testing.
This is because some CI can't render ruler correctly.

=head1 LICENSE

Copyright (C) takahito.yamada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

takahito.yamada

=head1 SEE ALSO

L<prove>, L<App::Prove::Plugin::MySQLPool>

=cut
