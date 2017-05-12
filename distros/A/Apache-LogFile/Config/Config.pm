package Apache::LogFile::Config;

use strict;
{
    no strict;
    $VERSION = '0.10';
    @ISA = qw(DynaLoader);
}

__PACKAGE__->bootstrap if $ENV{MOD_PERL};

sub PerlLogFile ($$$$) {
    my($cfg, $parms, $file, $handle) = @_;
    my $log = Apache::LogFile->_new($file);
    no strict;
    tie *{$handle}, "Apache::LogFile", $log;
}


1;
__END__
