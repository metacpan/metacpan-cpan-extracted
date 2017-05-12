use strict;
use warnings;
use Devel::CallChecker;
use Devel::CallParser;
use IO::File;

my $callchecker_h = 'callchecker0.h';
my $callparser_h = 'callparser.h';

sub _mm_args {
    return (
        clean => { FILES => join q{ } => $callchecker_h, $callparser_h },
        OBJECT => join(q{ },
                       '$(BASEEXT)$(OBJ_EXT)',
                       Devel::CallChecker::callchecker_linkable,
                       Devel::CallParser::callparser_linkable),
    );
}

sub write_header {
    my ($header, $content) = @_;
    my $fh = IO::File->new($header, 'w') or die $!;
    $fh->print($content) or die $!;
    $fh->close or die $!;
}

write_header(${callchecker_h}, Devel::CallChecker::callchecker0_h);
write_header(${callparser_h}, eval { Devel::CallParser::callparser1_h } || Devel::CallParser::callparser0_h);

1;
