package Acme::CramCode;
use Compress::Zlib;
our $VERSION = '0.01';
$birthmark ="Oh, I'm crammed, baby!!";
sub encode($){$birthmark. compress shift}
sub decode($){uncompress shift}
sub bm($){$_[0]=~/^$birthmark/s}
open 0 or print "Can't open '$0'\n" and exit;
(my $code=join q//, <0>)=~s/.*^\s*use\s+Acme::CramCode\s*;\n//sm;
do {$code=~s/^$birthmark//;eval decode $code; exit} if bm $code;
open 0, ">$0" or print "Cannot encode '$0'\n" and exit;
print {0} "use Acme::CramCode;\n", encode $code and exit;
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Acme::CramCode - Compress your code

=head1 SYNOPSIS

    use Acme::CramCode;
    print "Hello, World";

=head1 DESCRIPTION

This module compresses your program file and uncompresses it at run time. It's of no big use, but just for fun.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
