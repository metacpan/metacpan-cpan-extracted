package AI::Prolog::Parser::PreProcessor;
$REVISION = '$Id: PreProcessor.pm,v 1.2 2005/08/06 23:28:40 ovid Exp $';

$VERSION = '0.01';
use strict;
use warnings;

use aliased 'AI::Prolog::Parser::PreProcessor::Math';

sub process {
    my ($class, $prolog) = @_;
    # why the abstraction?  Because I want DCGs in here, too.  Maybe 
    # other stuff ...
    $prolog = Math->process($prolog);
    return $prolog;
}

1;

__END__

=head1 NAME

AI::Prolog::Parser::PreProcessor - The AI::Prolog Preprocessor

=head1 SYNOPSIS

 my $program = AI::Prolog::Parser::Preprocessor->process($prolog_text).

=head1 DESCRIPTION

This code reads in the Prolog text and rewrites it to a for that is suitable
for the L<AI::Prolog::Parser|AI::Prolog::Parser> to read.  Users of
L<AI::Prolog||AI::Prolog> should never need to know about this.

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
